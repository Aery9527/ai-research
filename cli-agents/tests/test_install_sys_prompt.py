"""以隔離家目錄驗證提示詞安裝器，不修改使用者設定。"""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


INSTALLER_ROOT = Path(__file__).resolve().parents[1]
TEMPLATES = {
    "claude-code/.claude/CLAUDE.md": ".claude/CLAUDE.md",
    "codex/.codex/AGENTS.md": ".codex/AGENTS.md",
    "github-copilot/.copilot/copilot-instructions.md": ".copilot/copilot-instructions.md",
}
SOURCES = {
    **{source: f"# 工具範本 {index}" for index, source in enumerate(TEMPLATES)},
    "prompt-user.md": "# 使用者規則",
    "prompt-custom.md": "# Environment Notes\nC:/record source/prompt-custom.md",
}


def available_runtimes():
    """找出可直接執行的 PowerShell 與 Bash，Windows 優先使用 Git Bash。"""
    runtimes = []
    for name in ("powershell", "pwsh"):
        executable = shutil.which(name)
        if executable:
            runtimes.append((name, [executable, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File"], ".ps1"))
    git_bash = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Git/bin/bash.exe"
    bash = str(git_bash) if os.name == "nt" and git_bash.is_file() else shutil.which("bash")
    if bash:
        runtimes.append(("bash", [bash, "--noprofile", "--norc"], ".sh"))
    return runtimes


class PromptInstallTests(unittest.TestCase):
    """檢查三組來源合併、備份及缺檔時的副作用邊界。"""

    def setUp(self):
        """每個案例使用獨立暫存根目錄。"""
        self.temporary = tempfile.TemporaryDirectory(prefix="prompt-install-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.runtimes = available_runtimes()
        self.assertTrue(self.runtimes, "需要 PowerShell 或 Bash 執行安裝器測試")

    def fixture(self, name):
        """建立含空白與非 ASCII 字元的來源及家目錄路徑。"""
        source = self.root / name / "安裝 source"
        home = self.root / name / "使用者 home"
        for relative, content in SOURCES.items():
            path = source / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
        (source / 'prompt-custom_ch.md').write_text('中文對照不應部署', encoding='utf-8')
        for suffix in (".ps1", ".sh"):
            shutil.copyfile(INSTALLER_ROOT / f"install-sys-prompt{suffix}", source / f"install-sys-prompt{suffix}")
        return source, home

    def install(self, runtime, paths, arguments=()):
        """只在子程序指定測試家目錄，不修改實際使用者設定。"""
        _, command, suffix = runtime
        source, home = paths
        env = dict(os.environ, HOME=home.as_posix(), USERPROFILE=str(home))
        return subprocess.run(
            [*command, (source / f"install-sys-prompt{suffix}").as_posix(), *arguments],
            env=env, cwd=self.root, capture_output=True, encoding="utf-8", errors="replace", timeout=30,
        )

    def assert_merged(self, paths, custom=None):
        """逐一比對三個目標的完整內容，忽略平台換行與 UTF-8 BOM。"""
        source, home = paths
        for template, target in TEMPLATES.items():
            actual = (home / target).read_text(encoding="utf-8-sig")
            expected = [
                path.read_text(encoding="utf-8-sig").strip()
                for path in (source / template, source / "prompt-user.md", custom or source / "prompt-custom.md")
            ]
            self.assertEqual(actual.strip(), "\n\n".join(expected).strip())

    def test_merge_and_republish_with_backups(self):
        """首次合併三組內容；修改自訂規則後重跑會保留原目標的完整備份。"""
        for runtime in self.runtimes:
            with self.subTest(runtime=runtime[0]):
                paths = self.fixture(runtime[0])
                result = self.install(runtime, paths)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assert_merged(paths)
                self.assertEqual(list(paths[1].rglob("*_????????????")), [])
                originals = {target: (paths[1] / target).read_bytes() for target in TEMPLATES.values()}
                (paths[0] / "prompt-custom.md").write_text("# 新環境規則", encoding="utf-8")
                result = self.install(runtime, paths)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assert_merged(paths)
                suffixes = set()
                for target, original in originals.items():
                    path = paths[1] / target
                    backups = list(path.parent.glob(path.name + "_*"))
                    self.assertEqual(len(backups), 1)
                    self.assertEqual(backups[0].read_bytes(), original)
                    suffixes.add(backups[0].name.rsplit("_", 1)[1])
                self.assertEqual(len(suffixes), 1)

    def test_missing_source_stops_before_target_changes(self):
        """任一來源缺檔時，既有設定不變，首次安裝也不建立目標目錄。"""
        for runtime in self.runtimes:
            for index, missing in enumerate(SOURCES):
                for existing in (False, True):
                    with self.subTest(runtime=runtime[0], missing=missing, existing=existing):
                        paths = self.fixture(f"{runtime[0]}-{index}-{existing}")
                        target = paths[1] / ".claude/CLAUDE.md"
                        if existing:
                            target.parent.mkdir(parents=True)
                            target.write_bytes("手動設定".encode("utf-8"))
                        (paths[0] / missing).unlink()
                        result = self.install(runtime, paths)
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn(Path(missing).name, result.stdout + result.stderr)
                        if existing:
                            self.assertEqual(target.read_bytes(), "手動設定".encode("utf-8"))
                            self.assertEqual(list(target.parent.iterdir()), [target])
                        else:
                            self.assertFalse(target.parent.exists())
                        self.assertFalse((paths[1] / ".codex").exists())
                        self.assertFalse((paths[1] / ".copilot").exists())

    def test_empty_custom_prompt_is_allowed(self):
        """自訂檔可留空，仍能部署工具範本與使用者規則。"""
        for runtime in self.runtimes:
            with self.subTest(runtime=runtime[0]):
                paths = self.fixture(runtime[0])
                (paths[0] / "prompt-custom.md").write_bytes(b"")
                result = self.install(runtime, paths)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assert_merged(paths)

    def test_external_custom_path_is_anchored_to_script(self):
        """外部相對與絕對來源取代內建 custom，與工作目錄無關。"""
        for runtime in self.runtimes:
            for absolute in (False, True):
                with self.subTest(runtime=runtime[0], absolute=absolute):
                    paths = self.fixture(f"external-{runtime[0]}-{absolute}")
                    external = paths[0].parent / "私有 custom.md"
                    external.write_text("# 私有環境\nOnly private custom", encoding="utf-8")
                    argument = external.as_posix() if absolute else "../私有 custom.md"
                    if absolute and runtime[0] == 'bash' and os.name == 'nt':
                        argument = '/' + argument[0].lower() + argument[2:]
                    flag = '--custom-prompt' if runtime[0] == 'bash' else '-CustomPromptPath'
                    (paths[0] / 'prompt-custom.md').unlink()
                    result = self.install(runtime, paths, (flag, argument))
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assert_merged(paths, external)

    def test_invalid_explicit_custom_never_falls_back_or_writes(self):
        """缺檔、目錄與明確空值均失敗，既有設定不變。"""
        for runtime in self.runtimes:
            cases = ['missing.md', '.', '']
            if runtime[0] != 'bash':
                cases += ['C:custom.md', '/custom.md', '\\custom.md']
            for index, argument in enumerate(cases):
                with self.subTest(runtime=runtime[0], argument=argument):
                    paths = self.fixture(f"invalid-{runtime[0]}-{index}")
                    target = paths[1] / '.claude/CLAUDE.md'
                    target.parent.mkdir(parents=True)
                    target.write_bytes(b'original')
                    flag = '--custom-prompt' if runtime[0] == 'bash' else '-CustomPromptPath'
                    result = self.install(runtime, paths, (flag, argument))
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(target.read_bytes(), b'original')
                    self.assertEqual(list(target.parent.iterdir()), [target])
                    self.assertFalse((paths[1] / '.codex').exists())
                    self.assertFalse((paths[1] / '.copilot').exists())

    def test_bash_invalid_arguments_stop_before_writes(self):
        """Bash 缺值、未知與多餘參數在寫入前拒絕。"""
        for runtime in self.runtimes:
            if runtime[0] != 'bash':
                continue
            for index, args in enumerate([('--custom-prompt',), ('--unknown',), ('--custom-prompt', 'prompt-custom.md', 'extra')]):
                paths = self.fixture(f"badargs-{index}")
                result = self.install(runtime, paths, args)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(paths[1].exists())

    @unittest.skipIf(os.name == 'nt' or (hasattr(os, 'geteuid') and os.geteuid() == 0), 'POSIX 非 root 才能可靠驗證讀取權限')
    def test_unreadable_external_custom_stops_before_writes(self):
        """不可讀外部來源不備份、不覆寫，也不建立其他工具目錄。"""
        for runtime in self.runtimes:
            if runtime[0] != 'bash':
                continue
            paths = self.fixture('unreadable')
            external = paths[0].parent / 'private.md'
            external.write_text('private', encoding='utf-8')
            external.chmod(0)
            target = paths[1] / '.claude/CLAUDE.md'
            target.parent.mkdir(parents=True)
            target.write_bytes(b'original')
            result = self.install(runtime, paths, ('--custom-prompt', '../private.md'))
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(target.read_bytes(), b'original')
            self.assertEqual(list(target.parent.iterdir()), [target])
            self.assertFalse((paths[1] / '.codex').exists())
            self.assertFalse((paths[1] / '.copilot').exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
