# 订单+交易合并小票 · OKR 材料索引（飞书粘贴稿）

> 用途：粘到**前端飞书 / 样板间**索引页。
> 三个 KR 云文档已建好，链接已填实，下方内容可直接整段复制。

---

## ↓↓↓ 以下复制到飞书 ↓↓↓

**订单+交易合并小票 · OKR 材料索引**

对应 OKR **O2**：完成前端 AI 样板间核心能力落地，支撑组内规范沉淀与效率基线测算（截止 09-30）

**三个 KR：**

| KR | 文档 | 一句话 |
|----|------|--------|
| KR1 | [KR1 可复用案例](https://zath6evqnvz.feishu.cn/wiki/ATglwvtpAidD85kHEjfcPkUQnVe) | 已提 MR 的真实案例 + clone 即用的工具仓 |
| KR2 | [KR2 实践文档](https://zath6evqnvz.feishu.cn/wiki/VJNGwzbzyitgr1kONzlcWCqKnQe) | 组内默认标准，关键环节已工具化 |
| KR3 | [KR3 效率基线](https://zath6evqnvz.feishu.cn/wiki/HRmAwIkjEiHzXfk31THcnzU0n0c) | 效率 + 质量双维基线 |

**交付物：**

- 小票模版 MR：[print-util !88](http://gitlab.zbspos.com/posbee-microservice/print-util/-/merge_requests/88)
- 工具链与 skill 仓库：[Shawn/ftl-util](http://gitlab.zbspos.com/Shawn/ftl-util)
- 完整案例（FTL + JSON + MR 描述范例）：`ftl-util` 的 `examples/order-trade-ticket/`
- Chrome 扩展 · FTL 小票预览：[common-util/browser-extend](http://gitlab.zbspos.com/common-util/browser-extend)

业务需求：[订单短信/邮件小票样式优化](https://zath6evqnvz.feishu.cn/wiki/KOokwhaejicNWpkVyG9c5618n8b)

**同事怎么复用：**

1. `git clone http://gitlab.zbspos.com/Shawn/ftl-util.git`
2. 用 Cursor 打开，`.cursor/skills/` 里四个 skill 自动生效，无需任何配置
3. 小票模版给三样：需求文档链接、FTL、JSON；其他需求给两样：需求文档链接、目标仓库（`req-to-mr`）
4. 都会走完：飞书需求 → 编码 → 自测出报告 → 提 MR

中途它会停下来问口径，那不是卡住，是在等你拍板——需求文档最常漏写的就是
「某个字段没数据时该显示什么」。

**这套流程的自测能测什么：** 空值风险（`${}` 取不到值又没写默认值，线上会抛异常）、
数组越界、指令未闭合。**测不到：** 真实引擎渲染、视觉样式、邮件客户端兼容性、
短信通道、业务口径——这些报告里会如实列出来，不会假装测过了。

## ↑↑↑ 以上复制到飞书 ↑↑↑

---

## 链接登记表

| 材料 | 链接 |
|------|------|
| 索引页（本文所在页） | （待填） |
| KR1 | https://zath6evqnvz.feishu.cn/wiki/ATglwvtpAidD85kHEjfcPkUQnVe |
| KR2 | https://zath6evqnvz.feishu.cn/wiki/VJNGwzbzyitgr1kONzlcWCqKnQe |
| KR3 | https://zath6evqnvz.feishu.cn/wiki/HRmAwIkjEiHzXfk31THcnzU0n0c |
| 模版 MR | http://gitlab.zbspos.com/posbee-microservice/print-util/-/merge_requests/88 |
| 工具仓 | http://gitlab.zbspos.com/Shawn/ftl-util |
| Chrome 扩展 | http://gitlab.zbspos.com/common-util/browser-extend |
| 业务需求 | https://zath6evqnvz.feishu.cn/wiki/KOokwhaejicNWpkVyG9c5618n8b |

代码与数据不再传飞书附件，统一放 GitLab，避免两处版本不一致。
