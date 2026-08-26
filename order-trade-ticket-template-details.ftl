<!DOCTYPE html>
<html lang="en" style="max-width: 430px;padding: 0;margin: 0 auto">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"/>
    <title>Order Receipt</title>
    <style>
        .w-100-f {
            width: 100%;
        }
        .w-70-f {
            width: 70%;
        }
        .w-50-f {
            width: 50%;
        }
        .w-40-f {
            width: 40%;
        }
        .w-30-f {
            width: 30%;
        }
        .w-20-f {
            width: 20%;
        }
        .line-box {
            width: 100%;
            padding: 0;
        }
        .line {
            border-top: 1px dashed #c8c8c8;
        }
        .word-break {
            word-break: break-word;
        }
        /* 订单类型胶囊：宽度随文字，避免被全局 div 规则撑满 */
        .order-badge {
            display: inline-block;
            width: auto;
            max-width: 100%;
            border: 1.5px solid #111111;
            border-radius: 8px;
            padding: 6px 12px;
            font-weight: 600;
            text-align: center;
            white-space: nowrap;
            box-sizing: border-box;
        }
        .info-icon {
            display: inline-block;
            width: 14px;
            height: 14px;
            border-radius: 50%;
            border: 1px solid #888888;
            color: #666666;
            font-size: 10px;
            line-height: 14px;
            text-align: center;
            cursor: pointer;
            user-select: none;
            margin-left: 4px;
            vertical-align: middle;
        }
        /* 页头：浅紫底，通栏铺满 */
        .page-header {
            width: 100%;
            background-color: #f5f3ff;
            padding: 20px 16px;
            box-sizing: border-box;
        }
        /* 白卡外层：左右各留一条浅紫边距，露出页面底色 */
        .card-wrap {
            width: 100%;
            padding: 0 6px 6px;
            box-sizing: border-box;
        }
        /* 白卡主体：单头往下的全部内容 */
        .ticket-card {
            width: 100%;
            background-color: #ffffff;
            padding: 16px;
            box-sizing: border-box;
        }
        .store-logo {
            width: 56px;
            height: 56px;
            border-radius: 50%;
            object-fit: cover;
            background: #6f3cff;
        }
        /* 热敏旧模版常用 div{width:99%}，H5 会把胶囊撑成整行，这里改为默认自适应 */
        div {
            width: auto;
            max-width: 100%;
        }
        .w-100-f,
        .line-box,
        .line,
        .card-wrap {
            width: 100%;
        }
        /* 邮件版使用原生 details 折叠税费明细，不依赖任何脚本 */
        .tax-fee-details {
            width: 100%;
        }
        .tax-fee-summary {
            cursor: pointer;
            list-style: none;
        }
        .tax-fee-summary::-webkit-details-marker {
            display: none;
        }
        .tax-fee-detail-list {
            margin: 4px 0 6px;
            padding: 6px 0 2px 16px;
            border-left: 2px solid #e2dcff;
        }
        .tax-fee-detail-row {
            font-size: 0;
            line-height: 22px;
        }
    </style>
</head>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;margin:0;padding:0;color:#111111;background-color:#ffffff;">

<#-- 行高计算，与旧小票模版保持一致 -->
<#function setLineSpacing fontSize lineSpace>
    <#assign space = (fontSize * (lineSpace / 6 + 1))?string["0.00"]>
    <#return space>
</#function>

<#-- 后端存在下发 bold:0 的情况，CSS font-weight:0 是非法值会被浏览器整条丢弃，
     这里统一规整到合法区间 -->
<#function normalizeFontWeight rawWeight>
    <#if !rawWeight?? || !rawWeight?is_number>
        <#return 400>
    </#if>
    <#if rawWeight lt 100>
        <#return 400>
    </#if>
    <#if rawWeight gt 900>
        <#return 900>
    </#if>
    <#return rawWeight?round>
</#function>

<#-- 只保留数字，用于门店电话的识别与格式化 -->
<#function keepDigitsOnly rawText>
    <#return rawText?replace(r"[^0-9]", "", "r")>
</#function>

<#-- 判断门店信息里的某一行是否为电话：整行只由数字与电话常见分隔符组成，且恰好 10 位数字，
     这样店名、地址这类含字母的行不会被误判。非字符串一律不当电话处理，避免正则匹配报错 -->
