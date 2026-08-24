# grill-me 对话纪要（已锁定口径）

Status: settled

> 完整题干/选项/推荐回放见：**[grill-me-conversation.md](./grill-me-conversation.md)**  
> 本文件仅保留结论速查，供扫一眼。

详细理由以 `adr/` 为准。

## Round 1

| Q | 结论 |
|---|------|
| Q1 交付物 | **C**：合并成一个新 FTL，视觉跟 H5 图 |
| Q2 数据 | 用订单/交易两份飞书 JSON 做占位，不调接口 |
| Q3 刷卡联 | 不需要；前端只做模版 |
| Q4 样板间 | 后澄清为案例包材料，不必强求独立 git |
| Q5 工时 | 手写 FTL vs AI 写 FTL；口径后定为拆包估时 |

## Round 2

| Q | 结论 |
|---|------|
| Q6 OKR 材料 | **C**：FTL + Demo JSON + 字段对照 + 提示词 + 工时表 |
| Q7 工时 | 手写中位 **14h**，AI 目标约 **7h** |
| Q8 弹窗 | **做**；`taxFeeDetailInfo` 有数据才显示 |
| Q9 JSON 形态 | **A**：拼盘保留两边字段 |
| Q10 砍留 | **A**：渠道/评价/条码/小费勾选/双价等砍掉 |

## Round 3

| Q | 结论 |
|---|------|
| Q11 | **A**：手写 14h / AI 目标 7h |
| Q12 支付 | **A**：只用 `tradeInfo` |
| Q13 胶囊 | 有桌台只显示类型；OO 无桌台有码：`Pickup / P00001`；双有不考虑 |
| Q13 更正 | 图上 `Dine In / A003` 画错，**只要 `Dine In`** |
| Q14 无支付 | **A**：整块不渲染 |
| Q15 | 共享理解达成，开始做 |

## 后补约束

- 模版布局必须与订单/交易 FTL 一样使用 **`table/tr/td`**（非 flex/div 主结构）。

## 设计树终点

frontier 已空；实现以 `../spec.md` + ADR 为准，改口径先改 ADR 再改 FTL。
