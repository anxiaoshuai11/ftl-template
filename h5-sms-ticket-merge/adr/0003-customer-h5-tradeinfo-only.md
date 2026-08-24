# 顾客 H5 支付区只用 tradeInfo，不做刷卡联细节

短信 H5 的 Payment 区块只渲染订单侧 `tradeInfo`（多支付方式左右栏）。交易小票的 `transInfo`、`cardDetail`、签名、`tipType` Add Tips 勾选框等 **商户联/刷卡凭证** 能力不进入顾客页。

## 为什么

短信给的是 Customer Copy。产品确认前端只做模版、不需要旧交易小票刷卡联深度。图 1 支付区是 `Card(****9999) $xx` + `Cash $yy`，对应 `tradeInfo` 形态。把 tipType=0 勾选框放进已支付顾客页会误导。

## 关键权衡（被否决的备选）

- **尽量塞 Trade 字段（AID、Auth、签名）**：被否决。超出图 1 / 顾客场景。
- **按卡支付分支显示刷卡明细**：本期不做；若法务以后要签名，另开需求。
- **无支付仍显示 Unpaid 标题**：被否决。无 `tradeInfo` 时整块不渲染。

## 后果

- 拼盘 JSON 可保留 `transInfo` 等字段，但本模版不输出。
- 多支付靠 `tradeInfo.contentList` 多行即可。
- 与打印交易小票职责分离：打印继续用 `trade-ticket-template`。
