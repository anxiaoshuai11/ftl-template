# FTL 自测报告 · order-trade-ticket-template.ftl

> 数据：`demo-merged-ticket.json`
> 生成：2026/8/24 15:15:20
> 工具：ftl-selftest（静态分析 + 逐数据行推演，非 FreeMarker 引擎渲染）

## 结论

**通过** — 错误 0 项，告警 0 项。

顶层分区覆盖 10/18（56%）：本次数据未走到 6 个，2 个判不了。

循环内分支 19 个，其中 0 个在本次数据里真假两侧都出现过。

## 一、问题清单

未发现问题。

## 二、顶层分区用例矩阵

这些分支决定「哪些区块整块显示或隐藏」，是最需要造数据覆盖的部分。

| 行号 | 所属分区 | 条件 | 本次命中 | 待补用例 |
|------|----------|------|----------|----------|
| 222 | - | `orderInfo??` | 真 | 补一组让条件为假的数据 |
| 224 | - | `orderInfo.orderNumber?? && orderInfo.orderNumber?is_…` | 假 | 补一组让条件为真的数据 |
| 236 | - | `taxFeeDetailInfo?? && taxFeeDetailInfo.title?? && ta…` | 真 | 补一组让条件为假的数据 |
| 242 | - | `ticketConfig?? && ticketConfig.merchant?? && ticketC…` | 假 | 补一组让条件为真的数据 |
| 246 | - | `ticketConfig?? && ticketConfig.meal?? && ticketConfi…` | 假 | 补一组让条件为真的数据 |
| 250 | - | `ticketConfig?? && ticketConfig.expense?? && ticketCo…` | 假 | 补一组让条件为真的数据 |
| 258 | 1. 页头：门店信息 | `showMerchant && merchantInfo?? && merchantInfo.conte…` | 真 | 补一组让条件为假的数据 |
| 259 | 1. 页头：门店信息 | `merchantInfo.logo?? && merchantInfo.logo?has_content` | 假 | 补一组让条件为真的数据 |
| 265 | 1. 页头：门店信息 | `ticketConfig?? && ticketConfig.merchant?? && ticketC…` | 真 | 补一组让条件为假的数据 |
| 293 | 2. 单头：单号 / 类型胶囊 | `orderInfo??` | 真 | 补一组让条件为假的数据 |
| 301 | 2. 单头：单号 / 类型胶囊 | `orderBadgeText?has_content` | 判不了 | 需人工确认 |
| 317 | 2. 单头：单号 / 类型胶囊 | `serverLabelText?has_content` | 判不了 | 需人工确认 |
| 334 | 3. 顾客信息：有则显示 | `customerInfo?? && customerInfo.contentList?? && cust…` | 真 | 补一组让条件为假的数据 |
| 354 | 4. 餐品信息 | `showMeal && mealInfo?? && mealInfo.contentList?? && …` | 真 | 补一组让条件为假的数据 |
| 517 | 整单备注 | `orderNoteInfo?? && orderNoteInfo.contentList?? && or…` | 假 | 补一组让条件为真的数据 |
| 535 | 5. 金额信息 | `showExpense && orderAmountInfo?? && orderAmountInfo.…` | 真 | 补一组让条件为假的数据 |
| 570 | 6. 支付信息：无数据整块不渲染 | `showPayment` | 真 | 补一组让条件为假的数据 |
| 607 | Tax & Fee 明细弹层：仅有 taxFeeDe… | `showTaxFeeModal` | 真 | 补一组让条件为假的数据 |

## 三、循环内分支（逐数据行统计）

每一行统计的是「该条件在实际数据的每一条记录上分别取什么值」。

