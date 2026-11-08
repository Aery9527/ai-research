#!/usr/bin/env node
// 驗證本機 Git 的 branch、提交內容與推送方向；不修改 refs 或工作區。
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const notes = 'cli-agents/prompt-custom_ch.md';
const mainRef = 'refs/remotes/origin/main';

// 執行 Git；非預期的結束碼不可當成安全狀態。
function git(args, allowed = [0]) {
    const result = spawnSync('git', args, { encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
    if (result.error || !allowed.includes(result.status)) {
        throw new Error(`Git 檢查失敗，請先確認狀態：${result.error?.message ?? result.stderr.trim()}`);
    }
    return result;
}

// 讀取 Git 的換行分隔輸出；不適用於檔案路徑。
function lines(text) {
    return text.trim().split(/\r?\n/).filter(Boolean);
}

// 檔案路徑使用 NUL 分隔，保留空白、中文與換行字元。
function paths(args) {
    const enforced = args[0] === 'diff' ? ['diff', '--ignore-submodules=none', ...args.slice(1)] : args;
    return git(enforced).stdout.split('\0').filter(Boolean);
}

// 回傳祖先關係；1 是已確認非祖先，其餘錯誤必須停止。
function ancestor(older, newer) {
    return git(['merge-base', '--is-ancestor', older, newer], [0, 1]).status === 0;
}

// 只接受可解析的 commit，缺少 fetch 物件時拒絕操作。
function commit(ref) {
    const result = git(['rev-parse', '--verify', `${ref}^{commit}`], [0, 128]);
    if (result.status !== 0) {
        throw new Error(`缺少 commit ${ref}；請先 fetch origin 並確認狀態。`);
    }
    return result.stdout.trim();
}

// 只允許明確的 main 或具名環境 branch；detached HEAD 不猜測來源。
function branch() {
    const result = git(['symbolic-ref', '--quiet', '--short', 'HEAD'], [0, 1]);
    const name = result.stdout.trim();
    if (result.status !== 0 || (name !== 'main' && !/^env\/.+/.test(name))) {
        throw new Error('只允許 main 或 env/*；detached HEAD、rebase edit 與其他 branch 請先停下確認。');
    }
    return name;
}

// 驗證環境變更只能觸及紀錄檔；submodule 漂移也必須由使用者處理。
function onlyNotes(changed, context = '工作區') {
    const extra = changed.filter(path => path !== notes);
    if (extra.length) {
        const hint = context === '工作區'
            ? '若涉及 submodule，先用 git -C <path> status 確認內容，再詢問使用者；submodule update 只適用於指標漂移，不能清除已修改或未追蹤內容，不可自動還原或 stash。'
            : '這是已提交的違規內容，請停下詢問使用者如何處理歷史；工作區清理無法修正已提交的變更，不可自動改寫或 force-push。';
        throw new Error(`env/* 只允許修改 ${notes}；${context} 的其他變更：${extra.map(path => JSON.stringify(path)).join(', ')}。${hint}`);
    }
}

// 回傳 merge 狀態；自動 merge hook 執行時尚無 MERGE_HEAD。
function mergeHeads() {
    const file = resolve(git(['rev-parse', '--git-path', 'MERGE_HEAD']).stdout.trim());
    return existsSync(file) ? lines(readFileSync(file, 'utf8')) : [];
}

// main 不可引入可從已知 env refs 追溯、且尚未存在 remote main 的 commits。
function noEnvironmentHistory(tips) {
    const refs = lines(git(['for-each-ref', '--format=%(refname) %(objectname)',
        'refs/heads/env/', 'refs/remotes/origin/env/']).stdout);
    if (!refs.length) return;
    const introduced = new Set(lines(git(['rev-list', ...tips, '--not', mainRef]).stdout));
    for (const entry of refs) {
        const [ref, tip] = entry.split(' ');
        const found = lines(git(['rev-list', tip, '--not', mainRef]).stdout)
            .find(sha => introduced.has(sha));
        if (found) {
            throw new Error(`main 不可引入 ${ref} 的未發布歷史 ${found}；若 env 從未推送的 main 建立而造成來源歧義，請停下詢問使用者。`);
        }
    }
}

// 檢查提交前的 index；main 保留 selective staging，env 檢查整個工作區。
function checkCommit() {
    const current = branch();
    commit(mainRef);
    const head = commit('HEAD');
    const merging = mergeHeads();
    if (current === 'main') {
        noEnvironmentHistory([head, ...merging]);
        return;
    }
    if (paths(['ls-files', '--unmerged', '-z']).length) {
        throw new Error('merge 衝突尚未解決；請停下詢問使用者。');
    }
    onlyNotes(paths(['diff', '--name-only', '--no-renames', '-z']));
    onlyNotes(paths(['ls-files', '--others', '--exclude-standard', '-z']));
    if (merging.length) {
        if (merging.length !== 1 || merging[0] !== commit(mainRef)) {
            throw new Error('同步只允許一個 MERGE_HEAD，且必須是目前 fetch 後的 origin/main tip；若背景 fetch 改變 tip，請停下重新確認。');
        }
        const tree = git(['write-tree']).stdout.trim();
        onlyNotes(paths(['diff', '--name-only', '--no-renames', '-z', merging[0], tree]));
    } else {
        if (!ancestor(mainRef, head)) throw new Error('請先 fetch origin，並將 origin/main merge 到環境 branch。');
        const staged = paths(['diff', '--cached', '--name-only', '--no-renames', '-z']);
        onlyNotes(staged);
        if (!staged.length) throw new Error('env/* 不接受沒有紀錄變更的空提交。');
    }
}

// 逐個驗證環境歷史，不能以還原後的最終 diff 掩蓋違規提交。
function checkEnvironmentTip(tip) {
    if (!ancestor(mainRef, tip)) throw new Error('環境 branch 尚未整合 fetch 後的 origin/main。');
    onlyNotes(paths(['diff', '--name-only', '--no-renames', '-z', mainRef, tip]), `推送 tree ${tip}`);
    for (const sha of lines(git(['rev-list', '--reverse', '--topo-order', tip, '--not', mainRef]).stdout)) {
        const [, ...parents] = git(['rev-list', '--parents', '-n', '1', sha]).stdout.trim().split(' ');
        if (parents.length === 1) {
            const changed = paths(['diff', '--name-only', '--no-renames', '-z', parents[0], sha]);
            onlyNotes(changed, `commit ${sha}`);
            if (!changed.length) throw new Error(`環境歷史含空提交 ${sha}。`);
        } else if (parents.length === 2 && ancestor(parents[1], mainRef)) {
            onlyNotes(paths(['diff', '--name-only', '--no-renames', '-z', parents[1], sha]), `同步 commit ${sha}`);
        } else {
            throw new Error(`環境歷史含不合法來源、orphan 或 octopus merge：${sha}。`);
        }
    }
}

// 檢查真正的 ref 更新；不能靠目前工作區狀態或 branch 名稱猜測目標。
function checkPush(remote) {
    if (remote !== 'origin') throw new Error('此防護只支援 origin；其他 remote 或 URL 推送請先詢問使用者。');
    commit(mainRef);
    const updates = lines(readFileSync(0, 'utf8'));
    for (const update of updates) {
        const fields = update.split(/\s+/);
        if (fields.length !== 4) throw new Error('無法解析 pre-push ref 更新。');
        const [localRef, localOid, remoteRef, remoteOid] = fields;
        if (!remoteRef.startsWith('refs/heads/')) continue;
        const destination = remoteRef.slice('refs/heads/'.length);
        if (destination !== 'main' && !/^env\/.+/.test(destination)) {
            throw new Error(`不允許推送到 ${remoteRef}。`);
        }
        if (/^0+$/.test(localOid)) throw new Error(`不允許刪除分支 ${remoteRef}。`);
        if (localRef !== remoteRef && !(localRef === 'HEAD' && branch() === destination)) {
            throw new Error(`來源與目標 branch 必須相同：${localRef} -> ${remoteRef}。`);
        }
        const tip = commit(localOid);
        if (!/^0+$/.test(remoteOid)) {
            commit(remoteOid);
            if (!ancestor(remoteOid, tip)) throw new Error(`不允許 non-fast-forward 或 force 更新 ${remoteRef}。`);
        }
        if (destination === 'main') noEnvironmentHistory([tip]);
        else checkEnvironmentTip(tip);
    }
}

try {
    if (Number(process.versions.node.split('.')[0]) < 18) throw new Error('需要 Node.js 18 以上。');
    const mode = process.argv[2];
    if (mode === 'pre-commit') checkCommit();
    else if (mode === 'pre-push') checkPush(process.argv[3]);
    else if (mode === 'pre-merge-commit') {
        throw new Error('自動 merge 無法可靠確認來源；請使用 git merge --no-commit origin/main，再執行 git commit 進行檢查。');
    } else throw new Error(`不支援的 hook：${mode}。`);
} catch (error) {
    process.stderr.write(`[拒絕] ${error.message}\n`);
    process.exitCode = 1;
}
