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
        .store-logo-fallback {
            width: 56px;
            height: 56px;
            border-radius: 50%;
            margin: 0 auto;
            background: #6f3cff;
            text-align: center;
            line-height: 56px;
        }
        .store-logo-fallback svg {
            width: 28px;
            height: 28px;
            fill: #ffffff;
            vertical-align: middle;
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
        .modal-mask {
            display: none;
            position: fixed;
            left: 0;
            top: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.45);
            z-index: 1000;
        }
        .modal-mask.is-open {
            display: block;
        }
        .modal-panel {
            width: 86%;
            max-width: 340px;
            margin: 20% auto 0;
            background: #ffffff;
            border-radius: 12px;
            padding: 18px 16px 16px;
        }
        .modal-confirm {
            display: block;
            width: 100%;
            margin-top: 18px;
            border: none;
            border-radius: 24px;
            padding: 12px 16px;
            background: #6f3cff;
            color: #ffffff;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
        }
        .modal-close {
            width: 28px;
            height: 28px;
            border: none;
            background: transparent;
            font-size: 22px;
            line-height: 1;
            color: #333333;
            cursor: pointer;
        }
    </style>
</head>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;margin:0;padding:0;color:#111111;background-color:#ffffff;">

<#-- 行高计算，与旧小票模版保持一致 -->
<#function setLineSpacing fontSize lineSpace>
    <#assign space = (fontSize * (lineSpace / 6 + 1))?string["0.00"]>
    <#return space>
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

