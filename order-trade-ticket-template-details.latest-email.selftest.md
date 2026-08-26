# FTL 自测报告 · order-trade-ticket-template-details.ftl

> 数据：`demo-latest-email.json`
> 生成：2026/8/26 10:47:17
> 工具：ftl-selftest（静态分析 + 逐数据行推演，非 FreeMarker 引擎渲染）

## 结论

**通过** — 错误 0 项，告警 0 项。

顶层分区覆盖 8/15（53%）：本次数据未走到 5 个，2 个判不了。

循环内分支 20 个，其中 0 个在本次数据里真假两侧都出现过。

## 一、问题清单

未发现问题。

## 二、顶层分区用例矩阵

这些分支决定「哪些区块整块显示或隐藏」，是最需要造数据覆盖的部分。

| 行号 | 所属分区 | 条件 | 本次命中 | 待补用例 |
|------|----------|------|----------|----------|
| 281 | 仍是对象时不再下钻，宁可留空也不能把对象自身打到页面… | `orderInfo??` | 真 | 补一组让条件为假的数据 |
| 295 | 仍是对象时不再下钻，宁可留空也不能把对象自身打到页面… | `orderAmountInfo?? && orderAmountInfo.contentList??` | 真 | 补一组让条件为假的数据 |
| 309 | 仍是对象时不再下钻，宁可留空也不能把对象自身打到页面… | `ticketConfig?? && ticketConfig.merchant?? && ticketC…` | 假 | 补一组让条件为真的数据 |
| 313 | 仍是对象时不再下钻，宁可留空也不能把对象自身打到页面… | `ticketConfig?? && ticketConfig.meal?? && ticketConfi…` | 假 | 补一组让条件为真的数据 |
| 317 | 仍是对象时不再下钻，宁可留空也不能把对象自身打到页面… | `ticketConfig?? && ticketConfig.expense?? && ticketCo…` | 假 | 补一组让条件为真的数据 |
| 324 | 1. 页头：门店信息，独立浅紫底通栏 | `showMerchant && merchantInfo?? && merchantInfo.conte…` | 真 | 补一组让条件为假的数据 |
| 326 | 1. 页头：门店信息，独立浅紫底通栏 | `merchantInfo.logo?? && merchantInfo.logo?has_content` | 假 | 补一组让条件为真的数据 |
| 356 | 2.1 单头：单号 / 类型胶囊 | `orderInfo??` | 真 | 补一组让条件为假的数据 |
| 364 | 2.1 单头：单号 / 类型胶囊 | `orderBadgeText?has_content` | 判不了 | 需人工确认 |
| 380 | 2.1 单头：单号 / 类型胶囊 | `serverLabelText?has_content` | 判不了 | 需人工确认 |
| 397 | 2.2 顾客信息：有则显示 | `customerInfo?? && customerInfo.contentList?? && cust…` | 真 | 补一组让条件为假的数据 |
| 417 | 2.3 餐品信息 | `showMeal && mealInfo?? && mealInfo.contentList?? && …` | 真 | 补一组让条件为假的数据 |
| 580 | 整单备注 | `orderNoteInfo?? && orderNoteInfo.contentList?? && or…` | 假 | 补一组让条件为真的数据 |
| 598 | 2.4 金额信息 | `showExpense && orderAmountInfo?? && orderAmountInfo.…` | 真 | 补一组让条件为假的数据 |
| 654 | 2.5 支付信息：无数据整块不渲染 | `showPayment` | 真 | 补一组让条件为假的数据 |

## 三、循环内分支（逐数据行统计）

每一行统计的是「该条件在实际数据的每一条记录上分别取什么值」。

