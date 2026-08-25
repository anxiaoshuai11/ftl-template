# 短信 H5 合并小票（订单+交易）

Status: ready-for-agent

决定见 `adr/`。按交付切片拆开的实现 spec 见 [`specs/00-index.md`](specs/00-index.md)。

业务需求：[订单短信/邮件小票样式优化](https://zath6evqnvz.feishu.cn/wiki/KOokwhaejicNWpkVyG9c5618n8b)  
数据参考：[订单小票数据模型](https://zath6evqnvz.feishu.cn/wiki/KBjtwETU1ihxqIkrnakcnkYyntf) · [交易小票](https://zath6evqnvz.feishu.cn/wiki/OvNowmXhFiCaQ0kP3RRcBc98nP8)

关联产物（同级目录）：

- `../order-trade-ticket-template.ftl`
- `../demo-merged-ticket.json`
- `../KR1-可复用案例.md` / `../KR2-实践文档.md` / `../KR3-效率基线报告.md`

## Problem Statement

结账后短信短链目前打开的是交易小票风页面，顾客看不到菜品明细，样式也不友好。业务要合并「订单小票 + 交易小票」为一张顾客可读的 H5；语言仅英文；入口与短链不变。旧热敏打印 FTL（订单/交易）继续服务打印，不能被这次改坏。同时本需求要作为前端 AI 样板间案例，支撑 OKR 的可复用案例、实践文档与人机工时基线。

## Solution

新建一张短信 H5 FreeMarker 模版（`table/tr/td` 布局，对齐现有订单/交易 FTL 写法），视觉按移动端收据，不走热敏 576 打印壳。数据用既有订单 JSON + 交易 JSON **拼盘占位**，不新调接口、不强制新 DTO。页面六段：门店、单头、顾客（有则显）、餐品、金额、支付（无则整块藏）。支付只用订单侧 `tradeInfo`；Tax&Fee 用新增占位 `taxFeeDetailInfo` 做 `i` 弹层。打印侧两套旧 FTL 不动。

## User Stories

1. As a 顾客, I want 点开短信短链看到门店、订单、菜品、金额、支付五类信息, so that 不必再猜交易小票上缺的菜品。
2. As a 顾客, I want 页面是手机可读的 H5 而不是热敏长条打印样式, so that 在手机上好扫一眼。
3. As a 顾客, I want 文案为英文, so that 与现网短信小票语言一致。
4. As a 店长, I want 短信发送入口与短链习惯不变, so that 结账流程不用重新培训。
5. As a 堂食顾客, I want 单头胶囊只显示 `Dine In` 这类订单类型, so that 不被桌台号干扰（产品确认图稿带桌台是错的）。
6. As an OO 顾客, I want 无桌台时胶囊显示 `Pickup / 取餐码`, so that 取餐码一眼能看到。
7. As a 顾客, I want 有顾客姓名/电话/取餐时间时才出现顾客区, so that 空字段不占版面。
8. As a 顾客, I want 菜品显示数量、名称、价格、加料与备注, so that 能核对点了什么。
9. As a 顾客, I want 金额区能点 Tax & Fee 的 `i` 看明细弹层, so that 税与费拆得清。
10. As a 顾客, I want 多支付方式分行显示（如 Card + Cash）, so that 对得上实付。
11. As a 顾客, I want 没有支付数据时整块 Payment 不出现, so that 不会看到半截空支付区。
12. As a 实现者, I want 模版用与旧 FTL 相同的 `tr/td` 写法, so that 后端渲染链路与既有小票一致、好维护。
13. As a 实现者, I want Demo JSON 能单独灌进模版预览, so that 不依赖后端真接口也能验收布局。
14. As a 前端同学, I want 本案例沉淀为样板间可复用包, so that 组内下次合并旧模版能照抄。
15. As a 前端同学, I want 有实践文档（流程/提示词/Checklist）, so that AI 辅助开发有默认标准。
16. As a 前端同学, I want 有人机工时基线表, so that OKR 能量化手写 vs AI 差距。

## Implementation Decisions

- 遵守 ADR-0001：新建 H5 FTL，不改写热敏订单/交易打印模版，不做 SPA。
- 遵守 ADR-0002：数据契约为旧 JSON 拼盘占位；字段名沿用 `merchantInfo` / `mealInfo` / `orderAmountInfo` / `tradeInfo` 等。
- 遵守 ADR-0003：支付区只渲染 `tradeInfo`；`transInfo` / `cardDetail` / 签名 / tipType 勾选框不进顾客 H5。
- 遵守 ADR-0004：胶囊有桌台只显示 `diningOption`；OO（`orderChannel=1`）且无桌台有 `confirmationNumber` 时显示 `类型 / 取餐码`；不显示渠道；桌台不进胶囊。
- 遵守 ADR-0005：Tax&Fee 弹层依赖 `taxFeeDetailInfo`；无数据不显示 `i`、不渲染弹层。
- 布局：`table/tr/td` + 嵌套 table；短信页 `max-width:430px`；虚线分隔；仅英文。
- 模块开关：无 `ticketConfig` 默认展示；`showPart=false` 时隐藏对应块。
- `orderNumber` 兼容字符串与 `{content:[]}`。
- Server：有则显；content 已含 `Server` 前缀则不重复拼接。
- 明确砍掉：渠道、评价/二维码、条码、底图、Tip Suggestions/Add Tips、刷卡价/现金价、礼品卡交易块、Merchant Copy、热敏 576 定宽。

## Testing Decisions

- 用 `demo-merged-ticket.json` 灌模版做静态预览，不连真短链环境亦可验收布局。
- 必测场景：
  - 堂食：有 `table` 时胶囊仅为 `Dine In`。
  - OO：`orderChannel=1`、空 table、有 confirmation → `Pickup / P00001`。
  - 无 `customerInfo` → 顾客整块不出现。
  - 无 `tradeInfo` → Payment 整块不出现。
  - 无 `taxFeeDetailInfo` → 无 `i`、无弹层；有则点 `i` 可开关。
  - 菜品 `child` / `remarkChild` 缩进与价格右对齐。
  - `contentType=101` 删除线。
  - 多支付两行金额。
- 不测：打印热敏两套旧 FTL、短信网关、后端灌数接口。

## Out of Scope

- Admin / Kiosk / 平板 / KDS / 叫号屏 / Online Order / 老板手机端改动。
- 新调后端接口或新聚合 DTO（可后续迭代）。
- 顾客 H5 展示 AID、Auth Code、签名、Add Tips 勾选。
- 多语言（本期仅英文）。
- 替换打印订单/交易小票。

## Further Notes

- grill-me 已锁定口径后再写模版；图稿与口头不一致时以口头/ADR 为准（胶囊不带桌台）。
- OKR 材料拆成 KR1/KR2/KR3 三份 md，见同级目录与 `specs/03-okr-showroom-docs.md`。
- 手写基线估时 14h，AI 目标约 7h；实测以 KR3 采集表为准。
