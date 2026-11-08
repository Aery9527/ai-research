#!/usr/bin/env node
// 在這個 clone 啟用版本化 hooks，遇到其他自訂 hooks 時保留原設定並停止。
import { execFileSync, spawnSync } from 'node:child_process';
import { accessSync, constants, existsSync, lstatSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const names = ['pre-commit', 'pre-merge-commit', 'pre-push'];

// 安裝時固定操作腳本所在 repo，不受呼叫者的工作目錄影響。
function git(args) {
    return execFileSync('git', args, { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
}

try {
    if (Number(process.versions.node.split('.')[0]) < 18) throw new Error('需要 Node.js 18 以上。');
    const match = git(['--version']).match(/git version (\d+)\.(\d+)/);
    if (!match || (Number(match[1]) < 2 || (Number(match[1]) === 2 && Number(match[2]) < 24))) {
        throw new Error('需要 Git 2.24 以上。');
    }
    if (resolve(git(['rev-parse', '--show-toplevel'])) !== root) throw new Error('腳本必須位於本 repo 的 scripts 目錄。');
    git(['rev-parse', '--verify', 'refs/remotes/origin/main^{commit}']);
    const target = resolve(root, '.githooks');
    const existing = spawnSync('git', ['config', '--get', 'core.hooksPath'], { cwd: root, encoding: 'utf8' });
    if (![0, 1].includes(existing.status)) throw new Error('無法讀取 core.hooksPath。');
    if (existing.status === 0) {
        if (resolve(root, existing.stdout.trim()) !== target) throw new Error('已有其他 core.hooksPath；請先詢問使用者，不覆蓋原設定。');
    } else {
        const defaultHooks = resolve(root, git(['rev-parse', '--git-path', 'hooks']));
        if (existsSync(defaultHooks) && readdirSync(defaultHooks).some(name => !name.endsWith('.sample'))) {
            throw new Error('預設 hooks 目錄含自訂內容；請先詢問使用者，不覆蓋原設定。');
        }
    }
    for (const name of names) {
        const relative = `.githooks/${name}`;
        const file = resolve(root, relative);
        if (!lstatSync(file).isFile()) throw new Error(`${relative} 必須是一般檔案。`);
        const content = readFileSync(file, 'utf8');
        if (!content.startsWith('#!/bin/sh\n') || content.includes('\r')) throw new Error(`${relative} 必須使用 LF。`);
        if (!git(['ls-files', '--stage', '--', relative]).startsWith('100755 ')) {
            throw new Error(`${relative} 的 Git mode 必須是 100755。`);
        }
        if (process.platform !== 'win32') accessSync(file, constants.X_OK);
    }
    git(['config', '--local', 'core.hooksPath', '.githooks']);
    process.stdout.write('[OK] 已為本 clone 啟用 .githooks；每個 clone 都必須另行安裝。\n');
} catch (error) {
    process.stderr.write(`[拒絕] 安裝 hooks 失敗：${error.message}\n`);
    process.exitCode = 1;
}
