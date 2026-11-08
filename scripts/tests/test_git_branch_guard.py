"""以隔離 Git remote 驗證 branch 防護，不操作使用者的遠端。

code-mereology-leaf: scripts/sd-git-branch-guard.md
"""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
NOTES = 'cli-agents/prompt-custom_ch.md'
HOOKS = ('pre-commit', 'pre-merge-commit', 'pre-push')


class BranchGuardTests(unittest.TestCase):
    """透過真正 commit、merge 與 push 驗證允許及拒絕的情境。"""

    def setUp(self):
        """建立含空白與中文路徑的 clone，並安裝受測 hooks。"""
        self.tmp = tempfile.TemporaryDirectory(prefix='branch-guard-')
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.repo = self.base / '測試 repo'
        self.remote = self.base / 'remote.git'
        self.repo.mkdir()
        self.git('init', '--bare', str(self.remote))
        self.git('init', '-b', 'main')
        self.git('config', 'user.name', 'Guard Test')
        self.git('config', 'user.email', 'guard@example.invalid')
        for relative in ['scripts/git-branch-guard.mjs', 'scripts/install-git-hooks.mjs',
                         *[f'.githooks/{name}' for name in HOOKS]]:
            target = self.repo / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, target)
            if relative.startswith('.githooks/'):
                target.chmod(0o755)
        self.write(NOTES, '共用規則\n')
        self.write('README.md', '共用內容\n')
        self.git('add', '.')
        self.git('update-index', '--chmod=+x', *[f'.githooks/{name}' for name in HOOKS])
        self.git('commit', '-m', 'base')
        self.git('remote', 'add', 'origin', str(self.remote))
        self.git('push', '-u', 'origin', 'main')
        self.install()

    def git(self, *args, ok=True):
        """執行 Git，保留預期拒絕操作的結果供斷言使用。"""
        env = dict(os.environ, GIT_TERMINAL_PROMPT='0', LC_ALL='C', GIT_EDITOR='true')
        result = subprocess.run(['git', *args], cwd=self.repo, env=env,
                                capture_output=True, encoding='utf-8', errors='replace', timeout=30)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def write(self, relative, content):
        """寫入指定 fixture 檔案。"""
        path = self.repo / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding='utf-8')

    def install(self, ok=True):
        """以 Node 執行安裝入口。"""
        result = subprocess.run(['node', 'scripts/install-git-hooks.mjs'], cwd=self.repo,
                                capture_output=True, encoding='utf-8', errors='replace', timeout=30)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def commit(self, path=NOTES, content='環境案例\n', bypass=False):
        """新增案例；僅在漏擋測試刻意略過 commit hook。"""
        self.write(path, content)
        self.git('add', path)
        return self.git('commit', *(['--no-verify'] if bypass else []), '-m', 'case', ok=False)

    def env_branch(self):
        """從 main 建立該環境的 branch。"""
        self.git('switch', '-c', 'env/test')

    def main_update(self, path='README.md', content='main 更新\n'):
        """發布 main 更新，再返回環境 branch 並取得新 refs。"""
        self.git('switch', 'main')
        self.assertEqual(self.commit(path, content).returncode, 0)
        self.git('push', 'origin', 'main')
        self.git('switch', 'env/test')
        self.git('fetch', 'origin')

    def rejected(self, result):
        """確認 hook 明確拒絕操作，而非只列出提示。"""
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('[拒絕]', result.stdout + result.stderr)

    def test_main_selective_staging_and_install_idempotency(self):
        """main 可只提交指定檔案，重複安裝不變更行為。"""
        self.install()
        self.write('unrelated.txt', '保留\n')
        self.assertEqual(self.commit('README.md', 'main 改動\n').returncode, 0)
        self.git('push', 'origin', 'main')

    def test_env_notes_commit_and_new_branch_push(self):
        """環境案例可提交並建立遠端同名 branch。"""
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        self.git('push', '-u', 'origin', 'env/test')

    def test_env_other_file_staged_unstaged_and_untracked(self):
        """env 的其他檔案不論是否暫存都必須擋下。"""
        self.env_branch()
        self.rejected(self.commit('README.md', '違規\n'))
        self.git('reset', '--hard', 'HEAD')
        self.write('README.md', '未暫存\n')
        self.rejected(self.commit())
        self.git('restore', 'README.md')
        self.write('額外 file.txt', '未追蹤\n')
        self.rejected(self.git('commit', '-m', 'case', ok=False))

    def test_push_rejects_bad_history_even_after_revert(self):
        """略過 hook 並還原違規檔案，最終 diff 合法仍不得推送。"""
        self.env_branch()
        self.assertEqual(self.commit('README.md', 'bad\n', bypass=True).returncode, 0)
        self.assertEqual(self.commit('README.md', '共用內容\n', bypass=True).returncode, 0)
        self.rejected(self.git('push', 'origin', 'env/test', ok=False))

    def test_env_requires_main_synchronization(self):
        """未整合已 fetch 的 main 更新時，不得新增環境案例。"""
        self.env_branch()
        self.main_update()
        self.rejected(self.commit())

    def test_main_merge_into_env(self):
        """兩父同步 commit 可帶入 main 的其他檔案更新。"""
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        self.main_update()
        self.git('merge', '--no-commit', 'origin/main')
        self.git('commit', '-m', 'sync main')
        self.git('push', 'origin', 'env/test')

    def test_automatic_merge_is_rejected_then_explicit_commit_is_valid(self):
        """自動 merge 提早拒絕，Git 保留的 merge 狀態可再受檢查。"""
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        self.main_update()
        self.rejected(self.git('merge', '--no-edit', 'origin/main', ok=False))
        self.git('commit', '-m', 'explicit sync')

    def test_merge_conflict_in_notes_can_be_resolved_explicitly(self):
        """允許使用者明確處理白名單檔案的衝突。"""
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        self.main_update(NOTES, 'main 共用規則更新\n')
        result = self.git('merge', '--no-commit', 'origin/main', ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.write(NOTES, 'main 共用規則更新\n環境案例\n')
        self.git('add', NOTES)
        self.git('commit', '-m', 'resolved sync')
        self.git('push', 'origin', 'env/test')

    def test_merge_cannot_smuggle_other_changes(self):
        """同步 merge 中增加其他修改必須被擋下。"""
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        self.main_update()
        self.git('merge', '--no-commit', 'origin/main')
        self.write('README.md', 'sync 混入修改\n')
        self.git('add', 'README.md')
        self.rejected(self.git('commit', '-m', 'bad sync', ok=False))

    def test_unpublished_local_main_is_not_a_sync_source(self):
        """本機未發布的 main 不可冒充遠端 main 同步。"""
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        self.git('switch', 'main')
        self.assertEqual(self.commit('README.md', 'local main\n').returncode, 0)
        self.git('switch', 'env/test')
        self.git('merge', '--no-commit', 'main')
        self.rejected(self.git('commit', '-m', 'bad source', ok=False))

    def test_known_env_history_cannot_return_to_main(self):
        """手動 merge 及略過 merge hook 後的 main push 都會被擋。"""
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        self.git('switch', 'main')
        self.assertEqual(self.commit('README.md', 'main 分岔\n').returncode, 0)
        self.git('merge', '--no-commit', 'env/test')
        self.rejected(self.git('commit', '-m', 'bad return', ok=False))
        self.git('commit', '--no-verify', '-m', 'bypass')
        self.rejected(self.git('push', 'origin', 'main', ok=False))

    def test_fast_forward_env_into_main_is_blocked_on_push(self):
        """fast-forward 不跑 merge hook，仍會在 push 被擋。"""
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        self.git('switch', 'main')
        self.git('merge', '--ff-only', 'env/test')
        self.rejected(self.git('push', 'origin', 'main', ok=False))

    def test_ref_mapping_and_multi_ref_push(self):
        """不能用 HEAD:main 或混合多個 ref 繞過目的地檢查。"""
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        self.rejected(self.git('push', 'origin', 'HEAD:main', ok=False))
        self.rejected(self.git('push', 'origin', 'env/test:main', ok=False))
        self.rejected(self.git('push', 'origin', 'env/test:env/other', ok=False))
        self.git('branch', 'feature/unsupported')
        self.rejected(self.git('push', 'origin', 'env/test', 'feature/unsupported', ok=False))
        self.assertEqual(self.git('ls-remote', 'origin', 'refs/heads/env/test').stdout, '')

    def test_detached_unsupported_and_orphan_commits(self):
        """無法確認 branch 或其他 branch 名稱時拒絕。"""
        self.git('switch', '--detach')
        self.rejected(self.commit())
        self.git('reset', '--hard', 'HEAD')
        self.git('switch', '-c', 'feature/test')
        self.rejected(self.commit())
        self.git('reset', '--hard', 'HEAD')
        self.git('checkout', '--orphan', 'env/orphan')
        self.rejected(self.git('commit', '-m', 'orphan', ok=False))

    def test_non_fast_forward_delete_tag_and_remote_policy(self):
        """禁止分支 force 更新與刪除；tag 不受分支規則限制。"""
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        self.git('push', 'origin', 'env/test')
        self.git('reset', '--hard', 'origin/main')
        self.rejected(self.git('push', '--force', 'origin', 'env/test', ok=False))
        self.rejected(self.git('push', 'origin', ':env/test', ok=False))
        self.git('tag', 'test-tag')
        self.git('push', 'origin', 'test-tag')
        self.git('remote', 'add', 'other', str(self.remote))
        self.rejected(self.git('push', 'other', 'env/test', ok=False))

    def test_origin_main_missing_and_remote_old_object_missing(self):
        """缺少必要 refs 或遠端舊物件時明確拒絕，不能假定安全。"""
        self.env_branch()
        self.git('update-ref', '-d', 'refs/remotes/origin/main')
        self.rejected(self.commit())
        self.git('reset', '--hard', 'HEAD')
        self.git('fetch', 'origin')
        result = subprocess.run(['node', 'scripts/git-branch-guard.mjs', 'pre-push', 'origin'],
                                cwd=self.repo, input='refs/heads/main ' + self.git('rev-parse', 'HEAD').stdout.strip() +
                                ' refs/heads/main ' + '1' * 40 + '\n',
                                capture_output=True, encoding='utf-8', timeout=30)
        self.rejected(result)

    def test_main_with_unpublished_commit_also_on_env_is_conservatively_rejected(self):
        """無法確認來源的共享未發布歷史採保守拒絕並指出 env ref。"""
        self.assertEqual(self.commit('README.md', 'unpublished\n').returncode, 0)
        self.git('branch', 'env/ambiguous')
        result = self.git('push', 'origin', 'main', ok=False)
        self.rejected(result)
        self.assertIn('env/ambiguous', result.stderr)

    def test_installer_preserves_existing_custom_hooks(self):
        """不覆蓋其他 hooksPath 或預設 hooks 內的自訂 hook。"""
        self.git('config', 'core.hooksPath', 'custom-hooks')
        self.assertNotEqual(self.install(ok=False).returncode, 0)
        self.assertEqual(self.git('config', '--get', 'core.hooksPath').stdout.strip(), 'custom-hooks')
        self.git('config', '--unset', 'core.hooksPath')
        self.write('.git/hooks/pre-commit', '#!/bin/sh\nexit 0\n')
        self.assertNotEqual(self.install(ok=False).returncode, 0)

    def hidden_gitlink(self, setting):
        """保持忽略設定，分別確認 commit 與 push 都不會隱藏 gitlink。"""
        initial = self.git('rev-parse', 'HEAD').stdout.strip()
        self.write('.gitmodules', '[submodule "upstream/bypass"]\n path = upstream/bypass\n url = ../unused.git\n')
        (self.repo / 'upstream/bypass').mkdir(parents=True)
        self.git('update-index', '--add', '--cacheinfo', f'160000,{initial},upstream/bypass')
        self.git('add', '.gitmodules')
        self.git('commit', '-m', 'main gitlink')
        self.git('push', 'origin', 'main')
        self.env_branch()
        self.git('config', setting, 'all')
        target = self.git('rev-parse', 'HEAD').stdout.strip()
        self.git('update-index', '--cacheinfo', f'160000,{target},upstream/bypass')
        self.assertNotIn('upstream/bypass', self.git('diff', '--cached', '--name-only').stdout)
        self.rejected(self.commit())
        self.git('commit', '--no-verify', '-m', 'bypassed invalid gitlink')
        result = self.git('push', 'origin', 'env/test', ok=False)
        self.rejected(result)
        self.assertIn('已提交', result.stderr)
        self.assertNotIn('git -C', result.stderr)
        self.assertEqual(self.git('config', '--get', setting).stdout.strip(), 'all')

    def test_diff_ignore_submodules_cannot_hide_gitlinks(self):
        """全域 diff 忽略設定不可繞過檔案白名單。"""
        self.hidden_gitlink('diff.ignoreSubmodules')

    def test_per_submodule_ignore_cannot_hide_gitlinks(self):
        """個別 submodule 忽略設定不可繞過檔案白名單。"""
        self.hidden_gitlink('submodule.upstream/bypass.ignore')

    def test_octopus_and_foreign_env_merges_are_rejected_on_push(self):
        """即使最終 tree 合法，非法 merge 父本仍不得通過。"""
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        first = self.git('rev-parse', 'HEAD').stdout.strip()
        self.main_update()
        second = self.git('rev-parse', 'origin/main').stdout.strip()
        base = self.git('merge-base', first, second).stdout.strip()
        tree = self.git('rev-parse', 'origin/main^{tree}').stdout.strip()
        octopus = self.git('commit-tree', tree, '-p', first, '-p', second, '-p', base,
                           '-m', 'octopus').stdout.strip()
        self.git('update-ref', 'refs/heads/env/test', octopus)
        self.rejected(self.git('push', 'origin', 'env/test', ok=False))
        self.git('reset', '--hard', first)
        self.git('merge', '--no-commit', 'origin/main')
        self.git('commit', '-m', 'sync')
        self.git('branch', 'env/other')
        self.git('switch', 'env/other')
        self.assertEqual(self.commit(content='其他環境案例\n').returncode, 0)
        foreign = self.git('rev-parse', 'HEAD').stdout.strip()
        self.git('switch', 'env/test')
        own = self.git('rev-parse', 'HEAD').stdout.strip()
        illegal = self.git('commit-tree', tree, '-p', own, '-p', foreign,
                           '-m', 'foreign env').stdout.strip()
        self.git('update-ref', 'refs/heads/env/test', illegal)
        self.rejected(self.git('push', 'origin', 'env/test', ok=False))

    def test_submodule_checkout_drift_blocks_until_user_updates_it(self):
        """index 已同步新 gitlink，但 checkout 漂移時仍須明確處理。"""
        source = self.base / 'submodule-source'
        source.mkdir()
        def subgit(*args):
            result = subprocess.run(['git', '-C', str(source), *args], capture_output=True,
                                    encoding='utf-8', errors='replace', timeout=30)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            return result.stdout.strip()
        subgit('init', '-b', 'main')
        subgit('config', 'user.name', 'Submodule Test')
        subgit('config', 'user.email', 'submodule@example.invalid')
        (source / 'data').write_text('old\n')
        subgit('add', '.'); subgit('commit', '-m', 'old')
        old = subgit('rev-parse', 'HEAD')
        self.git('-c', 'protocol.file.allow=always', 'submodule', 'add', str(source), 'upstream/probe')
        self.git('commit', '-am', 'add submodule')
        self.git('push', 'origin', 'main')
        self.env_branch()
        self.assertEqual(self.commit().returncode, 0)
        self.write('upstream/probe/generated.txt', '子 repo 未追蹤檔案\n')
        result = self.commit(content='dirty 時待提交的案例\n')
        self.rejected(result)
        self.assertIn('git -C', result.stderr)
        (self.repo / 'upstream/probe/generated.txt').unlink()
        self.git('commit', '-m', 'user removed untracked file')
        self.write('upstream/probe/data', '子 repo 本機修改\n')
        result = self.commit(content='另一個 dirty 案例\n')
        self.rejected(result)
        self.assertIn('git -C', result.stderr)
        self.git('-C', 'upstream/probe', 'restore', 'data')
        self.git('commit', '-m', 'user restored child content')
        (source / 'data').write_text('new\n')
        subgit('commit', '-am', 'new')
        new = subgit('rev-parse', 'HEAD')
        self.git('switch', 'main')
        self.git('-C', 'upstream/probe', 'fetch', 'origin')
        self.git('-C', 'upstream/probe', 'checkout', new)
        self.git('add', 'upstream/probe')
        self.git('commit', '-m', 'update submodule')
        self.git('push', 'origin', 'main')
        self.git('switch', 'env/test')
        self.git('-C', 'upstream/probe', 'checkout', old)
        self.git('merge', '--no-commit', 'origin/main')
        result = self.git('commit', '-m', 'sync', ok=False)
        self.rejected(result)
        self.assertIn('submodule', result.stderr)
        self.git('submodule', 'update')
        self.git('commit', '-m', 'sync after update')
        self.git('push', 'origin', 'env/test')


if __name__ == '__main__':
    unittest.main(verbosity=2)
