# 订单+交易合并小票 · OKR 材料索引

> 对应 OKR **O2**：完成前端 AI 样板间核心能力落地，支撑组内规范沉淀与效率基线测算（截止 09-30）

## 三个 KR（飞书云文档，组内可点）

| KR | 飞书文档 | 一句话 |
|----|----------|--------|
| **KR1** | [KR1 可复用案例](https://zath6evqnvz.feishu.cn/wiki/ATglwvtpAidD85kHEjfcPkUQnVe) | 已提 MR 的真实案例 + clone 即用的工具仓 |
| **KR2** | [KR2 实践文档](https://zath6evqnvz.feishu.cn/wiki/VJNGwzbzyitgr1kONzlcWCqKnQe) | 组内默认标准，关键环节已工具化 |
| **KR3** | [KR3 效率基线](https://zath6evqnvz.feishu.cn/wiki/HRmAwIkjEiHzXfk31THcnzU0n0c) | 效率 + 质量双维基线 |

## 交付物（GitLab，不用传飞书附件）

| 交付物 | 位置 |
|--------|------|
| 小票模版 MR | [print-util !88](http://gitlab.zbspos.com/posbee-microservice/print-util/-/merge_requests/88) |
| 工具链与 skill 仓库 | [Shawn/ftl-util](http://gitlab.zbspos.com/Shawn/ftl-util) |
| 完整案例（FTL + JSON + MR 描述范例） | `ftl-util` 的 `examples/order-trade-ticket/` |

业务需求：[订单短信/邮件小票样式优化](https://zath6evqnvz.feishu.cn/wiki/KOokwhaejicNWpkVyG9c5618n8b)

数据参考：[订单小票数据模型](https://zath6evqnvz.feishu.cn/wiki/KBjtwETU1ihxqIkrnakcnkYyntf) · [交易小票](https://zath6evqnvz.feishu.cn/wiki/OvNowmXhFiCaQ0kP3RRcBc98nP8)

## 同事怎么复用

```bash
git clone http://gitlab.zbspos.com/Shawn/ftl-util.git
```

用 Cursor 打开，三个 skill 自动生效，然后给三样东西：需求文档链接、FTL、JSON。
详见 [KR1 可复用案例](https://zath6evqnvz.feishu.cn/wiki/ATglwvtpAidD85kHEjfcPkUQnVe)。

## 本地文件（Cursor / Git 可点，飞书不解析）

| KR | 文档 |
|----|------|
| KR1 | [KR1-可复用案例.md](./KR1-可复用案例.md) |
| KR2 | [KR2-实践文档.md](./KR2-实践文档.md) |
| KR3 | [KR3-效率基线报告.md](./KR3-效率基线报告.md) |

口径锁定过程（grill-me 上下文）：[`h5-sms-ticket-merge/`](./h5-sms-ticket-merge/)，含 `spec.md` + `adr/` + `specs/`。
