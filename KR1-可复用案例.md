# KR1 · 完成 AI 样板间交付，形成可复用案例

> 归属 OKR **O2**：完成前端 AI 样板间核心能力落地，支撑组内规范沉淀与效率基线测算（截止 09-30）  
> 权重：33.3%  
> 业务需求：[订单短信/邮件小票样式优化](https://zath6evqnvz.feishu.cn/wiki/KOokwhaejicNWpkVyG9c5618n8b)  
> 数据参考：[订单小票数据模型](https://zath6evqnvz.feishu.cn/wiki/KBjtwETU1ihxqIkrnakcnkYyntf) · [交易小票](https://zath6evqnvz.feishu.cn/wiki/OvNowmXhFiCaQ0kP3RRcBc98nP8)

**本 KR 交付物：** 可运行的案例包（FTL + Demo JSON + 字段对照 + 复用步骤），组内可直接照抄。

配套文档：[KR2-实践文档.md](./KR2-实践文档.md) · [KR3-效率基线报告.md](./KR3-效率基线报告.md)

---

## 1. 案例一句话介绍（可贴样板间首页）

> 将「订单小票 + 交易小票」两套热敏 FTL/JSON，收敛为短信短链场景下的 **一张 H5 FreeMarker 模版**；数据沿用既有 `*Info` 拼盘占位，含 Tax&Fee 弹层与多支付展示，可作为「旧模版合并 → 新 H5 模版」的可复用样板。

---

## 2. 案例包清单

| 文件 | 用途 | 状态 |
|------|------|------|
| `h5-sms-ticket-template.ftl` | 合并订单+交易后的短信 H5 模版 | 已交付 |
| `demo-merged-ticket.json` | 拼盘 Demo 数据（订单侧为主，交易侧字段保留） | 已交付 |
| `KR1-可复用案例.md` | 本说明（案例入口） | 已交付 |
| 旧参考 `order-ticket-template(37).ftl` | 订单热敏小票（对照用，非本案例主交付） | 已有 |
| 旧参考 `trade-ticket-template(54).ftl` | 交易热敏小票（对照用） | 已有 |

---

## 3. 别人怎么复用（最小步骤）

1. 复制 `h5-sms-ticket-template.ftl` + `demo-merged-ticket.json`
2. 用组内 FreeMarker 渲染入口灌入 Demo JSON 预览
3. 按业务改字段映射时，先改 JSON，再改 FTL 中对应 `#if` / `#list`
4. 提示词复用 [KR2-实践文档.md](./KR2-实践文档.md) 中的「可复用 AI 提示词」

### 预览检查

1. 窄屏查看；验证胶囊、多支付、Tax&Fee `i` 弹层
2. OO 场景：`orderChannel=1`，清空 `table`，确认胶囊为 `Pickup / P00001`
3. 堂食场景：有桌台也只显示 `Dine In`，不拼接桌台号

---

## 4. 模块 ↔ 字段对照

| UI 模块 | 主要字段 | 规则摘要 |
|---------|----------|----------|
| 页头 | `merchantInfo.logo`、`merchantInfo.contentList` | Logo 有才显示；名称/地址/电话完整展示 |
| 单头-单号 | `orderInfo.orderNumber` | 大号；兼容字符串或 `{content:[]}` |
| 单头-胶囊 | `diningOption` +（条件）`confirmationNumber` | 有桌台只显示类型；OO 无桌台有取餐码显示 `类型 / 码`；不显示渠道；不拼桌台 |
| 单头-时间 / Server | `orderTime` / `server` | Server 有则显；已含前缀不重复 |
| 顾客 | `customerInfo.contentList` | 有则显 |
| 餐品 | `mealInfo` + `child` + `remarkChild` | 数量/名称/价格；备注与 Mod 有则显 |
| 整单备注 | `orderNoteInfo` | 有则显 |
| 金额 | `orderAmountInfo` | Total 放大；Tax 行可出 `i` |
| Tax&Fee 弹层 | `taxFeeDetailInfo`（新增占位） | 无数据不显示 `i`、不渲染弹层 |
| 支付 | `tradeInfo` | 无数据整块不渲染；支持多支付 |
| 交易侧保留不渲染 | `transInfo` / `cardDetail` / `amountInfo` | 拼盘留给后端；本 H5 不做刷卡联细节 |

**明确不进本案例模版：** 渠道、评价/二维码、条码、底图、Tip 勾选、刷卡价/现金价、礼品卡交易块、Merchant Copy、热敏 576 定宽。

---

## 5. 与旧 FTL 的关系

- `order-ticket-template(37).ftl` / `trade-ticket-template(54).ftl`：**打印继续用**
- 本案例是 **短信短链 H5 新模版**
- 仅 `taxFeeDetailInfo` 为弹层新增占位，需后端后续灌数

---

## 6. KR1 完成定义（DoD）

- [x] 有可打开的 FTL + Demo JSON
- [x] 有字段对照与边界规则（胶囊 / 支付隐藏 / 弹层）
- [ ] 组内至少 1 人按「复用步骤」能独立跑通预览（需组织）
- [ ] 样板间目录/飞书链接收录本案例（需挂载）
