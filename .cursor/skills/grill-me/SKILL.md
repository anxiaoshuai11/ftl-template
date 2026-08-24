---
name: grill-me
description: >-
  Relentless grill-me interview to lock design decisions (Q rounds with
  recommendations), then always persist the full Q&A into grill-me-conversation.md.
  Use when the user says grill-me, /grill-me, grill, 拷问, or asks to stress-test a
  plan/design before implementation.
---

# grill-me（含对话落盘）

先按下方 **grilling 流程** 提问；**每一轮用户作答后**，以及 **会话收口时**，必须把完整问答写入本地文件。不要只聊不写。

## 何时启用

- 用户触发：`grill-me`、`/grill-me`、`grill`、拷问、压力测试方案/设计
- 或用户明确要求「先 grill 再做」

## grilling 流程（必须遵守）

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Each question should be formatted like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on implementation until the user confirms you have reached a shared understanding.

## 强制：写入 `grill-me-conversation.md`

这是相对原版 grill-me 的增量要求——**每次使用本 skill 都必须落盘对话**。

### 文件路径（按优先级）

1. 若工作区已有功能目录（如 `*/spec.md` + `adr/` 或用户指定的 feature 目录）→ 写到该目录下的 `grill-me-conversation.md`
2. 否则写到当前工作区根目录：`grill-me-conversation.md`
3. 用户若指定路径，以用户为准

### 何时写

| 时机 | 动作 |
|------|------|
| Round 1 发出题目前 | 若文件不存在则创建，写标题、主题、Status=`in-progress` |
| 每一轮用户作答后 | **追加**本轮：完整题干 + 选项 + 推荐 + **用户原话/选项** |
| frontier 为空且用户确认可收口 | 更新 Status=`settled`，补「锁定结论速查」表 |
| 用户中途改口 | 追加「更正」小节，不要默默改掉上文 |

### 文件内容结构（必须）

```markdown
# grill-me 完整问答对话

> 主题：<一句话>
> 状态：in-progress | settled
> 日期：<YYYY-MM-DD>

## Round N

### ❓ Qx - <title>
<题干与选项全文>

➡️ <推荐>

**用户答复：** <原话或 Qx=A>

...
## 锁定结论速查
| 项 | 结论 |
```

要求：

- 保留 **❓ / ➡️ / 选项原文**，不要只写成「Q1→C」摘要表（摘要可另写 `grill-me-transcript.md`，但不能替代本文件）
- 用中文回复用户；文件正文可用中文
- 落盘用 Write/StrReplace 工具真实写文件，并在回复里告诉用户路径

### 与 ADR / spec 的关系

- `grill-me-conversation.md` = 对话过程
- `adr/` + `spec.md` = 决策结果（若用户同时要 tip-pool 结构，可另开；本 skill **至少**保证 conversation 文件）

## 收口后

简短告知：

1. `grill-me-conversation.md` 路径  
2. 已锁定的关键结论（3～6 条）  
3. 是否开始实现（等用户明确说「开始做」）