<#function isStorePhoneLine rawText>
    <#if !rawText?? || !rawText?is_string>
        <#return false>
    </#if>
    <#local trimmedText = rawText?trim>
    <#if !trimmedText?has_content>
        <#return false>
    </#if>
    <#if !trimmedText?matches(r"[0-9 ()+.\-]+")>
        <#return false>
    </#if>
    <#return keepDigitsOnly(trimmedText)?length == 10>
</#function>

<#-- 门店电话统一格式化成 3-3-4，位数不符则原样返回 -->
<#function formatStorePhone rawText>
    <#if !rawText?? || !rawText?is_string>
        <#return rawText>
    </#if>
    <#local digitsText = keepDigitsOnly(rawText)>
    <#if digitsText?length != 10>
        <#return rawText>
    </#if>
    <#return digitsText?substring(0, 3) + "-" + digitsText?substring(3, 6) + "-" + digitsText?substring(6, 10)>
</#function>

<#-- 取 content 数组里的单个元素：正常是字符串，做一层类型兜底 -->
<#function readContentValue contentValue>
    <#if !contentValue??>
        <#return "">
    </#if>
    <#-- 仍是对象时不再下钻，宁可留空也不能把对象自身打到页面上 -->
    <#if contentValue?is_hash>
        <#return "">
    </#if>
    <#if contentValue?is_string>
        <#return contentValue>
    </#if>
    <#if contentValue?is_number>
        <#return contentValue?c>
    </#if>
    <#return "">
</#function>

<#-- 读取字段文案：兼容纯字符串、{ content: [] } 结构、后端 Content 对象
     注意：后端 Content 对象经 FreeMarker 对象包装后 ?is_string 同样为真（取到的是 toString 结果），
     所以必须先按 hash 取 content，最后才回退成字符串，否则页面会出现 Content(contentType=0,...) -->
<#function readText field>
    <#if !field??>
        <#return "">
    </#if>
    <#if field?is_hash>
        <#if field.content??>
            <#local contentField = field.content>
            <#if contentField?is_string>
                <#return contentField>
            </#if>
            <#if contentField?is_enumerable>
                <#local contentList = contentField?sequence>
                <#if contentList?size gt 0>
                    <#return readContentValue(contentList[0])>
                </#if>
            </#if>
        </#if>
        <#return "">
    </#if>
    <#return readContentValue(field)>
</#function>

<#-- 组装右侧胶囊：有桌台只显示类型；OO 无桌台有取餐码则类型 / 取餐码 -->
<#function buildOrderBadge orderInfo>
    <#assign diningText = readText(orderInfo.diningOption!'')>
    <#assign tableText = readText(orderInfo.table!'')>
    <#assign confirmText = readText(orderInfo.confirmationNumber!'')>
    <#assign channelValue = orderInfo.orderChannel!0>
    <#assign hasTableFlag = tableText?has_content>
    <#assign isOnlineOrder = (channelValue?string == "1") || (channelValue?is_number && channelValue == 1)>
    <#if (!hasTableFlag) && isOnlineOrder && confirmText?has_content>
        <#if diningText?has_content>
            <#return diningText + " / " + confirmText>
        </#if>
        <#return confirmText>
    </#if>
    <#return diningText>
</#function>

<#-- Server 文案：后端若已带 Server: 前缀则不再重复拼接 -->
<#function buildServerLabel serverField>
    <#assign serverText = readText(serverField)>
    <#if !serverText?has_content>
        <#return "">
    </#if>
    <#assign serverLower = serverText?lower_case>
    <#if serverLower?starts_with("server")>
        <#return serverText>
    </#if>
    <#return "Server: " + serverText>
</#function>

<#-- 计算菜品数量列宽 -->
<#function orderQuantityColumnWidth mealInfo>
    <#assign maxLength = 0>
    <#assign fontSize = 0>
    <#if mealInfo.contentList?has_content>
        <#list mealInfo.contentList as item>
            <#if item.content?? && item.content?size gt 0>
                <#assign firstContent = item.content[0]!''>
                <#assign currentLength = firstContent?trim?length>
                <#assign currentFontSize = item.fontSize?number!0>
                <#if currentLength gt maxLength>
                    <#assign maxLength = currentLength>
                </#if>
                <#if currentFontSize gt fontSize>
                    <#assign fontSize = currentFontSize>
                </#if>
            </#if>
        </#list>
    </#if>
    <#assign maxFontSize = fontSize * maxLength>
    <#assign maxFontSize = maxFontSize * (maxLength > 1)?then((maxLength > 4)?then(0.8, 0.7), 1)>
    <#return (maxFontSize > 120)?then(120, maxFontSize?round)>
