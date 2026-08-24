# 单头胶囊：堂食只显示类型；OO 无桌台拼取餐码

右侧订单类型胶囊规则：

| 场景 | 胶囊文案 |
|------|----------|
| 有桌台（堂食等） | 只显示 `diningOption`（如 `Dine In`），**不拼** `/ 桌台号` |
| OO（`orderChannel=1`）、无桌台、有取餐码 | `diningOption / confirmationNumber`（如 `Pickup / P00001`） |
| 又有桌台又有取餐码 | 产品确认不存在，不考虑 |

不显示下单渠道。大号单号用 `orderInfo.orderNumber`。

## 为什么

图稿曾画出 `Dine In / A003`，产品口头更正：有桌台只要 `Dine In`。图 5 要求 OO 显示取餐码且不显示渠道。桌台不进胶囊，避免与「只要类型」冲突。

## 关键权衡（被否决的备选）

- **跟错图：`Dine In / A003`**：被否决。
- **取餐码单独一行**：可后续改，本期先把码放进胶囊以贴图 1 信息密度。
- **OO 大号改用 confirmationNumber**：被否决。大号保持 ticket/orderNumber。

## 后果

- 模版内 `buildOrderBadge` 集中实现，避免多处 if。
- 桌台字段可在 JSON 中存在，但 H5 单头不展示（除非以后产品加回）。
- 预览验收必须覆盖堂食与 OO 两种胶囊。
