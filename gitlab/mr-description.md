## 需求

[订单短信/邮件小票样式优化](https://zath6evqnvz.feishu.cn/wiki/KOokwhaejicNWpkVyG9c5618n8b)

结账完成后发送的短信小票改为 H5 形式，把原来分开的**订单小票**和**交易小票**合并成一张，
顾客点短链即可看到门店、订单、菜品、金额、支付五部分完整信息。仅英文。

## 改动

新增 `src/main/resources/templates/order-trade-ticket-template.ftl`。

**只新增，不改动现有模版。** `order-ticket-template.ftl` 和 `trade-ticket-template.ftl`
是热敏打印用的，继续保持原样，本次不动。

模块与字段对应关系：

| 模块 | 数据字段 | 规则 |
|------|----------|------|
| 页头 | `merchantInfo.logo`、`merchantInfo.contentList` | Logo 有才显示；名称地址完整展示 |
| 单头 | `orderInfo` | 单号大号显示；不显示下单渠道 |
| 单头胶囊 | `diningOption` + `confirmationNumber` | 有桌台只显示类型；OO 单无桌台有取餐码时显示「类型 / 取餐码」；不拼桌台号 |
| 顾客 | `customerInfo.contentList` | 有则显，无则整块不渲染 |
| 餐品 | `mealInfo` + `child` + `remarkChild` | 含单品折扣与备注 |
| 金额 | `orderAmountInfo` | Total 放大；Tax&Fee 行带 `i` 图标 |
| Tax&Fee 弹层 | `taxFeeDetailInfo`（新增占位字段） | 无数据则不显示 `i`、不渲染弹层与弹层 JS |
| 支付 | `tradeInfo` | 无数据整块不渲染；支持多支付方式 |

技术上沿用旧模版的 `table/tr/td` 结构以保证邮件客户端兼容性，弹层用原生 JS，无外部依赖。

## 需要后端配合

`taxFeeDetailInfo` 是本次新增的占位字段，需要后端灌数，结构与其他 `*Info` 一致：

```json
{ "title": "Taxes & Fees", "contentList": [{ "content": ["Sales Tax", "$1.02"] }] }
```

`title` 按实际内容下发 `Tax` / `Fees` / `Taxes & Fees`；不下发该字段时模版会自动隐藏 `i` 图标和弹层。

## 自测结果

用 `ftl-selftest` 工具跑了 15 组场景，**累计错误 0 项、告警 0 项**，
可判定的顶层分区合并覆盖 **16/16（100%）**。

| 场景 | 验证点 | 错误 | 告警 |
|------|--------|------|------|
| 基线-完整数据 | 所有分区都应显示，不应有任何错误 | 0 | 0 |
| 仅税 | 汇总行文案为 Tax，弹层只列税项 | 0 | 0 |
| 仅费 | 汇总行文案为 Fees，弹层只列费用项 | 0 | 0 |
| 无税无费 | 不渲染 `i` 图标，不渲染弹层与弹层 JS | 0 | 0 |
| 无顾客信息 | 顾客分区整块不渲染，分隔线不重复 | 0 | 0 |
| 无支付信息 | Payment 整块不渲染（含标题与分隔线） | 0 | 0 |
| 无门店 Logo | 不出图片，按配置决定是否走占位图标 | 0 | 0 |
| OO 取餐码胶囊 | 胶囊显示「类型 / 取餐码」，不显示桌台 | 0 | 0 |
| 堂食有桌台 | 胶囊只显示 Dine In，不拼接桌台号 | 0 | 0 |
| 带整单备注 | 整单备注行正常渲染 | 0 | 0 |
| 有门店 Logo | logo 有值时渲染图片，不走占位图标 | 0 | 0 |
| 配置关闭餐品分区 | `ticketConfig.meal.showPart` 为 false 时餐品整块不渲染 | 0 | 0 |
| 配置关闭门店分区 | `ticketConfig.merchant.showPart` 为 false 时页头整块不渲染 | 0 | 0 |
| 配置关闭金额分区 | `ticketConfig.expense.showPart` 为 false 时金额整块不渲染 | 0 | 0 |
| 单号为字符串 | `orderNumber` 是纯字符串时也能正常渲染（环境差异兼容） | 0 | 0 |

覆盖三类运行时故障：空值风险（`${}` 取不到值又没写 `!默认值`，会抛 `InvalidReferenceException`）、
数组越界（`content[n]` 超出实际长度）、指令闭合（`<#if>` / `<#list>` 未配对）。

附件（存于 GitLab 附件区，**未提交进仓库**，本 MR 变更文件只有一个 `.ftl`）：

- 完整自测报告：[order-trade-ticket-template.selftest-suite.md](/uploads/acc4afe13998ccd5bfe94f0eebba38bb/order-trade-ticket-template.selftest-suite.md)
- 样式预览（下载后用浏览器打开）：[order-trade-ticket-template.preview.html](/uploads/6ecfa7c54bee3e0a6c5ca675bc82d150/order-trade-ticket-template.preview.html)

### 自测覆盖不到的部分，请评审留意

自测是静态推演，**不启动 FreeMarker 引擎**，以下几项没有被验证过，不要因为上表全绿就认为已验收：

1. **两个分支静态分析判不了真假**（条件依赖自定义函数返回值），已通过本地 HTML 预览人工确认：
   第 301 行 `orderBadgeText?has_content`、第 317 行 `serverLabelText?has_content`
2. **真实 FreeMarker 引擎的渲染结果**
3. **视觉样式**：断行、对齐、长文案溢出、税费弹层位置
4. **邮件客户端兼容性**：Outlook 走 Word 引擎、Gmail 会剥离 `<style>`
5. **短信通道与短链跳转**

第 2～5 项要等后端灌真数据后联调确认。

## 请评审确认

**支付模块是否需要显示签名。** 需求文档「支付信息」一栏写的是「支付状态、支付时间、银行卡、支付金额、**签字**」，
但前期口径评审结论是：签名和 AID 属于商户联（Merchant Copy）能力，顾客侧短信 H5 不展示。

当前实现按**前期口径**做的，只用 `tradeInfo` 渲染多支付行，没有签名。两个说法需要产品拍板，
如果确认要签名，我再补一版。