</#function>

<#assign orderBadgeText = "">
<#assign orderNumberText = "">
<#assign orderTimeText = "">
<#assign serverLabelText = "">
<#if orderInfo??>
    <#assign orderBadgeText = buildOrderBadge(orderInfo)>
    <#-- 统一走 readText：orderNumber 可能是字符串、{content:[]} 或后端 Content 对象 -->
    <#assign orderNumberText = readText(orderInfo.orderNumber!'')>
    <#assign orderTimeText = readText(orderInfo.orderTime!'')>
    <#assign serverLabelText = buildServerLabel(orderInfo.server!'')>
</#if>

<#-- 折叠区严格展示客户端下发的明细，模版不识别或过滤费用类型 -->
<#assign taxFeeVisibleItems = (taxFeeDetailInfo.contentList)![]>
<#assign showTaxFeeDetails = taxFeeVisibleItems?size gt 0>

<#-- 客户端通过固定 id 标识税费汇总行，模版不再根据字段或文案猜测 -->
<#assign taxSummaryRowIndex = -1>
<#if orderAmountInfo?? && orderAmountInfo.contentList??>
    <#assign amountScanCursor = 0>
    <#list orderAmountInfo.contentList as amountItem>
        <#if taxSummaryRowIndex lt 0
            && amountItem.id?? && amountItem.id?is_string
            && amountItem.id == "taxFees">
            <#assign taxSummaryRowIndex = amountScanCursor>
        </#if>
        <#assign amountScanCursor = amountScanCursor + 1>
    </#list>
</#if>
<#assign showPayment = tradeInfo?? && tradeInfo.contentList?? && tradeInfo.contentList?size gt 0>

<#assign showMerchant = true>
<#if ticketConfig?? && ticketConfig.merchant?? && ticketConfig.merchant.showPart?? && !ticketConfig.merchant.showPart>
    <#assign showMerchant = false>
</#if>
<#assign showMeal = true>
<#if ticketConfig?? && ticketConfig.meal?? && ticketConfig.meal.showPart?? && !ticketConfig.meal.showPart>
    <#assign showMeal = false>
</#if>
<#assign showExpense = true>
<#if ticketConfig?? && ticketConfig.expense?? && ticketConfig.expense.showPart?? && !ticketConfig.expense.showPart>
    <#assign showExpense = false>
</#if>