| 行号 | 所属分区 | 条件 | 数据行分布 | 覆盖情况 |
|------|----------|------|------------|----------|
| 298 | 仍是对象时不再下钻，宁可留空也不能把对象自身打到页面… | `taxSummaryRowIndex lt 0 && amountItem.id?? && amount…` | 5 行中 0 真 / 4 假 / 1 判不了 | 1 行判不了，需人工确认 |
| 336 | 1. 页头：门店信息，独立浅紫底通栏 | `merchantLine?has_content` | 3 行中 3 真 / 0 假 | 当前数据全部走进，需补反例 |
| 401 | 2.2 顾客信息：有则显示 | `customerLine?has_content` | 1 行中 1 真 / 0 假 | 当前数据全部走进，需补反例 |
| 424 | 2.3 餐品信息 | `contentSize == 1` | 3 行中 0 真 / 3 假 | 当前数据从未走进，需补数据 |
| 430 | 2.3 餐品信息 | `isDeleted` | 3 行中 0 真 / 3 假 | 当前数据从未走进，需补数据 |
| 440 | 2.3 餐品信息 | `contentSize == 2` | 3 行中 0 真 / 3 假 | 当前数据从未走进，需补数据 |
| 446 | 2.3 餐品信息 | `isDeleted` | 3 行中 0 真 / 3 假 | 当前数据从未走进，需补数据 |
| 453 | 2.3 餐品信息 | `isDeleted` | 3 行中 0 真 / 3 假 | 当前数据从未走进，需补数据 |
| 469 | 2.3 餐品信息 | `isDeleted` | 3 行中 0 真 / 3 假 | 当前数据从未走进，需补数据 |
| 476 | 2.3 餐品信息 | `isDeleted` | 3 行中 0 真 / 3 假 | 当前数据从未走进，需补数据 |
| 483 | 2.3 餐品信息 | `isDeleted` | 3 行中 0 真 / 3 假 | 当前数据从未走进，需补数据 |
| 496 | 加料 / 备注 | `mealItem.child?? && mealItem.child?size gt 0` | 3 行中 0 真 / 3 假 | 当前数据从未走进，需补数据 |
| 502 | 加料 / 备注 | `contentSize gte 3` | 无数据行 | 外层循环在本次数据里就是空的，整段没测到 |
| 508 | 加料 / 备注 | `modifierItem.content?size gte 2` | 无数据行 | 外层循环在本次数据里就是空的，整段没测到 |
| 517 | 加料 / 备注 | `modifierItem.content?size gte 3` | 无数据行 | 外层循环在本次数据里就是空的，整段没测到 |
| 525 | 加料 / 备注 | `modifierItem.content?size gte 2` | 无数据行 | 外层循环在本次数据里就是空的，整段没测到 |
| 534 | 加料 / 备注 | `modifierItem.content?size gte 3` | 无数据行 | 外层循环在本次数据里就是空的，整段没测到 |
| 548 | 单品折扣 | `mealItem.remarkChild?? && mealItem.remarkChild?size …` | 3 行中 0 真 / 3 假 | 当前数据从未走进，需补数据 |
| 554 | 单品折扣 | `contentSize gte 3` | 无数据行 | 外层循环在本次数据里就是空的，整段没测到 |
| 614 | 2.4 金额信息 | `showDetailIcon` | 5 行中 0 真 / 1 假 / 4 判不了 | 4 行判不了，需人工确认 |

## 四、函数内分支（由入参决定，静态判不了）

| 行号 | 条件 |
|------|------|
| 135 | `!rawWeight?? || !rawWeight?is_number` |
| 138 | `rawWeight lt 100` |
| 141 | `rawWeight gt 900` |
| 155 | `!rawText?? || !rawText?is_string` |
| 159 | `!trimmedText?has_content` |
| 162 | `!trimmedText?matches(r"[0-9 ()+.\-]+")` |
| 170 | `!rawText?? || !rawText?is_string` |
| 174 | `digitsText?length != 10` |
| 182 | `!contentValue??` |
| 186 | `contentValue?is_hash` |
| 189 | `contentValue?is_string` |
| 192 | `contentValue?is_number` |
| 202 | `!field??` |
| 205 | `field?is_hash` |
| 206 | `field.content??` |
| 208 | `contentField?is_string` |
| 211 | `contentField?is_enumerable` |
| 213 | `contentList?size gt 0` |
| 231 | `(!hasTableFlag) && isOnlineOrder && confirmText?has_content` |
| 232 | `diningText?has_content` |
| 243 | `!serverText?has_content` |
| 247 | `serverLower?starts_with("server")` |
| 257 | `mealInfo.contentList?has_content` |
| 259 | `item.content?? && item.content?size gt 0` |
| 263 | `currentLength gt maxLength` |
| 266 | `currentFontSize gt fontSize` |

## 五、字段对账

**模版引用了、但 JSON 顶层没有的字段：**

- `orderNoteInfo` — 后端若不下发，相关分支恒为假，需确认是否符合预期
- `r` — 后端若不下发，相关分支恒为假，需确认是否符合预期

**JSON 里有、但模版没用到的字段：**

无。

## 六、本报告测不到的部分

以下必须人工或真机验证：

- 真实 FreeMarker 引擎的渲染结果（本工具只做静态推演）
- 视觉样式：断行、对齐、溢出、弹层位置
- 邮件客户端兼容性（Outlook / Gmail 会改写或剥离 CSS）
- 短信通道与短链跳转
- 业务口径是否符合产品预期
