# h5-ftl-template：短信 H5 合并小票 FreeMarker 模版

Status: ready-for-agent

切片：`h5-ftl-template`。端：前端模版（交后端渲染）。总 spec：[`../spec.md`](../spec.md)。依赖：无代码依赖；数据契约见 [02](./02-demo-json-contract.md)。

产物：`../../h5-sms-ticket-template.ftl`

## Problem Statement

顾客短信短链需要一张合并订单+交易信息的手机收据页。组内既有订单/交易 FTL 是热敏 `table/tr/td` 体系；新模版必须同一套写法，且落实 grill-me 锁定的砍留与交互（胶囊、支付隐藏、Tax&Fee 弹层）。

## Solution

新建 `h5-sms-ticket-template.ftl`：外层与嵌套 `table/tr/td`，`max-width:430px`。渲染顺序：门店 → 单头 → 顾客 → 餐品/整单备注 → 金额 → 支付。辅助函数：`setLineSpacing`、`readText`、`buildOrderBadge`、`buildServerLabel`、`orderQuantityColumnWidth`。弹层原生 JS。

## User Stories

1. As a 顾客, I want 手机打开即见完整收据六段, so that 一次看清订单与支付。
2. As a 实现者, I want 布局全是 tr/td, so that 与旧小票渲染习惯一致。
3. As a 堂食顾客, I want 胶囊只显示订单类型, so that 符合产品更正后的口径。
4. As an OO 顾客, I want 胶囊带取餐码, so that 取餐方便。
5. As a 顾客, I want 点 Tax&Fee 的 i 看明细, so that 税费可拆。
6. As a 顾客, I want 无支付数据时不出现 Payment, so that 页面干净。

## Implementation Decisions

- 遵守 ADR-0001～0005。
- 门店：logo 有才显示；contentList 居中。
- 单头：左 `orderNumber`，右胶囊；下行时间 / Server。
- 顾客：contentList 居中，有则显。
- 餐品：1/2/3 列；child、remarkChild 跟行；101 删除线。
- 金额：左右栏；Total 放大；税行可出 i。
- 支付：仅 `tradeInfo` 多行。
- 不渲染：渠道、条码、评价、tip 勾选、刷卡联、双价等（见总 spec Out of Scope / 砍清单）。

## Testing Decisions

- 灌 Demo JSON 窄屏预览。
- 场景：堂食胶囊、OO 胶囊、无顾客、无支付、无/有 taxFeeDetailInfo、多支付、mod/备注。
- 不测打印旧 FTL、真短信网关。

## Out of Scope

- SPA、新接口、打印模版改写。
- 交易侧 transInfo/签名展示。

## Further Notes

- 图稿与口径冲突时以 ADR-0004 为准。
- 若后端以后要 576 宽，只改样式常量，不要退回热敏模块堆叠。