<div style="max-width:430px;margin:0 auto;background-color:#f5f3ff;" class="w-100-f">

    <#-- 1. 页头：门店信息，独立浅紫底通栏 -->
    <#if showMerchant && merchantInfo?? && merchantInfo.contentList?? && merchantInfo.contentList?size gt 0>
        <table class="page-header" role="presentation" border="0" cellpadding="0" cellspacing="0">
            <#if merchantInfo.logo?? && merchantInfo.logo?has_content>
                <tr>
                    <td colspan="12" style="padding-bottom:8px;" align="center">
                        <img class="store-logo" src="${merchantInfo.logo}" alt="store logo"/>
                    </td>
                </tr>
            </#if>
            <#assign merchantLineSpace = (merchantInfo.block.lineSpace)!4>
            <#list merchantInfo.contentList as merchantItem>
                <#assign merchantLine = merchantItem.content[0]!"">
                <#if merchantLine?has_content>
                    <#-- 电话行按设计稿统一显示为 3-3-4 且加粗，其余行沿用后端下发的字重 -->
                    <#assign isPhoneLine = isStorePhoneLine(merchantLine)>
                    <#assign merchantText = isPhoneLine?then(formatStorePhone(merchantLine), merchantLine)>
                    <#assign merchantBold = isPhoneLine?then(700, normalizeFontWeight(merchantItem.bold!400))>
                    <tr style="line-height:${setLineSpacing(merchantItem.fontSize!14, merchantLineSpace)}px;">
                        <td style="font-size:${merchantItem.fontSize!14}px;font-weight:${merchantBold};word-break:break-word;" colspan="12" align="center">
                            <div>${merchantText}</div>
                        </td>
                    </tr>
                </#if>
            </#list>
        </table>
    </#if>

    <#-- 2. 主体白卡：左右各留一条浅紫边距 -->
    <div class="card-wrap">
    <table class="ticket-card" style="overflow:hidden;" role="presentation" border="0" cellpadding="0" cellspacing="0">

        <#-- 2.1 单头：单号 / 类型胶囊 -->
        <#if orderInfo??>
            <tr>
                <td colspan="12" style="padding:0;">
                    <table class="w-100-f" role="presentation" border="0" cellpadding="0" cellspacing="0">
                        <tr>
                            <td class="w-50-f" style="font-size:28px;font-weight:700;word-break:break-word;" valign="top" align="left">
                                <div>${orderNumberText}</div>
                            </td>
                            <#if orderBadgeText?has_content>
                                <td class="w-50-f" valign="middle" align="right" style="padding-left:8px;">
                                    <div class="order-badge" style="font-size:14px;">${orderBadgeText}</div>
                                </td>
                            </#if>
                        </tr>
                    </table>
                </td>
            </tr>
            <tr>
                <td colspan="12" style="padding:0;">
                    <table class="w-100-f" role="presentation" border="0" cellpadding="0" cellspacing="0">
                        <tr>
                            <td class="w-50-f" style="font-size:13px;color:#333333;padding-top:8px;" valign="top" align="left">
                                <div>${orderTimeText}</div>
                            </td>
                            <#if serverLabelText?has_content>
                                <td class="w-50-f" style="font-size:13px;color:#333333;padding-top:8px;" valign="top" align="right">
                                    <div>${serverLabelText}</div>
                                </td>
                            </#if>
                        </tr>
                    </table>
                </td>
            </tr>
            <tr>
                <td class="w-100-f line-box" style="height:28px;" valign="center" colspan="12">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>

        <#-- 2.2 顾客信息：有则显示 -->
        <#if customerInfo?? && customerInfo.contentList?? && customerInfo.contentList?size gt 0>
            <#assign customerLineSpace = (customerInfo.block.lineSpace)!4>
            <#list customerInfo.contentList as customerItem>
                <#assign customerLine = customerItem.content[0]!"">
                <#if customerLine?has_content>
                    <tr style="line-height:${setLineSpacing(customerItem.fontSize!14, customerLineSpace)}px;">
                        <td style="font-size:${customerItem.fontSize!14}px;font-weight:${normalizeFontWeight(customerItem.bold!400)};word-break:break-word;" colspan="12" align="center">
                            <div>${customerLine}</div>
                        </td>
                    </tr>
                </#if>
            </#list>
            <tr>
                <td class="w-100-f line-box" style="height:28px;" valign="center" colspan="12">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>

        <#-- 2.3 餐品信息 -->
        <#if showMeal && mealInfo?? && mealInfo.contentList?? && mealInfo.contentList?size gt 0>
            <#assign mealLineSpace = (mealInfo.block.lineSpace)!4>
            <#assign qtyWidth = orderQuantityColumnWidth(mealInfo)>
            <#list mealInfo.contentList as mealItem>
                <#assign contentSize = mealItem.content?size>
                <#assign isDeleted = mealItem.contentType?? && mealItem.contentType == 101>

                <#if contentSize == 1>
                    <tr>
                        <td colspan="12">
                            <table class="w-100-f" role="presentation" border="0" cellpadding="0" cellspacing="0">
                                <tr style="line-height:${setLineSpacing(mealItem.fontSize!14, mealLineSpace)}px;">
                                    <td style="font-size:${mealItem.fontSize!14}px;font-weight:${normalizeFontWeight(mealItem.bold!700)};" align="left">
                                        <#if isDeleted>
                                            <del class="word-break">${mealItem.content[0]}</del>
                                        <#else>
                                            <div class="word-break">${mealItem.content[0]}</div>
                                        </#if>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                <#elseif contentSize == 2>
                    <tr>
                        <td colspan="12">
                            <table class="w-100-f" role="presentation" border="0" cellpadding="0" cellspacing="0">
                                <tr style="line-height:${setLineSpacing(mealItem.fontSize!14, mealLineSpace)}px;">
                                    <td style="width:70%;font-size:${mealItem.fontSize!14}px;font-weight:${normalizeFontWeight(mealItem.bold!700)};" align="left" valign="top">
                                        <#if isDeleted>
                                            <del class="word-break">${mealItem.content[0]}</del>
                                        <#else>
                                            <div class="word-break">${mealItem.content[0]}</div>
                                        </#if>
                                    </td>
                                    <td style="width:30%;font-size:${mealItem.fontSize!14}px;font-weight:${normalizeFontWeight(mealItem.bold!700)};" align="right" valign="top">
                                        <#if isDeleted>
                                            <del class="word-break">${mealItem.content[1]}</del>
                                        <#else>
                                            <div class="word-break">${mealItem.content[1]}</div>
                                        </#if>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                <#else>
                    <tr>
                        <td colspan="12">
                            <table class="w-100-f" role="presentation" border="0" cellpadding="0" cellspacing="0">
                                <tr style="line-height:${setLineSpacing(mealItem.fontSize!14, mealLineSpace)}px;">
                                    <td style="width:${qtyWidth}px;font-size:${mealItem.fontSize!14}px;font-weight:${normalizeFontWeight(mealItem.bold!700)};" align="left" valign="top">
                                        <#if isDeleted>
                                            <del class="word-break">${mealItem.content[0]}</del>
                                        <#else>
                                            <div class="word-break">${mealItem.content[0]}</div>
                                        </#if>
                                    </td>
                                    <td style="width:calc(100% - ${qtyWidth}px - 80px);font-size:${mealItem.fontSize!14}px;font-weight:${normalizeFontWeight(mealItem.bold!700)};" align="left" valign="top">
                                        <#if isDeleted>
                                            <del class="word-break">${mealItem.content[1]}</del>
                                        <#else>
                                            <div class="word-break">${mealItem.content[1]}</div>
                                        </#if>
                                    </td>
                                    <td style="width:80px;font-size:${mealItem.fontSize!14}px;font-weight:${normalizeFontWeight(mealItem.bold!700)};" align="right" valign="top">
                                        <#if isDeleted>
                                            <del class="word-break">${mealItem.content[2]!""}</del>
                                        <#else>
                                            <div class="word-break">${mealItem.content[2]!""}</div>
                                        </#if>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </#if>

                <#-- 加料 / 备注 -->
                <#if mealItem.child?? && mealItem.child?size gt 0>
                    <#list mealItem.child as modifierItem>
                        <tr>
                            <td colspan="12">
                                <table class="w-100-f" role="presentation" border="0" cellpadding="0" cellspacing="0">
                                    <tr style="line-height:${setLineSpacing(modifierItem.fontSize!12, mealLineSpace)}px;">
                                        <#if contentSize gte 3>
                                            <td style="width:${qtyWidth}px;" align="left" valign="top">
                                                <div></div>
                                            </td>
                                            <td style="width:calc(100% - ${qtyWidth}px - 80px);font-size:${modifierItem.fontSize!12}px;font-weight:${normalizeFontWeight(modifierItem.bold!400)};color:#555555;" align="left" valign="top">
                                                <div class="word-break">
                                                    <#if modifierItem.content?size gte 2>
                                                        ${modifierItem.content[1]!""}
                                                    <#else>
                                                        ${modifierItem.content[0]!""}
                                                    </#if>
                                                </div>
                                            </td>
                                            <td style="width:80px;font-size:${modifierItem.fontSize!12}px;font-weight:${normalizeFontWeight(modifierItem.bold!400)};color:#555555;" align="right" valign="top">
                                                <div class="word-break">
                                                    <#if modifierItem.content?size gte 3>
                                                        ${modifierItem.content[2]!""}
                                                    </#if>
                                                </div>
                                            </td>
                                        <#else>
                                            <td style="width:70%;font-size:${modifierItem.fontSize!12}px;font-weight:${normalizeFontWeight(modifierItem.bold!400)};color:#555555;" align="left" valign="top">
                                                <div class="word-break">
                                                    <#if modifierItem.content?size gte 2>
                                                        ${modifierItem.content[1]!modifierItem.content[0]!""}
                                                    <#else>
                                                        ${modifierItem.content[0]!""}
                                                    </#if>
                                                </div>
                                            </td>
                                            <td style="width:30%;font-size:${modifierItem.fontSize!12}px;font-weight:${normalizeFontWeight(modifierItem.bold!400)};color:#555555;" align="right" valign="top">
                                                <div class="word-break">
                                                    <#if modifierItem.content?size gte 3>
                                                        ${modifierItem.content[2]!""}
                                                    </#if>
                                                </div>
                                            </td>
                                        </#if>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </#list>
                </#if>

                <#-- 单品折扣 -->
                <#if mealItem.remarkChild?? && mealItem.remarkChild?size gt 0>
                    <#list mealItem.remarkChild as remarkItem>
                        <tr>
                            <td colspan="12">
                                <table class="w-100-f" role="presentation" border="0" cellpadding="0" cellspacing="0">
                                    <tr style="line-height:${setLineSpacing(remarkItem.fontSize!12, mealLineSpace)}px;">
                                        <#if contentSize gte 3>
                                            <td style="width:${qtyWidth}px;" align="left" valign="top"><div></div></td>
                                            <td style="width:calc(100% - ${qtyWidth}px - 80px);font-size:${remarkItem.fontSize!12}px;font-weight:${normalizeFontWeight(remarkItem.bold!400)};color:#555555;" align="left" valign="top">
                                                <div class="word-break">${remarkItem.content[1]!remarkItem.content[0]!""}</div>
                                            </td>
                                            <td style="width:80px;font-size:${remarkItem.fontSize!12}px;font-weight:${normalizeFontWeight(remarkItem.bold!400)};color:#555555;" align="right" valign="top">
                                                <div class="word-break">${remarkItem.content[2]!""}</div>
                                            </td>
                                        <#else>
                                            <td style="width:70%;font-size:${remarkItem.fontSize!12}px;font-weight:${normalizeFontWeight(remarkItem.bold!400)};color:#555555;" align="left" valign="top">
                                                <div class="word-break">${remarkItem.content[1]!remarkItem.content[0]!""}</div>
                                            </td>
                                            <td style="width:30%;font-size:${remarkItem.fontSize!12}px;font-weight:${normalizeFontWeight(remarkItem.bold!400)};color:#555555;" align="right" valign="top">
                                                <div class="word-break">${remarkItem.content[2]!""}</div>
                                            </td>
                                        </#if>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </#list>
                </#if>
            </#list>
        </#if>

        <#-- 整单备注 -->
        <#if orderNoteInfo?? && orderNoteInfo.contentList?? && orderNoteInfo.contentList?size gt 0>
            <#assign noteLineSpace = (orderNoteInfo.block.lineSpace)!4>
            <#list orderNoteInfo.contentList as noteItem>
                <tr style="line-height:${setLineSpacing(noteItem.fontSize!13, noteLineSpace)}px;">
                    <td style="font-size:${noteItem.fontSize!13}px;font-weight:${normalizeFontWeight(noteItem.bold!400)};" colspan="12" align="left">
                        <div class="word-break">${noteItem.content[0]!""}</div>
                    </td>
                </tr>
            </#list>
        </#if>

        <tr>
            <td class="w-100-f line-box" style="height:28px;" valign="center" colspan="12">
                <div class="line"></div>
            </td>
        </tr>

        <#-- 2.4 金额信息 -->
        <#if showExpense && orderAmountInfo?? && orderAmountInfo.contentList?? && orderAmountInfo.contentList?size gt 0>
            <#assign amountLineSpace = (orderAmountInfo.block.lineSpace)!4>
            <#assign amountRowCursor = 0>
            <#list orderAmountInfo.contentList as amountItem>
                <#assign amountLabel = amountItem.content[0]!"">
                <#assign amountValue = amountItem.content[1]!"">
                <#-- 客户端通过固定 id 标识总计行，避免模版依赖展示文案 -->
                <#assign isTotalRow = amountItem.id?? && amountItem.id?is_string && amountItem.id == "total">
                <#-- 仅 id=taxFees 的汇总行显示明细图标 -->
                <#assign showDetailIcon = showTaxFeeDetails && (!isTotalRow) && (amountRowCursor == taxSummaryRowIndex)>
                <#assign amountRowCursor = amountRowCursor + 1>
                <#-- 设计稿：普通行左侧常规、右侧金额加粗；Total 行左侧 15px 加粗、右侧 22px 加粗 -->
                <#assign amountLabelFontSize = isTotalRow?then(15, amountItem.fontSize!14)>
                <#assign amountValueFontSize = isTotalRow?then(22, amountItem.fontSize!14)>
                <#assign amountLabelBold = isTotalRow?then(700, normalizeFontWeight(amountItem.bold!400))>
                <#assign amountRowValign = isTotalRow?then("bottom", "top")>
                <#if showDetailIcon>
                    <#-- 关键逻辑：summary 只放行内元素，点击整行即可原生展开，不使用 script -->
                    <tr>
                        <td colspan="12">
                            <details class="tax-fee-details">
                                <summary class="tax-fee-summary" style="line-height:${setLineSpacing(amountValueFontSize, amountLineSpace)}px;">
                                    <span style="display:inline-block;width:70%;font-size:${amountLabelFontSize}px;font-weight:${amountLabelBold};vertical-align:top;box-sizing:border-box;">
                                        ${amountLabel}<span class="info-icon" aria-hidden="true">i</span>
                                    </span><span style="display:inline-block;width:30%;font-size:${amountValueFontSize}px;font-weight:700;text-align:right;vertical-align:top;box-sizing:border-box;">${amountValue}</span>
                                </summary>
                                <div class="tax-fee-detail-list">
                                    <#list taxFeeVisibleItems as feeItem>
                                        <div class="tax-fee-detail-row">
                                            <span style="display:inline-block;width:70%;font-size:${feeItem.fontSize!13}px;font-weight:${normalizeFontWeight(feeItem.bold!400)};vertical-align:top;box-sizing:border-box;">${feeItem.content[0]!""}</span><span style="display:inline-block;width:30%;font-size:${feeItem.fontSize!13}px;font-weight:${normalizeFontWeight(feeItem.bold!400)};text-align:right;vertical-align:top;box-sizing:border-box;">${feeItem.content[1]!""}</span>
                                        </div>
                                    </#list>
                                </div>
                            </details>
                        </td>
                    </tr>
                <#else>
                    <tr>
                        <td colspan="12">
                            <table class="w-100-f" role="presentation" border="0" cellpadding="0" cellspacing="0">
                                <tr style="line-height:${setLineSpacing(amountValueFontSize, amountLineSpace)}px;">
                                    <td style="width:70%;font-size:${amountLabelFontSize}px;font-weight:${amountLabelBold};" align="left" valign="${amountRowValign}">
                                        <div>${amountLabel}</div>
                                    </td>
                                    <td style="width:30%;font-size:${amountValueFontSize}px;font-weight:700;" align="right" valign="${amountRowValign}">
                                        <div>${amountValue}</div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </#if>
            </#list>
        </#if>

        <#-- 2.5 支付信息：无数据整块不渲染 -->
        <#if showPayment>
            <tr>
                <td class="w-100-f line-box" style="height:28px;" valign="center" colspan="12">
                    <div class="line"></div>
                </td>
            </tr>
            <tr>
                <td colspan="12" style="font-size:15px;font-weight:700;padding-bottom:8px;" align="left">
                    <div>Payment</div>
                </td>
            </tr>
            <#assign tradeLineSpace = (tradeInfo.block.lineSpace)!4>
            <#list tradeInfo.contentList as payItem>
                <tr>
                    <td colspan="12">
                        <table class="w-100-f" role="presentation" border="0" cellpadding="0" cellspacing="0">
                            <tr style="line-height:${setLineSpacing(payItem.fontSize!14, tradeLineSpace)}px;">
                                <td style="width:70%;font-size:${payItem.fontSize!14}px;font-weight:${normalizeFontWeight(payItem.bold!400)};" align="left" valign="top">
                                    <div class="word-break">${payItem.content[0]!""}</div>
                                </td>
                                <td style="width:30%;font-size:${payItem.fontSize!14}px;font-weight:${normalizeFontWeight(payItem.bold!400)};" align="right" valign="top">
                                    <div>${payItem.content[1]!""}</div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#list>
            <#-- 设计稿在支付区下方还有一条收尾虚线 -->
            <tr>
                <td class="w-100-f line-box" style="height:28px;" valign="center" colspan="12">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>

        <tr>
            <td colspan="12" style="height:8px;"></td>
        </tr>
    </table>
    </div>
</div>

</body>
</html>