| 行号 | 所属分区 | 条件 | 数据行分布 | 覆盖情况 |
|------|----------|------|------------|----------|
| 279 | 1. 页头：门店信息 | `merchantLine?has_content` | 3 行中 3 真 / 0 假 | 当前数据全部走进，需补反例 |
| 338 | 3. 顾客信息：有则显示 | `customerLine?has_content` | 5 行中 5 真 / 0 假 | 当前数据全部走进，需补反例 |
| 361 | 4. 餐品信息 | `contentSize == 1` | 2 行中 0 真 / 2 假 | 当前数据从未走进，需补数据 |
| 367 | 4. 餐品信息 | `isDeleted` | 2 行中 0 真 / 2 假 | 当前数据从未走进，需补数据 |
| 377 | 4. 餐品信息 | `contentSize == 2` | 2 行中 0 真 / 2 假 | 当前数据从未走进，需补数据 |
| 383 | 4. 餐品信息 | `isDeleted` | 2 行中 0 真 / 2 假 | 当前数据从未走进，需补数据 |
| 390 | 4. 餐品信息 | `isDeleted` | 2 行中 0 真 / 2 假 | 当前数据从未走进，需补数据 |
| 406 | 4. 餐品信息 | `isDeleted` | 2 行中 0 真 / 2 假 | 当前数据从未走进，需补数据 |
| 413 | 4. 餐品信息 | `isDeleted` | 2 行中 0 真 / 2 假 | 当前数据从未走进，需补数据 |
| 420 | 4. 餐品信息 | `isDeleted` | 2 行中 0 真 / 2 假 | 当前数据从未走进，需补数据 |
| 433 | 加料 / 备注 | `mealItem.child?? && mealItem.child?size gt 0` | 2 行中 2 真 / 0 假 | 当前数据全部走进，需补反例 |
| 439 | 加料 / 备注 | `contentSize gte 3` | 5 行中 5 真 / 0 假 | 当前数据全部走进，需补反例 |
| 445 | 加料 / 备注 | `modifierItem.content?size gte 2` | 5 行中 5 真 / 0 假 | 当前数据全部走进，需补反例 |
| 454 | 加料 / 备注 | `modifierItem.content?size gte 3` | 5 行中 5 真 / 0 假 | 当前数据全部走进，需补反例 |
| 462 | 加料 / 备注 | `modifierItem.content?size gte 2` | 5 行中 0 真 / 5 假 | 当前数据从未走进，需补数据 |
| 471 | 加料 / 备注 | `modifierItem.content?size gte 3` | 5 行中 0 真 / 5 假 | 当前数据从未走进，需补数据 |
| 485 | 单品折扣 | `mealItem.remarkChild?? && mealItem.remarkChild?size …` | 2 行中 0 真 / 2 假 | 当前数据从未走进，需补数据 |
| 491 | 单品折扣 | `contentSize gte 3` | 无数据行 | 外层循环在本次数据里就是空的，整段没测到 |
| 554 | 5. 金额信息 | `showDetailIcon` | 6 行中 1 真 / 0 假 / 5 判不了 | 5 行判不了，需人工确认 |

## 四、函数内分支（由入参决定，静态判不了）

| 行号 | 条件 |
|------|------|
| 152 | `!field??` |
| 155 | `field?is_string` |
| 158 | `field?is_hash && field.content?? && field.content?size gt 0` |
| 172 | `(!hasTableFlag) && isOnlineOrder && confirmText?has_content` |
| 173 | `diningText?has_content` |
| 184 | `!serverText?has_content` |
| 188 | `serverLower?starts_with("server")` |
| 198 | `mealInfo.contentList?has_content` |
| 200 | `item.content?? && item.content?size gt 0` |
| 204 | `currentLength gt maxLength` |
| 207 | `currentFontSize gt fontSize` |

## 五、字段对账

**模版引用了、但 JSON 顶层没有的字段：**

无。

**JSON 里有、但模版没用到的字段：**

- `transInfo`
- `cardDetail`
- `amountInfo`

## 六、本报告测不到的部分

以下必须人工或真机验证：

- 真实 FreeMarker 引擎的渲染结果（本工具只做静态推演）
- 视觉样式：断行、对齐、溢出、弹层位置
- 邮件客户端兼容性（Outlook / Gmail 会改写或剥离 CSS）
- 短信通道与短链跳转
- 业务口径是否符合产品预期
