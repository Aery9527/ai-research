---
name: skills-governance
description: >-
  用於建立、修改、重新命名或移除本 repo 的 project skills，並套用
  文件同步、目錄邊界與 Conventional Commit 規則時使用。
---

# Skills Governance

治理本 repo 內的 project skills，特別是 [`.claude/skills/`](../) 下的可執行 workflow skills，以及與其直接相關的文件同步、目錄邊界與 commit slice 規則。

## Directory Boundaries

- [`.claude/skills/`](../) — project skills — 放本 repo 執行維護任務時需要的 sync skill、CLI 文件同步 skill、治理 workflow 與共用協議。
- [`skill-source/`](../../../skill-source/) — upstream submodule container — 集中存放上游 skill 函式庫的 git submodule；嚴禁直接修改上游內容。
- [`skill-source/anthropic-skills/`](../../../skill-source/anthropic-skills/) — upstream submodule — 放上游 skills 原始內容；除同步任務外，不承擔本 repo 治理規則。

## Placement Rules

- 如果內容是本 repo 專用且需要被 agent 執行的 workflow skill，必須放在 [`.claude/skills/`](../)。
- 如果內容是在調整 sync 流程、CLI 文件同步流程、治理 workflow 或 shared protocol，必須放在 [`.claude/skills/`](../)。
- 如果內容只是協助選擇或解釋 upstream skill，應優先讀取 [`skill-source/`](../../../skill-source/) 內的上游 `SKILL.md`，嚴禁為此建立 project skill。
- 如果規則離開此 repo 就失去意義，嚴禁塞進 upstream submodule。

## Workflow

1. 先搜尋影響面。必須用舊名稱、舊路徑、新名稱、新路徑與主題關鍵字掃描整個 repo。
2. 在同一個 change slice 內修完所有過期資訊。嚴禁只改 skill 本體卻把 [`README.md`](../../../README.md)、[`AGENTS.md`](../../../AGENTS.md) 或相關入口文件留到之後。
3. 定義 commit 邊界。一個 slice 必須只有單一目的，且可獨立 review、獨立回滾。
4. Slice 一完成就 commit。若 worktree 有不相關修改，必須用 selective staging 或先 stash；嚴禁等待大雜燴 commit。
5. 完成一個 slice 後，才能進下一個主題。

## Slice Completion Rules

- 如果變更目的單一，例如修 frontmatter parse error、rename skill、補同步文件，則可視為一個 slice。
- 如果相關文件與 metadata 仍有過期資訊，則 slice 尚未完成。
- 如果只靠簡單搜尋與 diff 就能驗證沒有遺漏，則 slice 可提交；否則先補齊。

## Conventional Commit Rules

- 預設格式：`<type>(<scope>): <summary>`。
- 建議 scope：
  - `claude-skills` — 修改 [`.claude/skills/`](../) project skill 或 shared protocol。
  - `docs` — 以文件索引與說明同步為主。
- 類型選擇：
  - `feat` — 新增 skill、擴充能力、擴大規則覆蓋面。
  - `fix` — 修正壞掉的 frontmatter、錯誤規則、錯誤路徑、錯誤觸發條件。
  - `refactor` — 重新命名、搬移、重組結構，但不改行為語意。
  - `docs` — 純文件同步、說明澄清、索引補充。
  - `chore` — 純 metadata 或維護雜項，沒有行為或文件語意變更。
- 優先序：`feat > fix > refactor > docs > chore`。如果同一 slice 同時包含多種變更，必須以最高影響層級決定 type。

## Documentation And Metadata Sync

- 修改 [`.claude/skills/`](../) 或相關治理邊界時，至少檢查這些位置是否因本次變更而過期：
  - [`README.md`](../../../README.md)
  - [`AGENTS.md`](../../../AGENTS.md)
  - [`CLAUDE.md`](../../../CLAUDE.md)，如果專案級使用指引受影響
  - [`.claude/skills/`](../) 下的 project skill 或 shared protocol，如果入口或引用名稱受影響
  - [`.gitignore`](../../../.gitignore)、[`scripts/SCRIPTS.md`](../../../scripts/SCRIPTS.md)、migration docs、舊計畫文件，如果名稱或路徑變更讓它們過期
- 原則不是每次全改，而是所有被這次修改弄成不準確的地方都必須在同一個 slice 內修完。

## Verification Checklist

- 用 `rg` 搜舊名稱與舊路徑，確認沒有殘留過期引用。
- 檢查 `git diff --staged`，確認 commit 只包含同一個 slice 的檔案。
- 若動到 JSON metadata，必須先 parse 一次再 commit。
- 若動到 `SKILL.md` frontmatter，必須確認 `name` 與 `description` 合法且沒有 YAML parse 風險。

## Red Flags

- 「README / AGENTS 晚點再補」。
- 「這次只有改 skill 本體，索引文件不用動」。
- 「先做下一件事，commit 最後再說」。
- 「先全部混在一起，之後再拆 commit」。

以上任一條成立時，表示 slice 尚未完成。必須先同步文件與 metadata，確認類型，再 commit。

## Invalid Rationalizations

- 如果你認為 `SKILL.md` 才是唯一 source of truth，因此 README 或 AGENTS 之後再補，那是錯的；README、AGENTS 與 repo 指引都是正式 discovery surface。
- 如果你認為先把 skill 改完、等所有雜項收尾後再一起 commit 比較省事，那是錯的；完整且可驗證的 slice 應立刻 commit。
- 如果你認為可以等到最後再決定 `feat`、`fix`、`docs`，那是錯的；type 是 slice 邊界的一部分，開始 stage 前就應明確。