<#assign showTaxFeeModal = taxFeeDetailInfo?? && taxFeeDetailInfo.contentList?? && taxFeeDetailInfo.contentList?size gt 0>
<#-- 弹层标题：优先用后端下发的 title（Tax / Taxes & Fees / Fees），否则默认 Taxes & Fees -->
<#assign taxFeeModalTitleText = "Taxes & Fees">
<#if taxFeeDetailInfo??>
    <#assign taxFeeTitleFromServer = readText(taxFeeDetailInfo.title!'')>
    <#if taxFeeTitleFromServer?has_content>
        <#assign taxFeeModalTitleText = taxFeeTitleFromServer>
    </#if>
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
            <#elseif ticketConfig?? && ticketConfig.merchant?? && ticketConfig.merchant.logo?? && ticketConfig.merchant.logo>
                <tr>
                    <td colspan="12" style="padding-bottom:8px;" align="center">
                        <div class="store-logo-fallback" aria-hidden="true">
                            <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                <path d="M21 8.5l-1.5-4.2A2 2 0 0017.6 3H6.4a2 2 0 00-1.9 1.3L3 8.5V10a2 2 0 002 2v7a1 1 0 001 1h12a1 1 0 001-1v-7a2 2 0 002-2V8.5zM6.4 5h11.2l1.1 3H5.3L6.4 5zM8 19v-5h8v5H8z"/>
                            </svg>
                        </div>
                    </td>
                </tr>
            </#if>
            <#assign merchantLineSpace = (merchantInfo.block.lineSpace)!4>
            <#list merchantInfo.contentList as merchantItem>
                <#assign merchantLine = merchantItem.content[0]!"">
                <#if merchantLine?has_content>
                    <tr style="line-height:${setLineSpacing(merchantItem.fontSize!14, merchantLineSpace)}px;">
                        <td style="font-size:${merchantItem.fontSize!14}px;font-weight:${merchantItem.bold!400};word-break:break-word;" colspan="12" align="center">
                            <div>${merchantLine}</div>
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
                        <td style="font-size:${customerItem.fontSize!14}px;font-weight:${customerItem.bold!400};word-break:break-word;" colspan="12" align="center">
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
                                    <td style="font-size:${mealItem.fontSize!14}px;font-weight:${mealItem.bold!700};" align="left">
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
                                    <td style="width:70%;font-size:${mealItem.fontSize!14}px;font-weight:${mealItem.bold!700};" align="left" valign="top">
                                        <#if isDeleted>
                                            <del class="word-break">${mealItem.content[0]}</del>
                                        <#else>
                                            <div class="word-break">${mealItem.content[0]}</div>
                                        </#if>
                                    </td>
                                    <td style="width:30%;font-size:${mealItem.fontSize!14}px;font-weight:${mealItem.bold!700};" align="right" valign="top">
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
                                    <td style="width:${qtyWidth}px;font-size:${mealItem.fontSize!14}px;font-weight:${mealItem.bold!700};" align="left" valign="top">
                                        <#if isDeleted>
                                            <del class="word-break">${mealItem.content[0]}</del>
                                        <#else>
                                            <div class="word-break">${mealItem.content[0]}</div>
                                        </#if>
                                    </td>
                                    <td style="width:calc(100% - ${qtyWidth}px - 80px);font-size:${mealItem.fontSize!14}px;font-weight:${mealItem.bold!700};" align="left" valign="top">
                                        <#if isDeleted>
                                            <del class="word-break">${mealItem.content[1]}</del>
                                        <#else>
                                            <div class="word-break">${mealItem.content[1]}</div>
                                        </#if>
                                    </td>
                                    <td style="width:80px;font-size:${mealItem.fontSize!14}px;font-weight:${mealItem.bold!700};" align="right" valign="top">
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
                                            <td style="width:calc(100% - ${qtyWidth}px - 80px);font-size:${modifierItem.fontSize!12}px;font-weight:${modifierItem.bold!400};color:#555555;" align="left" valign="top">
                                                <div class="word-break">
                                                    <#if modifierItem.content?size gte 2>
                                                        ${modifierItem.content[1]!""}
                                                    <#else>
                                                        ${modifierItem.content[0]!""}
                                                    </#if>
                                                </div>
                                            </td>
                                            <td style="width:80px;font-size:${modifierItem.fontSize!12}px;font-weight:${modifierItem.bold!400};color:#555555;" align="right" valign="top">
                                                <div class="word-break">
                                                    <#if modifierItem.content?size gte 3>
                                                        ${modifierItem.content[2]!""}
                                                    </#if>
                                                </div>
                                            </td>
                                        <#else>
                                            <td style="width:70%;font-size:${modifierItem.fontSize!12}px;font-weight:${modifierItem.bold!400};color:#555555;" align="left" valign="top">
                                                <div class="word-break">
                                                    <#if modifierItem.content?size gte 2>
                                                        ${modifierItem.content[1]!modifierItem.content[0]!""}
                                                    <#else>
                                                        ${modifierItem.content[0]!""}
                                                    </#if>
                                                </div>
                                            </td>
                                            <td style="width:30%;font-size:${modifierItem.fontSize!12}px;font-weight:${modifierItem.bold!400};color:#555555;" align="right" valign="top">
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
                                            <td style="width:calc(100% - ${qtyWidth}px - 80px);font-size:${remarkItem.fontSize!12}px;font-weight:${remarkItem.bold!400};color:#555555;" align="left" valign="top">
                                                <div class="word-break">${remarkItem.content[1]!remarkItem.content[0]!""}</div>
                                            </td>
                                            <td style="width:80px;font-size:${remarkItem.fontSize!12}px;font-weight:${remarkItem.bold!400};color:#555555;" align="right" valign="top">
                                                <div class="word-break">${remarkItem.content[2]!""}</div>
                                            </td>
                                        <#else>
                                            <td style="width:70%;font-size:${remarkItem.fontSize!12}px;font-weight:${remarkItem.bold!400};color:#555555;" align="left" valign="top">
                                                <div class="word-break">${remarkItem.content[1]!remarkItem.content[0]!""}</div>
                                            </td>
                                            <td style="width:30%;font-size:${remarkItem.fontSize!12}px;font-weight:${remarkItem.bold!400};color:#555555;" align="right" valign="top">
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
                    <td style="font-size:${noteItem.fontSize!13}px;font-weight:${noteItem.bold!400};" colspan="12" align="left">
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
            <#list orderAmountInfo.contentList as amountItem>
                <#assign amountLabel = amountItem.content[0]!"">
                <#assign amountValue = amountItem.content[1]!"">
                <#assign isTotalRow = (amountItem.isTotal?? && amountItem.isTotal) || amountLabel?lower_case?contains("total")>
                <#assign showDetailIcon = showTaxFeeModal && (
                    (amountItem.showDetailIcon?? && amountItem.showDetailIcon)
                    || amountLabel?lower_case?contains("tax")
                )>
                <#assign amountFontSize = isTotalRow?then(22, amountItem.fontSize!14)>
                <#assign amountBold = isTotalRow?then(700, amountItem.bold!400)>
                <tr>
                    <td colspan="12">
                        <table class="w-100-f" role="presentation" border="0" cellpadding="0" cellspacing="0">
                            <tr style="line-height:${setLineSpacing(amountFontSize, amountLineSpace)}px;">
                                <td style="width:70%;font-size:${amountFontSize}px;font-weight:${amountBold};" align="left" valign="top">
                                    <div>
                                        ${amountLabel}
                                        <#if showDetailIcon>
                                            <span class="info-icon" id="taxFeeInfoBtn" role="button" aria-label="Taxes and Fees detail">i</span>
                                        </#if>
                                    </div>
                                </td>
                                <td style="width:30%;font-size:${amountFontSize}px;font-weight:${amountBold};" align="right" valign="top">
                                    <div>${amountValue}</div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
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
                                <td style="width:70%;font-size:${payItem.fontSize!14}px;font-weight:${payItem.bold!600};" align="left" valign="top">
                                    <div class="word-break">${payItem.content[0]!""}</div>
                                </td>
                                <td style="width:30%;font-size:${payItem.fontSize!14}px;font-weight:${payItem.bold!600};" align="right" valign="top">
                                    <div>${payItem.content[1]!""}</div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#list>
        </#if>

        <tr>
            <td colspan="12" style="height:8px;"></td>
        </tr>
    </table>
    </div>
