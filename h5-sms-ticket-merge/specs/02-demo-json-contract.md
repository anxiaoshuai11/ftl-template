# demo-json-contract：拼盘 Demo 与字段契约

Status: ready-for-agent

切片：`demo-json-contract`。端：数据占位（给 FTL 预览与后端对照）。总 spec：[`../spec.md`](../spec.md)。依赖：无。被依赖：[01](./01-h5-ftl-template.md)。

产物：`../../demo-merged-ticket.json`

## Problem Statement

模版验收不能等真短链与真订单。需要一份可灌入 FreeMarker 的拼盘 JSON，字段名对齐飞书「订单小票数据模型」与「交易小票」文档，并补上 H5 弹层占位。

## Solution

维护 `demo-merged-ticket.json`：订单侧主字段 + 交易侧保留字段 + `taxFeeDetailInfo`。在 `_demoScenes`（或注释）标明堂食/OO 胶囊如何改数据验收。模版对缺失字段安全降级。

## User Stories

1. As a 实现者, I want 一份 JSON 直接预览整页, so that 不连后端也能改样式。
2. As a 后端同学, I want 字段名眼熟（*Info + contentList）, so that 灌数成本低。
3. As a 实现者, I want 能改 orderChannel/table 验证胶囊, so that ADR-0004 可回归。
4. As a 实现者, I want 可删 tradeInfo / taxFeeDetailInfo 看隐藏逻辑, so that 空数据行为明确。

## Implementation Decisions

- 遵守 ADR-0002、0003、0005。
- 主渲染字段：`merchantInfo`、`orderInfo`、`customerInfo`、`mealInfo`、`orderNoteInfo`、`orderAmountInfo`、`tradeInfo`、`taxFeeDetailInfo`、`ticketConfig`。
- 保留不渲染：`transInfo`、`cardDetail`、`amountInfo`（拼盘留给后端）。
- `orderAmountInfo` 税行可带 `showDetailIcon: true`；Total 可带 `isTotal: true`。
- `orderNumber` Demo 用 `{content:["#1"]}`；模版仍兼容纯字符串。

## Testing Decisions

- JSON 可被标准解析器解析（无尾逗号、无非法注释；说明放 `_demoScenes` 对象）。
- 切换 `_demoScenes` 所述字段后，人工预览胶囊与隐藏块。

## Out of Scope

- 真接口 schema、历史订单兼容迁移脚本。
- 金额计算逻辑（文案由后端预排进 content）。

## Further Notes

- 飞书文档里的 demo 可能含中文/非法 JSON 片段；本文件以可解析、可灌模版为准。
