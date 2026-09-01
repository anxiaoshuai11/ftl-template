# okr-showroom-docs：AI 样板间 KR1/KR2/KR3 材料

Status: ready-for-agent

切片：`okr-showroom-docs`。端：文档 / OKR。总 spec：[`../spec.md`](../spec.md)。依赖：案例产物 [01](./01-h5-ftl-template.md)、[02](./02-demo-json-contract.md)。

产物：

- `../../KR1-可复用案例.md`
- `../../KR2-实践文档.md`
- `../../KR3-效率基线报告.md`
- `../../OKR-样板间材料.md`（索引）
- 本目录 `../`（grill-me 上下文：spec + adr + specs）

## Problem Statement

O2 要求三个 KR：**可复用案例、实践文档、效率基线**。不能只交一个 FTL。需要把本次 grill-me + 实现沉淀成组内可挂载的文档，并能量化手写 vs AI。

## Solution

KR 各一份 md；另建本 `h5-sms-ticket-merge/` 作为 tip-pool 同款的 grill-me 文件上下文（`adr/` + `spec.md` + `specs/`）。工时口径：全周期含需求理解与 grill-me，上报节省约 20%；采集表见 KR3。

## User Stories

1. As a 前端同学, I want KR1 有可复制案例包说明, so that 样板间能挂链接。
2. As a 前端同学, I want KR2 有流程/提示词/Checklist, so that 组内有默认标准。
3. As a 前端同学, I want KR3 有指标与采集表, so that 能交初版基线报告。
4. As an Agent, I want adr/spec 目录可被再次加载, so that 后续改模版不丢口径。

## Implementation Decisions

- KR1：案例清单、字段对照、复用步骤、DoD。
- KR2：工作流、Checklist、可复用提示词、踩坑、口径锁定表。
- KR3：指标定义、采集表、初版报告、计时边界（不含等后端）。
- grill-me 决策写入 ADR，避免只活在聊天记录里。
- 对照口径写明：本人估时 vs AI 实测（非第二人盲做）。

## Testing Decisions

- 文档互链可点：索引 ↔ KR1/2/3 ↔ 本 specs。
- KR3「AI 实测」列需人工补墙钟后才算采集完成。
- 不把文档写作时间与等产品空窗计入开发工时（可单列）。

## Out of Scope

- 强制独立 Git 仓库（可文件夹/飞书挂载）。
- 组内评审会议本身（DoD 勾选由负责人组织）。

## Further Notes

- 可上报一句话见 `KR3-效率基线报告.md`。
- 若样板间要迁到「AI agent」目录，整夹移动 `h5-sms-ticket-merge/` 即可，记得改相对路径。
