# KR1 · 完成 AI 样板间交付，形成可复用案例

> 归属 OKR **O2**：完成前端 AI 样板间核心能力落地，支撑组内规范沉淀与效率基线测算（截止 09-30）
> 权重：33.3%
> 业务需求：[订单短信/邮件小票样式优化](https://zath6evqnvz.feishu.cn/wiki/KOokwhaejicNWpkVyG9c5618n8b)
> 数据参考：[订单小票数据模型](https://zath6evqnvz.feishu.cn/wiki/KBjtwETU1ihxqIkrnakcnkYyntf) · [交易小票](https://zath6evqnvz.feishu.cn/wiki/OvNowmXhFiCaQ0kP3RRcBc98nP8)

**本 KR 交付物：** 一个已提 MR 的真实案例，加一个同事 clone 即用的工具仓库。

配套文档：[KR2 实践文档](https://zath6evqnvz.feishu.cn/wiki/VJNGwzbzyitgr1kONzlcWCqKnQe) · [KR3 效率基线](https://zath6evqnvz.feishu.cn/wiki/HRmAwIkjEiHzXfk31THcnzU0n0c)

---

## 1. 案例介绍

> 把「订单小票 + 交易小票」两套热敏 FTL/JSON，收敛成短信短链场景下的**一张 H5 FreeMarker 模版**，
> 并把「飞书需求 → 编码 → 自测出报告 → 提 MR」固化成可执行的工具与 skill。
> 小票需求给三样东西就能跑：需求文档链接、FTL、JSON。
> 其他需求走同一条链路：给飞书文档链接和目标仓库即可（`req-to-mr`，不绑定技术栈）。

---

## 2. 交付物

| 交付物 | 位置 | 状态 |
|--------|------|------|
| 合并后的 H5 小票模版 | [print-util !88](http://gitlab.zbspos.com/posbee-microservice/print-util/-/merge_requests/88) | 已提 MR，待评审合入 |
| 工具链与 skill 仓库 | [Shawn/ftl-util](http://gitlab.zbspos.com/Shawn/ftl-util) | 已发布，clone 即用 |
| 完整案例（FTL + JSON + MR 描述范例） | `ftl-util` 的 `examples/order-trade-ticket/` | 已交付 |
| Chrome 扩展 · FTL 小票预览 | [common-util/browser-extend](http://gitlab.zbspos.com/common-util/browser-extend) | 已发布；开发者模式加载后，上传 FTL + JSON 即可看样式 |

模版本体交付到 `print-util` 的 `src/main/resources/templates/`，工具仓只放工具，两者边界清晰。

**交付的不只是代码，还有流程。** 只给 FTL 和 JSON 的话，拿到的人还得自己想怎么测、
怎么提 MR，可复用的只有代码。所以把自测与提 MR 这两个环节也一并沉淀成了工具。
同一条「飞书需求 → 编码 → 自测出报告 → 提 MR」也抽成了通用 skill `req-to-mr`，
非小票需求同样能用，验证手段按目标仓库已有能力探测（lint / 单测 / 构建），不假设某种框架。

---

## 3. 别人怎么复用

```bash
git clone http://gitlab.zbspos.com/Shawn/ftl-util.git
```

用 Cursor 打开，`.cursor/skills/` 里四个 skill 自动生效，不需要任何配置。

**小票模版**走 `ftl-ticket-workflow`，给三样东西：

```
按流程做这个需求：<飞书文档链接>
模版：<你的.ftl>
数据：<你的.json>
目标仓库：<你本地的 print-util 路径>
```

**其他需求**走 `req-to-mr`，同一条链路，不绑定技术栈：

```
按流程做这个需求：<飞书文档链接>
目标仓库：<你本地的仓库路径>
```

都会依次做完：读需求列改动清单 → 对齐口径 → 编码 → 自测出报告 → 建分支 → 提 MR。
小票路径还会出 HTML 预览；通用路径的验证按目标仓库已有手段探测，仓库没有单测会如实写进 MR，不假装测过。

**中途它会停下来问你，那不是卡住，是在等你确认口径。** 需求文档最常漏写的就是
「这个字段没数据时该显示什么」——整块隐藏、显示占位、还是显示 0，必须人来拍板。

新增模版和修改现有模版都覆盖。修改现有模版时会强制做改动前后回归对比，
只报「这次改出来的问题」，老模版本来就带着的告警不会拦你。

只想看样式、不走整条流程时，用 Chrome 扩展 [FTL 小票预览](http://gitlab.zbspos.com/common-util/browser-extend)：
开发者模式加载后，上传 FTL + Demo JSON，右侧实时渲染，可切「样式预览 / 尽力求值」，可下载 `preview.html`。
自测、回归、提 MR 仍走 `ftl-util`，插件不替代那条链路。

---

## 4. 自测结论（可验证，不是自我评价）

模版本身：

| 项 | 结果 |
|----|------|
| 场景数 | 15（仅税 / 仅费 / 无税无费 / 无顾客 / 无支付 / 有无 Logo / OO 取餐码 / 堂食桌台 / 整单备注 / 三种分区开关 / 单号字符串兼容） |
| 错误 | 0 |
| 告警 | 0 |
| 可判定顶层分区覆盖 | 16/16（100%） |
| 静态分析判不了的分支 | 2 个（条件依赖自定义函数返回值），已人工看预览确认 |

**自测覆盖不到的部分**（已写进 MR 描述留给评审）：真实 FreeMarker 引擎渲染结果、
视觉样式细节、邮件客户端兼容性、短信通道与短链跳转、业务口径是否符合产品预期。

工具本身也做了反向验证，避免「永远报绿」：

- 故意做坏的数据 → 退出码 1，报出错误 1、告警 5
- 故意引入回归（加一个取不到值的 `${}` 和一个新分支）→ 全部被拦截并标出该补用例
- 只挪动行号不改语义 → 报 0 个新增问题，不产生误报

---

## 5. 模块 ↔ 字段对照

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
| Tax&Fee 折叠 | `taxFeeDetailInfo`（新增占位） | 无数据不显示 `i`、不渲染折叠区；有则点汇总行原生展开 |
| 支付 | `tradeInfo` | 无数据整块不渲染；支持多支付 |
| 交易侧保留不渲染 | `transInfo` / `cardDetail` / `amountInfo` | 拼盘留给后端；本 H5 不做刷卡联细节 |

**明确不进本案例模版：** 渠道、评价/二维码、条码、底图、Tip 勾选、刷卡价/现金价、
礼品卡交易块、Merchant Copy、热敏 576 定宽。

---

## 6. 与旧 FTL 的关系

- `order-ticket-template.ftl` / `trade-ticket-template.ftl`：**热敏打印继续用，本次不动**
- 本案例是**短信短链 H5 新模版**，只新增不改动
- 仅 `taxFeeDetailInfo` 为折叠明细新增占位，需后端灌数，结构与其他 `*Info` 一致

---

## 7. KR1 完成定义（DoD）

- [x] 有可运行的 FTL + Demo JSON
- [x] 有字段对照与边界规则（胶囊 / 支付隐藏 / Tax&Fee 折叠）
- [x] 交付物已进入正式评审流程（[print-util !88](http://gitlab.zbspos.com/posbee-microservice/print-util/-/merge_requests/88)）
- [x] 复用方式从「照抄文件」升级为「clone 即用」（[Shawn/ftl-util](http://gitlab.zbspos.com/Shawn/ftl-util)）
- [ ] 组内至少 1 人按复用步骤独立跑通
- [ ] 样板间目录收录本案例
- [ ] 工具仓迁至 `common-util` 群组，便于交接