</div>

<#-- Tax & Fee 明细弹层：仅有 taxFeeDetailInfo 时可用 -->
<#if showTaxFeeModal>
    <div class="modal-mask" id="taxFeeModal" aria-hidden="true">
        <div class="modal-panel" role="dialog" aria-modal="true" aria-labelledby="taxFeeModalTitle">
            <table class="w-100-f" role="presentation" border="0" cellpadding="0" cellspacing="0">
                <tr>
                    <td style="font-size:18px;font-weight:700;" align="left">
                        <div id="taxFeeModalTitle">${taxFeeModalTitleText}</div>
                    </td>
                    <td style="width:40px;" align="right">
                        <button type="button" class="modal-close" id="taxFeeCloseBtn" aria-label="Close">×</button>
                    </td>
                </tr>
            </table>
            <table class="w-100-f" style="margin-top:14px;" role="presentation" border="0" cellpadding="0" cellspacing="0">
                <#list taxFeeDetailInfo.contentList as feeItem>
                    <tr style="line-height:22px;">
                        <td style="font-size:14px;padding-bottom:10px;" align="left">
                            <div>${feeItem.content[0]!""}</div>
                        </td>
                        <td style="font-size:14px;padding-bottom:10px;" align="right">
                            <div>${feeItem.content[1]!""}</div>
                        </td>
                    </tr>
                </#list>
            </table>
            <button type="button" class="modal-confirm" id="taxFeeConfirmBtn">Confirm</button>
        </div>
    </div>
    <script>
        (function () {
            var modalNode = document.getElementById("taxFeeModal");
            var openBtn = document.getElementById("taxFeeInfoBtn");
            var closeBtn = document.getElementById("taxFeeCloseBtn");
            var confirmBtn = document.getElementById("taxFeeConfirmBtn");

            function openModal() {
                if (!modalNode) {
                    return;
                }
                modalNode.classList.add("is-open");
                modalNode.setAttribute("aria-hidden", "false");
            }

            function closeModal() {
                if (!modalNode) {
                    return;
                }
                modalNode.classList.remove("is-open");
                modalNode.setAttribute("aria-hidden", "true");
            }

            if (openBtn) {
                openBtn.addEventListener("click", openModal);
            }
            if (closeBtn) {
                closeBtn.addEventListener("click", closeModal);
            }
            if (confirmBtn) {
                confirmBtn.addEventListener("click", closeModal);
            }
            if (modalNode) {
                modalNode.addEventListener("click", function (event) {
                    if (event.target === modalNode) {
                        closeModal();
                    }
                });
            }
        })();
    </script>
</#if>
</body>
</html>
