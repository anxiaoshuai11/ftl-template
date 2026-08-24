<!DOCTYPE html>
<html lang="en" style="max-width: 576px;padding: 0;margin: 0">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0,maximum-scale=1.0, user-scalable=no"/>
    <title>订单小票</title>
    <style>
        .w-100-f{
            width: 100%;
        }
        .w-70-f{
            width: 70%;
        }
        .w-50-f{
            width: 50%;
        }
        .w-45-f{
            width: 45%;
        }
        .w-40-f{
            width: 40%;
        }
        .w-30-f{
            width: 30%;
        }
        .w-20-f{
            width: 20%;
        }
        .half-line {
            width: 30%;
            height: 0;
        }
        .half-line-dashed{
            display: block;
            border-top: 2px dashed #000;
        }
        .line-box{
            width: 576px;
            padding: 0px;
        }
        .line{
            border-top: 2px dashed #000;
        }
        .line-bold{
            width: 576px;
            padding: 0px;
            border-top: 8px dashed #000;
        }
        .line-double{
            border-top: 2px dashed #000;
            border-bottom: 2px dashed #000;
            padding: 1px;
        }
        .word-break{
            word-break: break-word;
        }
        .review{
            border: 2px solid #000;
            border-radius: 40px;
        }
        div {
            width: 99%;
        }
        @font-face {
           font-family: 'HarmonyOS Sans SC';
           src: url('file:///android_asset/fonts/HarmonyOS_Sans_SC_Regular.ttf') format('truetype');
        }
    </style>
</head>
<body style="font-family:'HarmonyOS Sans SC';max-width:576px;padding:0;margin: 0;color: #000;background-color: #ffffff;">
<#function setLineSpacing fontSize lineSpace>
    <#assign space = (fontSize * (lineSpace / 6 + 1))?string["0.00"]>
    <#return space>
</#function>
<#-- 定义计算列宽的函数 -->
<#function orderQuantityColumnWidth mealInfo>
    <#assign maxLength = 0>
    <#assign fontSize = 0>
<#-- 增加集合空校验 -->
    <#if mealInfo.contentList?has_content>
        <#list mealInfo.contentList as item>
        <#-- 双重空校验 -->
            <#if item.content?? && item.content?size gt 0>
                <#assign firstContent = item.content[0]!''>
                <#assign currentLength = firstContent?trim?length>
            <#-- 数字类型转换 -->
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
<#-- 计算逻辑增强容错 -->
    <#assign maxFontSize = fontSize * maxLength>
<#-- 长度超过1时应用缩放系数 -->
    <#assign maxFontSize = maxFontSize * (maxLength > 1)?then((maxLength > 4)?then(0.8, 0.7),1)>
<#-- 限制最大值并取整 -->
    <#return (maxFontSize > 120)?then(120, maxFontSize?round)>
</#function>


<div class="w-100-f">
    <#if emailInfo??>
        <table style="width: 576px;padding-top: 0px;overflow: hidden;" role="presentation" border="0" cellpadding="0" cellspacing="0">
            <tr>
                <td style="font-size:24px;">
                    ${ emailInfo }
                </td>
            </tr>
        </table>
    </#if>
    <div style="height: ${30 * ticketConfig.merchant.topBlank}px;width: 100%;"></div>
    <table style="background-color: #ffffff;width: 576px;padding-top: 0px;overflow: hidden;" role="presentation" border="0" cellpadding="0" cellspacing="0">
        <#if updateInfo??>
            <tr>
                <td style="font-size: 24px">
                    ${ updateInfo }
                </td>
            </tr>
        </#if>
        <!--退菜单-->
        <#if headerInfo?? && headerInfo.contentList??>
            <tr style="line-height: ${setLineSpacing(headerInfo.contentList[0].fontSize, headerInfo.block.lineSpace)}px;">
                <td style="background-color: #000;" align="center">
                    <div style="color: #ffffff;font-size: ${headerInfo.contentList[0].fontSize}px;font-weight: ${headerInfo.contentList[0].bold}">${headerInfo.contentList[0].content[0]}</div>
                </td>
            </tr>
            <tr>
                <td>
                    <div style="height: 20px;"></div>
                </td>
            </tr>
        </#if>

        <#if ticketConfig.merchant.showPart?? && ticketConfig.merchant.showPart>
            <#if merchantInfo ?? && merchantInfo.contentList?? && merchantInfo.contentList[0]??>
                <#if ticketConfig.merchant.logo?? && ticketConfig.merchant.logo && merchantInfo.logo?? && merchantInfo.logo !="">
                    <tr>
                        <td colspan="12" style="padding-top: 8px" align="center">
                            <img src="${merchantInfo.logo}" width="220"
                                 height="200"/>
                        </td>
                    </tr>
                </#if>
                <#assign lineSpace = merchantInfo.block.lineSpace />
                <#list merchantInfo.contentList as item>
                    <tr style="line-height: ${setLineSpacing(item.fontSize, lineSpace)}px;">
                        <td style="font-size: ${item.fontSize}px;font-weight:  ${item.bold};word-break: break-word;" colspan="12" align="center"><div>${item.content[0]}</div></td>
                    </tr>
                </#list>
            </#if>
            <tr>
                <td class="w-100-f line-box" style="height: 40px" valign="center">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>

        <!--1 Online订单，外卖/自提 -->
        <#assign orderTime = orderInfo.orderTime!'' />
        <#assign orderNumber = orderInfo.orderNumber!'' />
        <#assign diningOption = orderInfo.diningOption!'' />
        <#assign server = orderInfo.server!'' />
        <#assign guests = orderInfo.guests!'' />
        <#assign table = orderInfo.table!'' />
        <#assign plate = orderInfo.plate!'' />
        <#assign confirmationNumber = orderInfo.confirmationNumber!'' />
        <#assign orderingChannel = orderInfo.orderingChannel!'' />
        <#assign orderingChannelDiningOption = orderInfo.orderingChannelDiningOption!'' />
        <#assign block = orderInfo.block!'' />
        <#if ticketConfig.order.showPart?? && ticketConfig.order.showPart>
            <#if orderInfo.orderChannel=1>
                <tr>
                    <td colspan="12" style="padding: 0;">
                        <table class="w-100-f">
                            <tr>
                                <#if ticketConfig.orderSort.showPart?? && ticketConfig.orderSort.showPart>
                                    <td class="w-30-f" style="font-size: ${orderNumber.fontSize}px;font-weight: ${orderNumber.bold};line-height: ${setLineSpacing(orderNumber.fontSize, orderNumber.lineSpace)}px;" valign="center" align="left"><div>${orderNumber.content[0]}</div></td>
                                </#if>
                                <#if ticketConfig.ooOrderType?? && ticketConfig.ooOrderType.showPart?? && ticketConfig.ooOrderType.showPart>
                                    <td class="w-70-f" style="font-size: ${diningOption.fontSize}px;font-weight: ${diningOption.bold};line-height: ${setLineSpacing(diningOption.fontSize, diningOption.lineSpace)}px;" valign="center" align="right"><div>${diningOption.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <table class="w-100-f">
                            <tr>
                                <#if ticketConfig.ooChannel?? && ticketConfig.ooChannel.showPart?? && ticketConfig.ooChannel.showPart>
                                    <td class="w-30-f" style="font-size: ${orderingChannel.fontSize}px;font-weight: ${orderingChannel.bold};line-height: ${setLineSpacing(orderingChannel.fontSize, orderingChannel.lineSpace)}px;" valign="center" align="left"><div>${orderingChannel.content[0]}</div></td>
                                </#if>
                                <#if ticketConfig.ticketNum.showPart?? && ticketConfig.ticketNum.showPart>
                                    <td class="w-70-f" style="font-size: ${confirmationNumber.fontSize}px;font-weight:${confirmationNumber.bold};line-height: ${setLineSpacing(confirmationNumber.fontSize, confirmationNumber.lineSpace)}px;" valign="center" align="right"><div>${confirmationNumber.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <#if ticketConfig.createTime.showPart?? && ticketConfig.createTime.showPart>
                            <table class="w-100-f">
                                <tr>
                                    <td style="font-size:${orderTime.fontSize}px;font-weight: ${orderTime.bold};line-height: ${setLineSpacing(orderTime.fontSize, orderTime.lineSpace)}px;" align="left"><div>${orderTime.content[0]}</div></td>
                                </tr>
                            </table>
                        </#if>
                        <table class="w-100-f">
                            <tr>
                                <td class="w-100-f line-box">
                                    <div class="line"></div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#if>

            <!--3，三方外卖 -->
            <#if orderInfo.orderChannel<0>
                <tr>
                    <td colspan="12" style="padding: 0;">
                        <table class="w-100-f">
                            <tr>
                                <#if ticketConfig.orderSort.showPart?? && ticketConfig.orderSort.showPart>
                                    <td class="w-30-f" style="font-size:${orderNumber.fontSize}px;font-weight:${orderNumber.bold};line-height: ${setLineSpacing(orderNumber.fontSize, orderNumber.lineSpace)}px;" valign="center" align="left"><div>${orderNumber.content[0]}</div></td>
                                </#if>
                                <#if ticketConfig.ooOrderType?? && ticketConfig.ooOrderType.showPart?? && ticketConfig.ooOrderType.showPart>
                                    <td class="w-70-f" style="font-size:${diningOption.fontSize}px;font-weight:${diningOption.bold};line-height: ${setLineSpacing(diningOption.fontSize, diningOption.lineSpace)}px;" valign="center" align="right"><div>${diningOption.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <table class="w-100-f">
                            <tr>
                                <#if ticketConfig.ooChannel?? && ticketConfig.ooChannel.showPart?? && ticketConfig.ooChannel.showPart>
                                    <td class="w-30-f" style="font-size:${orderingChannel.fontSize}px;font-weight:${orderingChannel.bold};line-height: ${setLineSpacing(orderingChannel.fontSize, orderingChannel.lineSpace)}px;" valign="center" align="left"><div>${orderingChannel.content[0]}</div></td>
                                </#if>
                                <#if ticketConfig.ticketNum.showPart?? && ticketConfig.ticketNum.showPart>
                                    <td class="w-70-f" style="font-size:${confirmationNumber.fontSize}px;font-weight:${confirmationNumber.bold};line-height: ${setLineSpacing(confirmationNumber.fontSize, confirmationNumber.lineSpace)}px;" valign="center" align="right"><div>${confirmationNumber.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <#if ticketConfig.createTime.showPart?? && ticketConfig.createTime.showPart>
                            <table class="w-100-f">
                                <tr>
                                    <td style="font-size:${orderTime.fontSize}px;font-weight:${orderTime.bold};line-height: ${setLineSpacing(orderTime.fontSize, orderTime.lineSpace)}px;" align="left"><div>${orderTime.content[0]}</div></td>
                                </tr>
                            </table>
                        </#if>

                        <table class="w-100-f">
                            <tr>
                                <td class="w-100-f line-box">
                                    <div class="line"></div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#if>

            <!-- 4，POS(Dinein) 预留 -->
            <#if orderInfo.orderChannel=55 && orderInfo.orderType=1>
                <tr>
                    <td colspan="12" style="padding: 0;">
                        <table class="w-100-f">
                            <tr style="line-height: ${setLineSpacing(orderingChannel.fontSize, block.lineSpace)}px;">
                                <#if ticketConfig.orderSort.showPart?? && ticketConfig.orderSort.showPart>
                                    <td align="left" style="width:30%;font-size:${orderNumber.fontSize}px;font-weight:${orderNumber.bold};line-height: ${setLineSpacing(orderNumber.fontSize, orderNumber.lineSpace)}px;" valign="top" align="left"><div>${orderNumber.content[0]}</div></td>
                                </#if>
                                <#if ticketConfig.orderType.showPart?? && ticketConfig.orderType.showPart && diningOption?? && diningOption.content?size gt 0>
                                    <td align="right" style="width:70%;font-size:${diningOption.fontSize}px;font-weight:${diningOption.bold};line-height: ${setLineSpacing(diningOption.fontSize, diningOption.lineSpace)}px;" valign="center" align="left"><div>${diningOption.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <#if ticketConfig.channel.showPart?? && ticketConfig.channel.showPart && orderingChannel?? && orderingChannel.content?size gt 0>
                            <table width="576">
                                <tr>
                                    <td align="left" style="width:100%;font-size:${orderingChannel.fontSize}px;font-weight:${orderingChannel.bold};line-height: ${setLineSpacing(orderingChannel.fontSize, orderingChannel.lineSpace)}px;" valign="top" align="right"><div>${orderingChannel.content[0]}</div></td>
                                </tr>
                            </table>
                        </#if>

                        <table class="w-100-f">
                            <tr>
                                <#if ticketConfig.createTime.showPart?? && ticketConfig.createTime.showPart>
                                    <td style="font-size:${orderTime.fontSize}px;font-weight:${orderTime.bold};line-height: ${setLineSpacing(orderTime.fontSize, orderTime.lineSpace)}px;" align="left"><div>${orderTime.content[0]}</div></td>
                                </#if>
                                <#if ticketConfig.server.showPart?? && ticketConfig.server.showPart>
                                    <td style="font-size:${server.fontSize}px;font-weight:${server.bold};line-height: ${setLineSpacing(server.fontSize, server.lineSpace)}px;" align="right"><div>Server: ${server.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <!--FUTURE ORDER-->
                        <#if orderInfo.futureOrder?? && orderInfo.futureOrder.content[0]??>
                            <table width="576">
                                <tr>
                                    <td class="w-100-f line-box">
                                        <div class="line"></div>
                                    </td>
                                </tr>
                                <tr>
                                    <td align="center">
                                        <div style="font-size:${orderInfo.futureOrder.fontSize}px;font-weight:${orderInfo.futureOrder.bold};">${orderInfo.futureOrder.content[0]}</div>
                                    </td>
                                </tr>
                            </table>
                        </#if>
                        <table class="w-100-f">
                            <tr>
                                <td class="w-100-f line-box">
                                    <div class="line"></div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#if>

            <!--5，POS(Delivery) 预留 -->
            <#if orderInfo.orderChannel=55 && orderInfo.orderType=2>
                <tr>
                    <td colspan="12" style="padding: 0;">
                        <table class="w-100-f">
                            <tr>
                                <#if ticketConfig.orderSort.showPart?? && ticketConfig.orderSort.showPart>
                                    <td align="left" style="width: 30%;font-size:${orderNumber.fontSize}px;font-weight:${orderNumber.bold};line-height: ${setLineSpacing(orderNumber.fontSize, orderNumber.lineSpace)}px;" valign="top" align="left"><div>${orderNumber.content[0]}</div></td>
                                </#if>
                                <#if ticketConfig.orderType.showPart?? && ticketConfig.orderType.showPart && diningOption.content?size gt 0>
                                    <td align="right" style="width: 70%;font-size:${diningOption.fontSize}px;font-weight:${diningOption.bold};line-height: ${setLineSpacing(diningOption.fontSize, diningOption.lineSpace)}px;" valign="center" align="left"><div>${diningOption.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <#if diningOption.content[0]?? || confirmationNumber.content[0]??>
                            <table class="w-100-f">
                                <tr style="line-height: ${setLineSpacing(confirmationNumber.fontSize, block.lineSpace)}px;">
                                    <#if ticketConfig.channel.showPart?? && ticketConfig.channel.showPart && orderInfo.orderingChannel?? && orderingChannel?? && orderingChannel.content?size gt 0>
                                        <td align="left" style="width: 50%;font-size:${orderingChannel.fontSize}px;font-weight:${orderingChannel.bold};line-height: ${setLineSpacing(orderingChannel.fontSize, orderingChannel.lineSpace)}px;" valign="top" align="right"><div>${orderingChannel.content[0]}</div></td>
                                    </#if>
                                    <#if ticketConfig.ticketNum.showPart?? && ticketConfig.ticketNum.showPart>
                                        <td align="right" style="width: 50%;font-size:${confirmationNumber.fontSize}px;font-weight:${confirmationNumber.bold};line-height: ${setLineSpacing(confirmationNumber.fontSize, confirmationNumber.lineSpace)}px;" valign="center" align="right"><div>${confirmationNumber.content[0]}</div></td>
                                    </#if>
                                </tr>
                            </table>
                        </#if>
                        <table class="w-100-f">
                            <tr>
                                <#if ticketConfig.createTime.showPart?? && ticketConfig.createTime.showPart>
                                    <td style="font-size:${orderTime.fontSize}px;font-weight:${orderTime.bold};line-height: ${setLineSpacing(orderTime.fontSize, orderTime.lineSpace)}px;" align="left"><div>${orderTime.content[0]}</div></td>
                                </#if>
                                <#if ticketConfig.server.showPart?? && ticketConfig.server.showPart>
                                    <td style="font-size:${server.fontSize}px;font-weight:${server.bold};line-height: ${setLineSpacing(server.fontSize, server.lineSpace)}px;" align="right"><div>Server: ${server.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <table class="w-100-f">
                            <tr>
                                <td class="w-100-f line-box">
                                    <div class="line"></div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#if>
            <!--6, POS (Pickup) 预留 -->
            <#if orderInfo.orderChannel=55 && orderInfo.orderType=3>
                <tr>
                    <td colspan="12" style="padding: 0;">
                        <table class="w-100-f">
                            <tr>
                                <#if ticketConfig.orderSort.showPart?? && ticketConfig.orderSort.showPart>
                                    <td valign="top" align="left" style="width: 30%;font-size:${orderNumber.fontSize}px;font-weight:${orderNumber.bold};line-height: ${setLineSpacing(orderNumber.fontSize, orderNumber.lineSpace)}px;">
                                        <div>${orderNumber.content[0]}</div>
                                    </td>
                                </#if>
                                <#if ticketConfig.orderType.showPart?? && ticketConfig.orderType.showPart && diningOption.content?? && diningOption.content[0]??>
                                    <td align="right" style="width:70%;font-size:${diningOption.fontSize}px;font-weight:${diningOption.bold};line-height: ${setLineSpacing(diningOption.fontSize, diningOption.lineSpace)}px;" valign="center" align="left"><div>${diningOption.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <#if ticketConfig.channel.showPart?? && ticketConfig.channel.showPart && orderInfo.orderingChannel?? && orderingChannel?? && orderingChannel.content?size gt 0>
                            <table width="576">
                                <tr>
                                    <td align="left" style="width: 100%;font-size:${orderingChannel.fontSize}px;font-weight:${orderingChannel.bold};line-height: ${setLineSpacing(orderingChannel.fontSize, orderingChannel.lineSpace)}px;" valign="top" align="right"><div>${orderingChannel.content[0]}</div></td>
                                </tr>
                            </table>
                        </#if>
                        <table class="w-100-f">
                            <tr style="line-height: ${setLineSpacing(server.fontSize, orderTime.lineSpace)}px;">
                                <#if ticketConfig.createTime.showPart?? && ticketConfig.createTime.showPart>
                                    <td style="font-size:${orderTime.fontSize}px;font-weight:${orderTime.bold};line-height: ${setLineSpacing(orderTime.fontSize, orderTime.lineSpace)}px;" align="left"><div>${orderTime.content[0]}</div></td>
                                </#if>
                                <#if ticketConfig.server.showPart?? && ticketConfig.server.showPart>
                                    <td style="font-size:${server.fontSize}px;font-weight:${server.bold};line-height: ${setLineSpacing(server.fontSize, server.lineSpace)}px;" align="right"><div>Server: ${server.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <table class="w-100-f">
                            <tr>
                                <td class="w-100-f line-box">
                                    <div class="line"></div>
                                </td>
                            </tr>
                        </table>
                        <!--FUTURE ORDER-->
                        <#if orderInfo.futureOrder?? && orderInfo.futureOrder.content[0]??>
                            <table width="576">
                                <tr>
                                    <td align="center">
                                        <div style="font-size:${orderInfo.futureOrder.fontSize}px;font-weight:${orderInfo.futureOrder.bold};">${orderInfo.futureOrder.content[0]}</div>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="w-100-f line-box">
                                        <div class="line"></div>
                                    </td>
                                </tr>
                            </table>
                        </#if>
                    </td>
                </tr>
            </#if>
            <!--7, POS(walkin) 预留-->
            <#if orderInfo.orderChannel=55 && orderInfo.orderType=11>
                <tr>
                    <td colspan="12" style="padding: 0;">
                        <table class="w-100-f">
                            <tr>
                                <#if ticketConfig.orderSort.showPart?? && ticketConfig.orderSort.showPart>
                                    <td  align="left" style="width: 30%;font-size:${orderNumber.fontSize}px;font-weight:${orderNumber.bold};line-height: ${setLineSpacing(orderNumber.fontSize,orderNumber.lineSpace)}px;" valign="top" align="left"><div>${orderNumber.content[0]}</div></td>
                                </#if>
                                <#if ticketConfig.orderType.showPart?? && ticketConfig.orderType.showPart && diningOption?? && diningOption.content?? && diningOption.content[0]??>
                                    <td align="right" style="width: 70%;font-size:${diningOption.fontSize}px;font-weight:${diningOption.bold};line-height: ${setLineSpacing(diningOption.fontSize, diningOption.lineSpace)}px;" valign="center" align="left"><div>${diningOption.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <#if ticketConfig.channel.showPart?? && ticketConfig.channel.showPart && orderingChannel?? && orderingChannel.content?size gt 0>
                            <table width="576">
                                <tr>
                                    <td align="right" style="width: 100%;font-size:${orderingChannel.fontSize}px;font-weight:${orderingChannel.bold};line-height: ${setLineSpacing(orderingChannel.fontSize, orderingChannel.lineSpace)}px;" valign="top" align="right"><div>${orderingChannel.content[0]}</div></td>
                                </tr>
                            </table>
                        </#if>

                        <table class="w-100-f">
                            <tr>
                                <#if ticketConfig.createTime.showPart?? && ticketConfig.createTime.showPart>
                                    <td style="font-size:${orderTime.fontSize}px;line-height: ${setLineSpacing(orderTime.fontSize,orderTime.lineSpace)}px;" align="left"><div>${orderTime.content[0]}</div></td>
                                </#if>
                                <#if ticketConfig.server.showPart?? && ticketConfig.server.showPart>
                                    <td style="font-size:${server.fontSize}px;line-height: ${setLineSpacing(server.fontSize,server.lineSpace)}px;" align="right"><div>Server: ${server.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                        <table class="w-100-f">
                            <tr>
                                <td class="w-100-f line-box">
                                    <div class="line"></div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#if>
        </#if>
        <!--FUTURE ORDER  -->
        <#if orderInfo?? && orderInfo.futureOrder?? && orderInfo.futureOrder.content?? && orderInfo.futureOrder.content[0]??>
            <tr>
                <td>
                    <#--  staion  -->
                    <#if orderInfo.orderChannel?? && orderInfo.orderChannel=55>
                    <#-- 以下情况不显示： POS端 orderInfo.orderType=1 /orderInfo.orderType=3 时不显示 -->
                        <#if orderInfo.orderType?? && orderInfo.orderType != 1 && orderInfo.orderType != 3>
                            <table width="576">
                                <tr>
                                    <td align="center">
                                        <div style="font-size:${orderInfo.futureOrder.fontSize}px;font-weight:${orderInfo.futureOrder.bold};">${orderInfo.futureOrder.content[0]}</div>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="w-100-f line-box">
                                        <div class="line"></div>
                                    </td>
                                </tr>
                            </table>
                        </#if>
                    <#else>
                    <#--  online order  -->
                        <table width="576">
                            <tr>
                                <td align="center">
                                    <div style="font-size:${orderNumber.fontSize}px;font-weight:${orderNumber.bold};">${orderInfo.futureOrder.content[0]}</div>
                                </td>
                            </tr>
                            <tr>
                                <td class="w-100-f line-box">
                                    <div class="line"></div>
                                </td>
                            </tr>
                        </table>
                    </#if>
                </td>
            </tr>
        </#if>
        <tr>
            <td>
                <#if ticketConfig.tableInfo??>
                <#-- 勾选了桌台 或者 顾客人数   -->
                    <#if (ticketConfig.tableInfo.table?? && ticketConfig.tableInfo.table) || (ticketConfig.tableInfo.customers?? && ticketConfig.tableInfo.customers)>
                    <#--  table 不存在或为 null → config = guests，如果guests没有值，则为{}  -->
                        <#assign config = (table?? && table?is_hash)?then(table, (guests?? && guests?is_hash)?then(guests, {}))>
                    <#-- 抽离公共判断 -->
                        <#assign hasTable = table?? && table?is_hash && table.content?? && table.content?size gt 0>
                        <#assign hasGuests = guests?? && guests?is_hash && guests.content?? && guests.content?size gt 0>


                        <#if ticketConfig.tableInfo.table?? && ticketConfig.tableInfo.table &&  ticketConfig.tableInfo.customers?? && ticketConfig.tableInfo.customers>
                            <#if config?? && config?has_content>
                                <table class="w-100-f">
                                    <tr style="line-height: ${setLineSpacing(config.fontSize, config.lineSpace)}px;">
                                        <td colspan="12" align="center">
                                            <div style="font-size:${config.fontSize}px;font-weight:${config.bold};">
                                                <#if hasTable?? && hasTable>
                                                    <span>${table.content[0]}-</span>
                                                </#if>
                                                <#if hasGuests?? && hasGuests>
                                                    <span>${guests.content[0]}</span>
                                                </#if>
                                            </div>
                                        </td>
                                    </tr>
                                </table>
                            </#if>
                        </#if>
                    <#--  打开桌台，关闭顾客人数  -->
                        <#if hasTable?? && hasTable>
                            <#if ticketConfig.tableInfo.table?? && ticketConfig.tableInfo.table && !ticketConfig.tableInfo.customers>
                                <table class="w-100-f">
                                    <tr>
                                        <td style="font-size:${table.fontSize}px;font-weight:${table.bold};line-height: ${setLineSpacing(table.fontSize, table.lineSpace)}px;" colspan="12" align="center"><div>${table.content[0]}</div></td>
                                    </tr>
                                </table>
                            </#if>
                        </#if>
                    <#--  关闭桌台，打开顾客人数  -->
                        <#if hasGuests?? && hasGuests>
                            <#if !ticketConfig.tableInfo.table && ticketConfig.tableInfo.customers?? && ticketConfig.tableInfo.customers>
                                <table class="w-100-f">
                                    <tr>
                                        <td style="font-size:${guests.fontSize}px;font-weight:${guests.bold};line-height: ${setLineSpacing(guests.fontSize, guests.lineSpace)}px;" colspan="12" align="center"><div>${guests.content[0]}</div></td>
                                    </tr>
                                </table>
                            </#if>
                        </#if>
                    <#--  桌台名有值且开关开启，或者 顾客人数有值开关开启，符合一种就显示上横线  -->
                        <#if (hasTable?? && hasTable) || (hasGuests?? && hasGuests)>
                            <table class="w-100-f">
                                <tr>
                                    <td class="w-100-f line-box">
                                        <div class="line"></div>
                                    </td>
                                </tr>
                            </table>
                        </#if>
                    </#if>
                </#if>
                <#-- kiosk 的  pickup  才需要这个 -->
                <#if plate?? && plate?is_hash && plate.content?has_content && plate.content[0]??>
                    <table class="w-100-f">
                        <tr style="line-height: ${setLineSpacing(plate.fontSize, plate.lineSpace)}px;">
                            <td style="font-size:${plate.fontSize}px;font-weight:${plate.bold};" colspan="12" align="center"><div>${plate.content[0]}</div></td>
                        </tr>
                    </table>
                    <table class="w-100-f">
                        <tr>
                            <td class="w-100-f line-box">
                                <div class="line"></div>
                            </td>
                        </tr>
                    </table>
                </#if>
            </td>
        </tr>

        <#--Kiosk号码牌-->
        <#if ticketConfig.orderLocator?? && ticketConfig.orderLocator.showPart && orderLocatorInfo?? && orderLocatorInfo.contentList?? && orderLocatorInfo.contentList?size gt 0>
            <tr>
                <td>
                    <table width="576">
                        <tr>
                            <td align="center">
                                <#list orderLocatorInfo.contentList as item>
                                    <span style="line-height: ${setLineSpacing(item.fontSize, orderLocatorInfo.block.lineSpace)}px;font-size: ${item.fontSize}px;font-weight:${item.bold};vertical-align: middle;">${item.content[0]}&nbsp;</span>
                                </#list>
                            </td>
                        </tr>
                    </table>
                    <table width="576">
                        <tr>
                            <td class="w-100-f line-box">
                                <div class="line"></div>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </#if>
        <!--Kiosk设备信息-->
        <#if ticketConfig.deviceName?? && ticketConfig.deviceName.showPart && deviceNameInfo?? && deviceNameInfo.contentList?? && deviceNameInfo.contentList[0]??>
            <tr>
                <td>
                    <table width="576">
                        <tr style="line-height: ${setLineSpacing(deviceNameInfo.contentList[0].fontSize, deviceNameInfo.block.lineSpace)}px;">
                            <td style="font-size: ${deviceNameInfo.contentList[0].fontSize}px;font-weight:  ${deviceNameInfo.contentList[0].bold};word-break: break-word;" align="center">
                                <div>${deviceNameInfo.contentList[0].content[0]}</div>
                            </td>
                        </tr>
                    </table>
                    <table width="576">
                        <tr>
                            <td class="w-100-f line-box">
                                <div class="line"></div>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </#if>

        <#if customerInfo?? && customerInfo.contentList?? && customerInfo.contentList[0]??>
            <tr>
                <td>
                    <table width="576">
                        <#list customerInfo.contentList as item>
                            <tr style="line-height: ${setLineSpacing(item.fontSize, customerInfo.block.lineSpace)}px;">
                                <td style="font-size:${item.fontSize}px; font-weight: ${item.bold}" colspan="12" align="center">
                                    <div>${item.content[0]}</div>
                                </td>
                            </tr>
                        </#list>
                        <tr>
                            <td class="w-100-f line-box">
                                <div class="line"></div>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </#if>

        <!--餐品-->
        <#if ticketConfig.meal.showPart?? && ticketConfig.meal.showPart && mealInfo?? && mealInfo.contentList?? && mealInfo.contentList[0]??>
            <#list mealInfo.contentList as item>
                <#if item.content?size = 1>
                    <#list item.content as name>
                        <tr>
                            <td colspan="12">
                                <table class="w-100-f">
                                    <tr style="line-height: ${setLineSpacing(item.fontSize, mealInfo.block.lineSpace)}px;">
                                        <td style="font-size:${item.fontSize}px;font-weight: ${item.bold};" align="left">
                                            <#if item.contentType == 101>
                                                <del class="word-break">${name}</del>
                                            <#else>
                                                <div class="word-break">${name}</div>
                                            </#if>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </#list>

                    <#list item.child as modifier>
                        <tr>
                            <td colspan="12">
                                <table class="w-100-f">
                                    <tr style="line-height: ${setLineSpacing(modifier.fontSize, mealInfo.block.lineSpace)}px;">
                                        <td style="font-size:${modifier.fontSize}px;font-weight: ${modifier.bold};" align="left">
                                            <#if modifier.contentType == 101>
                                                <del class="word-break">${modifier.content[0]}</del>
                                            <#else>
                                                <div class="word-break">${modifier.content[0]}</div>
                                            </#if>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </#list>
                    <!--POS端餐品折扣，没有餐品价格不显示-->
                    <#if item.remarkChild?? && ticketConfig.meal.mealPrice>
                        <#list item.remarkChild as remark>
                            <tr>
                                <td colspan="12">
                                    <table class="w-100-f">
                                        <tr style="line-height: ${setLineSpacing(remark.fontSize, mealInfo.block.lineSpace)}px;">
                                            <td style="font-size:${remark.fontSize}px;font-weight: ${remark.bold};" align="left">
                                                <#if remark.contentType == 101>
                                                    <del class="word-break">${remark.content[0]}</del>
                                                <#else>
                                                    <div class="word-break">${remark.content[0]}</div>
                                                </#if>
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                        </#list>
                    </#if>

                </#if>
                <#if item.content?size = 2>
                    <tr>
                        <td colspan="12">
                            <table class="w-100-f">
                                <tr style="font-size: ${item.fontSize}px;font-weight: ${item.bold};line-height: ${setLineSpacing(item.fontSize, mealInfo.block.lineSpace)}px;">
                                    <#if ticketConfig.meal.quantity && ticketConfig.meal.mealName>
                                        <td style="width: ${ orderQuantityColumnWidth(mealInfo)}px;" align="left" valign="top">
                                            <#if item.contentType == 101>
                                                <del class="word-break">${item.content[0]}</del>
                                            <#else>
                                                <div class="word-break">${item.content[0]}</div>
                                            </#if>
                                        </td>
                                        <td style="width: calc(100% - ${ orderQuantityColumnWidth(mealInfo)}px);" align="left" valign="top">
                                            <#if item.contentType == 101>
                                                <del class="word-break">${item.content[1]}</del>
                                            <#else>
                                                <div class="word-break">${item.content[1]}</div>
                                            </#if>
                                        </td>
                                    </#if>
                                    <#if ticketConfig.meal.mealName && ticketConfig.meal.mealPrice>
                                        <td style="width: 70%" align="left" valign="top">
                                            <#if item.contentType == 101>
                                                <del class="word-break">${item.content[0]}</del>
                                            <#else>
                                                <div class="word-break">${item.content[0]}</div>
                                            </#if>
                                        </td>
                                        <td style="width: 30%" align="right" valign="top">
                                            <#if item.contentType == 101>
                                                <del class="word-break">${item.content[1]}</del>
                                            <#else>
                                                <div class="word-break">${item.content[1]}</div>
                                            </#if>
                                        </td>
                                    </#if>
                                    <#if ticketConfig.meal.quantity && ticketConfig.meal.mealPrice>
                                        <td style="width: ${ orderQuantityColumnWidth(mealInfo)}px;" align="left" valign="top">
                                            <#if item.contentType == 101>
                                                <del class="word-break">${item.content[0]}</del>
                                            <#else>
                                                <div class="word-break">${item.content[0]}</div>
                                            </#if>
                                        </td>
                                        <td style="width: calc(100% - ${ orderQuantityColumnWidth(mealInfo)}px);" align="right" valign="top">
                                            <#if item.contentType == 101>
                                                <del class="word-break">${item.content[1]}</del>
                                            <#else>
                                                <div class="word-break">${item.content[1]}</div>
                                            </#if>
                                        </td>
                                    </#if>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    <#list item.child as modifier>
                        <tr>
                            <td colspan="12">
                                <table class="w-100-f">
                                    <tr style="font-size:${modifier.fontSize}px;font-weight: ${modifier.bold};line-height: ${setLineSpacing(modifier.fontSize, mealInfo.block.lineSpace)}px;">
                                        <#if ticketConfig.meal.quantity && ticketConfig.meal.mealName>
                                            <td style="width: ${ orderQuantityColumnWidth(mealInfo)}px;" align="left">
                                                <#if modifier.contentType == 101>
                                                    <del class="word-break">${modifier.content[0]}</del>
                                                <#else>
                                                    <div class="word-break">${modifier.content[0]}</div>
                                                </#if>
                                            </td>
                                            <td style="width:calc(100% - ${ orderQuantityColumnWidth(mealInfo)}px);" align="left">
                                                <#if modifier.contentType == 101>
                                                    <div class="word-break">${modifier.content[1]}</div>
                                                <#else>
                                                    <div class="word-break">${modifier.content[1]}</div>
                                                </#if>
                                            </td>
                                        </#if>
                                        <#if ticketConfig.meal.mealName && ticketConfig.meal.mealPrice>
                                            <td style="width: 70%" align="left">
                                                <#if modifier.contentType == 101>
                                                    <del class="word-break">${modifier.content[0]}</del>
                                                <#else>
                                                    <div class="word-break">${modifier.content[0]}</div>
                                                </#if>
                                            </td>
                                            <td style="width: 30%" align="right">
                                                <#if modifier.contentType == 101>
                                                    <del class="word-break">${modifier.content[1]}</del>
                                                <#else>
                                                    <div class="word-break">${modifier.content[1]}</div>
                                                </#if>
                                            </td>
                                        </#if>
                                        <#if ticketConfig.meal.quantity && ticketConfig.meal.mealPrice>
                                            <td style="width: ${ orderQuantityColumnWidth(mealInfo)}px;" align="left">
                                                <#if modifier.contentType == 101>
                                                    <del class="word-break">${modifier.content[0]}</del>
                                                <#else>
                                                    <div class="word-break">${modifier.content[0]}</div>
                                                </#if>
                                            </td>
                                            <td style="width:calc(100% - ${ orderQuantityColumnWidth(mealInfo)}px);" align="right">
                                                <#if modifier.contentType == 101>
                                                    <del class="word-break">${modifier.content[1]}</del>
                                                <#else>
                                                    <div class="word-break">${modifier.content[1]}</div>
                                                </#if>
                                            </td>
                                        </#if>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </#list>
                    <!--POS端餐品折扣，没有餐品价格不显示-->
                    <#if item.remarkChild?? && ticketConfig.meal.mealPrice>
                        <#list item.remarkChild as remark>
                            <tr>
                                <td colspan="12">
                                    <table class="w-100-f">
                                        <tr style="font-size:${remark.fontSize}px;font-weight: ${remark.bold};line-height: ${setLineSpacing(remark.fontSize, mealInfo.block.lineSpace)}px;">
                                            <#if ticketConfig.meal.quantity && ticketConfig.meal.mealName>
                                                <td style="width:${ orderQuantityColumnWidth(mealInfo)}px;" align="left">
                                                    <#if remark.contentType == 101>
                                                        <del class="word-break">${remark.content[0]}</del>
                                                    <#else>
                                                        <div class="word-break">${remark.content[0]}</div>
                                                    </#if>
                                                </td>
                                                <td style="width:calc(100% - ${ orderQuantityColumnWidth(mealInfo)}px);" align="left">
                                                    <#if remark.contentType == 101>
                                                        <del class="word-break">${remark.content[1]}</del>
                                                    <#else>
                                                        <div class="word-break">${remark.content[1]}</div>
                                                    </#if>
                                                </td>
                                            </#if>
                                            <#if ticketConfig.meal.mealName && ticketConfig.meal.mealPrice>
                                                <td style="width: 70%" align="left">
                                                    <#if remark.contentType == 101>
                                                        <del class="word-break">${remark.content[0]}</del>
                                                    <#else>
                                                        <div class="word-break">${remark.content[0]}</div>
                                                    </#if>
                                                </td>
                                                <td style="width: 30%" align="right">
                                                    <#if remark.contentType == 101>
                                                        <del class="word-break">${remark.content[1]}</del>
                                                    <#else>
                                                        <div class="word-break">${remark.content[1]}</div>
                                                    </#if>
                                                </td>
                                            </#if>
                                            <#if ticketConfig.meal.quantity && ticketConfig.meal.mealPrice>
                                                <td style="width:${ orderQuantityColumnWidth(mealInfo)}px;" align="left">
                                                    <#if remark.contentType == 101>
                                                        <del class="word-break">${remark.content[0]}</del>
                                                    <#else>
                                                        <div class="word-break">${remark.content[0]}</div>
                                                    </#if>
                                                </td>
                                                <td style="width:calc(100% - ${ orderQuantityColumnWidth(mealInfo)}px);" align="right">
                                                    <#if remark.contentType == 101>
                                                        <del class="word-break">${remark.content[1]}</del>
                                                    <#else>
                                                        <div class="word-break">${remark.content[1]}</div>
                                                    </#if>
                                                </td>
                                            </#if>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                        </#list>
                    </#if>
                </#if>

                <#if item.content?size = 3>
                    <tr>
                        <td colspan="12">
                            <table class="w-100-f">
                                <tr style="font-size: ${item.fontSize}px;font-weight: ${item.bold};line-height: ${setLineSpacing(item.fontSize, mealInfo.block.lineSpace)}px;">
                                    <#-- 第一列：动态宽度 -->
                                    <td style="width: ${ orderQuantityColumnWidth(mealInfo)}px;" valign="top">
                                        <#if item.contentType == 101>
                                            <del class="word-break">${item.content[0]}</del>
                                        <#else>
                                            <div class="word-break">${item.content[0]}</div>
                                        </#if>
                                    </td>
                                    <#-- 第二列：剩余宽度 (100% - 第一列 - 27%) -->
                                    <td style="width: calc(73% - ${ orderQuantityColumnWidth(mealInfo)}px);" valign="top">
                                        <#if item.contentType == 101>
                                            <del class="word-break">${item.content[1]}</del>
                                        <#else>
                                            <div class="word-break">${item.content[1]}</div>
                                        </#if>
                                    </td>
                                    <td style="width: 27%;" align="right" valign="top">
                                        <#if item.contentType == 101>
                                            <del class="word-break">${item.content[2]}</del>
                                        <#else>
                                            <div class="word-break">${item.content[2]}</div>
                                        </#if>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    <#if item.child??>
                        <#list item.child as modifier>
                            <tr>
                                <td>
                                    <table class="w-100-f">
                                        <tr style="font-size:${modifier.fontSize}px;font-weight: ${modifier.bold};line-height: ${setLineSpacing(modifier.fontSize, mealInfo.block.lineSpace)}px;">
                                            <td style="width:${ orderQuantityColumnWidth(mealInfo)}px;" valign="top">
                                                <#if modifier.contentType == 101>
                                                    <del>${modifier.content[0]}</del>
                                                <#else>
                                                    <div>${modifier.content[0]}</div>
                                                </#if>
                                            </td>
                                            <td style="width:calc(73% - ${ orderQuantityColumnWidth(mealInfo)}px);">
                                                <#if modifier.contentType == 101>
                                                    <del class="word-break">${modifier.content[1]}</del>
                                                <#else>
                                                    <div class="word-break">${modifier.content[1]}</div>
                                                </#if>
                                            </td>
                                            <td style="width: 27%;" align="right" valign="top">
                                                <#if modifier.contentType == 101>
                                                    <del class="word-break">${modifier.content[2]}</del>
                                                <#else>
                                                    <div class="word-break">${modifier.content[2]}</div>
                                                </#if>
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                        </#list>
                    </#if>
                    <!--POS端餐品折扣，没有餐品价格不显示-->
                    <#if item.remarkChild?? && ticketConfig.meal.mealPrice>
                        <#list item.remarkChild as remark>
                            <tr>
                                <td>
                                    <table class="w-100-f">
                                        <tr style="line-height: ${setLineSpacing(remark.fontSize, mealInfo.block.lineSpace)}px;">
                                            <td style="width: ${ orderQuantityColumnWidth(mealInfo)}px;" valign="top">
                                                <#if remark.contentType == 101>
                                                    <del>${remark.content[0]}</del>
                                                <#else>
                                                    <div>${remark.content[0]}</div>
                                                </#if>
                                            </td>
                                            <td style="width:calc(73% - ${ orderQuantityColumnWidth(mealInfo)}px);font-size:${remark.fontSize}px;font-weight: ${remark.bold};">
                                                <#if remark.contentType == 101>
                                                    <del class="word-break">${remark.content[1]}</del>
                                                <#else>
                                                    <div class="word-break">${remark.content[1]}</div>
                                                </#if>
                                            </td>
                                            <td style="width: 27%;font-size:${remark.fontSize}px;font-weight: ${remark.bold};" align="right" valign="top">
                                                <#if remark.contentType == 101>
                                                    <del class="word-break">${remark.content[2]}</del>
                                                <#else>
                                                    <div class="word-break">${remark.content[2]}</div>
                                                </#if>
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                        </#list>
                    </#if>
                </#if>

                <#if ticketConfig.meal.partingLine?? && ticketConfig.meal.partingLine>
                    <tr>
                        <td class="w-100-f line-box">
                            <div class="line"></div>
                        </td>
                    </tr>
                </#if>
            <#--  给pos使用，增加餐品分割线  -->
                <#if item.underLine?? && item.underLine == 1>
                    <tr>
                        <td class="w-100-f">
                            <div class="line-bold"></div>
                        </td>
                    </tr>
                </#if>
            </#list>
        </#if>
        <#if ticketConfig.meal.partingLine?? && ticketConfig.meal.partingLine==false>
            <tr>
                <td class="w-100-f line-box">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>
        <!--餐具-->
        <#if ticketConfig.cutlery?? && ticketConfig.cutlery.showPart && cutleryInfo?? && cutleryInfo.contentList?? && cutleryInfo.contentList[0]??>
            <tr class="w-100-f" style="line-height: ${setLineSpacing(cutleryInfo.contentList[0].fontSize, cutleryInfo.block.lineSpace)}px;">
                <td>
                    <div style="font-size:  ${cutleryInfo.contentList[0].fontSize}px; font-weight: ${cutleryInfo.contentList[0].bold};" >${cutleryInfo.contentList[0].content[0]}</div>
                </td>
            </tr>
            <tr>
                <td class="w-100-f line-box">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>
        <!-- 整单备注 -->
        <#if ticketConfig.note.orderNote?? && ticketConfig.note.orderNote && orderNoteInfo?? && orderNoteInfo.contentList?? && orderNoteInfo.contentList[0]??>
            <#list orderNoteInfo.contentList as note>
                <tr class="w-100-f" style="line-height: ${setLineSpacing(note.fontSize, orderNoteInfo.block.lineSpace)}px;">
                    <td class="w-100-f" style="font-size: ${note.fontSize}px; font-weight: ${note.bold}" colspan="3">
                        <div class="word-break">${note.content[0]}</div>
                    </td>
                </tr>
            </#list>
            <tr>
                <td class="w-100-f line-box">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>
        <!--total item 数量合计-->
        <#if ticketConfig.totalItems?? && ticketConfig.totalItems.showPart?? && ticketConfig.totalItems.showPart && totalItemsInfo?? && totalItemsInfo.contentList?? && totalItemsInfo.contentList[0]??>
            <tr>
                <td style="font-size: ${totalItemsInfo.contentList[0].fontSize}px; font-weight: ${totalItemsInfo.contentList[0].bold}">
                    <div style="line-height: ${setLineSpacing(totalItemsInfo.contentList[0].fontSize, totalItemsInfo.block.lineSpace)}px;">${totalItemsInfo.contentList[0].content[0]}</div>
                </td>
            </tr>
            <tr>
                <td class="w-100-f line-box">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>

        <!-- 金额明细 -->
        <#if ticketConfig.expense.showPart?? && ticketConfig.expense.showPart && orderAmountInfo ?? && orderAmountInfo.contentList?? && orderAmountInfo.contentList[0]??>
            <#list orderAmountInfo.contentList as amount>
                <tr>
                    <td colspan="12">
                        <table style="width: 100%;">
                            <tr style="line-height: ${setLineSpacing(amount.fontSize, orderAmountInfo.block.lineSpace)}px;">
                                <td style="width: 70%;font-size: ${amount.fontSize}px; font-weight: ${amount.bold};" align="left"><div>${amount.content[0]}</div></td>
                                <td style="width: 30%;font-size:  ${amount.fontSize}px; font-weight: ${amount.bold};" align="right"><div>${amount.content[1]}</div></td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#list>
            <#if !(cardCashPriceInfo?? && cardCashPriceInfo.contentList?? && cardCashPriceInfo.contentList[0]??)>
                <tr>
                    <td class="w-100-f line-box">
                        <div class="line"></div>
                    </td>
                </tr>
            </#if>
        </#if>
        <!-- 刷卡价/现金价 -->
        <#if cardCashPriceInfo?? && cardCashPriceInfo.contentList?? && cardCashPriceInfo.contentList[0]??>
            <#if (ticketConfig.expense.cardPrice?? && ticketConfig.expense.cardPrice) || (ticketConfig.expense.cashPrice?? && ticketConfig.expense.cashPrice)>
                <tr>
                    <td class="w-100-f line-box">
                        <div class="line-double"></div>
                    </td>
                </tr>
                <tr>
                    <td colspan="12">
                        <!-- 刷卡价/现金价都为true -->
                        <#if ticketConfig.expense.cardPrice && ticketConfig.expense.cashPrice>
                            <table class="w-100-f">
                                <tr>
                                    <td class="w-40-f" align="right">
                                        <table class="w-100-f">
                                            <tr style="line-height: ${setLineSpacing(cardCashPriceInfo.contentList[0].fontSize, cardCashPriceInfo.block.lineSpace)}px;">
                                                <td class="w-100-f" style="font-size: ${cardCashPriceInfo.contentList[0].fontSize}px;font-weight: ${cardCashPriceInfo.contentList[0].bold};" align="right">${cardCashPriceInfo.contentList[0].content[0]}</td>
                                            </tr>
                                            <tr style="line-height: ${setLineSpacing(cardCashPriceInfo.contentList[0].fontSize, cardCashPriceInfo.block.lineSpace)}px;">
                                                <td class="w-100-f" style="font-size: ${cardCashPriceInfo.contentList[0].fontSize}px;font-weight: ${cardCashPriceInfo.contentList[0].bold};" align="right">${cardCashPriceInfo.contentList[0].content[1]}</td>
                                            </tr>
                                        </table>
                                    </td>
                                    <td class="w-20-f" align="center" valign="center">/</td>
                                    <td class="w-40-f" align="left">
                                        <table class="w-100-f">
                                            <tr style="line-height: ${setLineSpacing(cardCashPriceInfo.contentList[1].fontSize, cardCashPriceInfo.block.lineSpace)}px;">
                                                <td class="w-100-f" style="font-size: ${cardCashPriceInfo.contentList[1].fontSize}px;font-weight: ${cardCashPriceInfo.contentList[1].bold};" align="left">${cardCashPriceInfo.contentList[1].content[0]}</td>
                                            </tr>
                                            <tr style="line-height: ${setLineSpacing(cardCashPriceInfo.contentList[1].fontSize, cardCashPriceInfo.block.lineSpace)}px;">
                                                <td class="w-100-f" style="font-size: ${cardCashPriceInfo.contentList[1].fontSize}px;font-weight: ${cardCashPriceInfo.contentList[1].bold};" align="left">${cardCashPriceInfo.contentList[1].content[1]}</td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>
                        <#elseif ticketConfig.expense.cardPrice || ticketConfig.expense.cashPrice>
                            <!-- 刷卡价/现金价其中一个为true -->
                            <table class="w-100-f">
                                <tr style="line-height: ${setLineSpacing(cardCashPriceInfo.contentList[0].fontSize, cardCashPriceInfo.block.lineSpace)}px;">
                                    <td class="w-100-f" style="font-size: ${cardCashPriceInfo.contentList[0].fontSize}px;font-weight: ${cardCashPriceInfo.contentList[0].bold};" align="center">${cardCashPriceInfo.contentList[0].content[0]}</td>
                                </tr>
                                <tr style="line-height: ${setLineSpacing(cardCashPriceInfo.contentList[0].fontSize, cardCashPriceInfo.block.lineSpace)}px;">
                                    <td class="w-100-f" style="font-size: ${cardCashPriceInfo.contentList[0].fontSize}px;font-weight: ${cardCashPriceInfo.contentList[0].bold};" align="center">${cardCashPriceInfo.contentList[0].content[1]}</td>
                                </tr>
                            </table>
                        </#if>
                    </td>
                </tr>
                <tr>
                    <td class="w-100-f line-box">
                        <div class="line-double"></div>
                    </td>
                </tr>
            </#if>
        </#if>
        <!-- 交易/小票信息 -->
        <#if tradeInfo?? && tradeInfo.contentList?? && tradeInfo.contentList[0]?? && ticketConfig.trading.showPart?? && ticketConfig.trading.showPart>
            <#list tradeInfo.contentList as trade>
                <tr>
                    <td colspan="12">
                        <table class="w-100-f">
                            <tr style="line-height: ${setLineSpacing(trade.fontSize, tradeInfo.block.lineSpace)}px;">
                                <td class="w-70-f" style="font-size: ${trade.fontSize}px; font-weight: ${trade.bold};" align="left"><div>${trade.content[0]}</div></td>
                                <td class="w-30-f" style="font-size: ${trade.fontSize}px; font-weight: ${trade.bold};" align="right"><div>${trade.content[1]}</div></td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#list>
            <tr>
                <td class="w-100-f line-box">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>
        <!-- 礼品卡余额 -->
        <#if giftCardRemainInfo?? && giftCardRemainInfo.contentList?? && giftCardRemainInfo.contentList[0]??>
            <#list giftCardRemainInfo.contentList as gift>
                <tr>
                    <td colspan="12">
                        <table class="w-100-f">
                            <tr style="line-height: ${setLineSpacing(gift.fontSize, giftCardRemainInfo.block.lineSpace)}px;font-size: ${gift.fontSize}px; font-weight: ${gift.bold};">
                                <td class="w-70-f" align="left">${gift.content[0]}</td>
                                <td class="w-30-f" align="right">${gift.content[1]}</td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#list>
            <tr>
                <td class="w-100-f line-box">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>
        <#-- OPF / cash discount  -->
        <#if cashDiscountInfo?? && cashDiscountInfo.contentList?? && cashDiscountInfo.contentList?size gt 0>
            <tr>
                <td>
                    <table class="w-100-f">
                        <tr style="line-height: ${setLineSpacing(cashDiscountInfo.contentList[0].fontSize, cashDiscountInfo.block.lineSpace)}px;font-size: ${cashDiscountInfo.contentList[0].fontSize}px; font-weight: ${cashDiscountInfo.contentList[0].bold};">
                            <td align="center">${cashDiscountInfo.contentList[0].content[0]}</td>
                        </tr>
                    </table>
                </td>
            </tr>
            <tr>
                <td class="w-100-f line-box">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>

        <#if tipInfo?? && tipInfo.contentList?? && tipInfo.contentList[0]?? && ticketConfig.tipSuggestions?? && ticketConfig.tipSuggestions.showPart?? && ticketConfig.tipSuggestions.showPart>
            <#list tipInfo.contentList as tip>
                <tr>
                    <td colspan="12">
                        <table class="w-100-f">
                            <tr style="line-height: ${setLineSpacing(tip.fontSize, tipInfo.block.lineSpace)}px;font-size: ${tip.fontSize}px; font-weight: ${tip.bold};">
                                <#if tip.content?? && tip.content[1]??>
                                    <td class="w-50-f" align="right" style="padding-right: 20px;">
                                        <div>${tip.content[0]}</div>
                                    </td>
                                    <td class="w-50-f" align="left">
                                        <div>${tip.content[1]}</div>
                                    </td>
                                <#else>
                                    <td align="center" valign="center"><div>${tip.content[0]}</div></td>
                                </#if>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#list>
            <tr style="height: 40px">
                <td class="w-100-f line-box">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>
        <#--  评价管理  -->
        <#if ticketConfig.review?? && ticketConfig.review.showPart?? && reviewInfo?? && reviewInfo.contentList?size gt 0>
            <tr>
                <td colspan="12">
                    <table width="576">
                        <tr>
                            <td colspan="12" align="center">
                                <div style="width:100%;height: 60px;"></div>
                            </td>
                        </tr>
                        <#if ticketConfig.review?? && ticketConfig.review.starStyle?? && ticketConfig.review.starStyle == 1>
                            <tr>
                                <td colspan="12" align="center">
                                    <div class="review">
                                        <#--  星星的样式 -->
                                        <img style="width: 300px;height:48px;margin-top: -24px;background-color: #ffffff;" src="${reviewInfo.contentList[0].content[0]}"/>
                                        <div style="width: 100%;height:30px;"></div>
                                        <#--  二维码  -->
                                        <img style="width:300px;height:300px;" src="${reviewInfo.contentList[1].content[0]}"/>
                                        <div style="width: 100%;height:30px;"></div>
                                        <div style="line-height: ${setLineSpacing(reviewInfo.contentList[2].fontSize, reviewInfo.block.lineSpace)}px;font-weight: ${reviewInfo.contentList[2].bold};font-size: ${reviewInfo.contentList[2].fontSize}px;">${reviewInfo.contentList[2].content[0]}</div>
                                        <div style="width: 100%;height:30px;"></div>
                                    </div>
                                </td>
                            </tr>
                        </#if>
                        <#if ticketConfig.review?? && ticketConfig.review.starStyle?? && (ticketConfig.review.starStyle == 2 || ticketConfig.review.starStyle == 3)>
                            <tr>
                                <td colspan="12" align="center">
                                    <div class="review">
                                        <#--  星星的样式 -->
                                        <img style="width: 404px;height:32px;margin-top: -16px;background-color: #ffffff;" src="${reviewInfo.contentList[0].content[0]}"/>
                                        <div style="width: 100%;height:30px;"></div>
                                        <#--  二维码  -->
                                        <img style="width:300px;height:300px;" src="${reviewInfo.contentList[1].content[0]}"/>
                                        <div style="width: 100%;height:30px;"></div>
                                        <div style="line-height: ${setLineSpacing(reviewInfo.contentList[2].fontSize, reviewInfo.block.lineSpace)}px;font-weight: ${reviewInfo.contentList[2].bold};font-size: ${reviewInfo.contentList[2].fontSize}px;">${reviewInfo.contentList[2].content[0]}</div>
                                        <div style="width: 100%;height:30px;"></div>
                                    </div>
                                    <img style="width: 404px;height:32px;margin-top: -16px;background-color: #ffffff;" src="${reviewInfo.contentList[0].content[0]}"/>
                                </td>
                            </tr>
                        </#if>
                        <#if ticketConfig.review?? && ticketConfig.review.starStyle?? && ticketConfig.review.starStyle == 4>
                            <tr>
                                <td colspan="12" align="center">
                                    <div class="review">
                                        <#--  星星的样式 -->
                                        <img style="width: 102px;height:72px;margin-top: -36px;margin-left: -340px;background-color: #ffffff;" src="${reviewInfo.contentList[0].content[0]}"/>
                                        <div style="width: 100%;height:30px;"></div>
                                        <#--  二维码  -->
                                        <img style="width:300px;height:300px;" src="${reviewInfo.contentList[1].content[0]}"/>
                                        <div style="width: 100%;height:30px;"></div>
                                        <div style="line-height: ${setLineSpacing(reviewInfo.contentList[2].fontSize, reviewInfo.block.lineSpace)}px;font-weight: ${reviewInfo.contentList[2].bold};font-size: ${reviewInfo.contentList[2].fontSize}px;">${reviewInfo.contentList[2].content[0]}</div>
                                        <div style="width: 100%;height:60px;"></div>
                                    </div>
                                    <img style="transform: rotateY(180deg); width: 102px;height:72px;margin-top: -36px;margin-left: 340px;background-color: #ffffff;" src="${reviewInfo.contentList[0].content[1]}"/>
                                </td>
                            </tr>
                        </#if>
                        <#if ticketConfig.review?? && ticketConfig.review.starStyle?? && ticketConfig.review.starStyle == 5>
                            <tr>
                                <td colspan="12" align="center">
                                    <div class="review">
                                        <div style="width: 100%;height: 20px;"></div>
                                        <div style="width: 500px; height: 100%; border: 2px solid #000000;">
                                            <div>
                                                <#--  星星的样式 -->
                                                <img style="width: 44px;height: 35px;margin-top: -18px;margin-left: -22px;float: left;background-color: #ffffff;" src="${reviewInfo.contentList[0].content[0]}"/>
                                                <img style="width: 44px;height: 35px;margin-top: -18px;margin-right: -22px;float: right;background-color: #ffffff;" src="${reviewInfo.contentList[0].content[1]}"/>
                                            </div>
                                            <div style="width: 100%;height:30px;"></div>
                                            <#--  二维码  -->
                                            <img style="width:300px;height:300px;" src="${reviewInfo.contentList[1].content[0]}"/>
                                            <div style="width: 100%;height:30px;"></div>
                                            <div style="line-height: ${setLineSpacing(reviewInfo.contentList[2].fontSize, reviewInfo.block.lineSpace)}px;font-weight: ${reviewInfo.contentList[2].bold};font-size: ${reviewInfo.contentList[2].fontSize}px;">${reviewInfo.contentList[2].content[0]}</div>
                                            <div style="width: 100%;height:60px;"></div>
                                            <div>
                                                <#--  星星的样式 -->
                                                <img style="width: 44px;height: 35px;margin-top: -18px;margin-left: -22px;float: left;background-color: #ffffff;" src="${reviewInfo.contentList[0].content[0]}"/>
                                                <img style="width: 44px;height: 35px;margin-top: -18px;margin-right: -22px;float: right;background-color: #ffffff;" src="${reviewInfo.contentList[0].content[1]}"/>
                                            </div>
                                        </div>
                                    </div>
                                </td>
                            </tr>
                        </#if>
                    </table>
                </td>
            </tr>
        </#if>

        <!--条形码-->
        <#if ticketConfig.footer.barCode?? && ticketConfig.footer.barCode && barCode??>
            <tr>
                <td colspan="12" align="center">
                    <img width="540" src="${barCode}" alt="">
                </td>
            </tr>
        </#if>
        <#if ticketConfig.footer.orderSn?? && ticketConfig.footer.orderSn && orderNumberInfo?? && orderNumberInfo.contentList?? && orderNumberInfo.contentList[0]??>
            <#list orderNumberInfo.contentList as orderSn>
                <tr>
                    <td colspan="12">
                        <table class="w-100-f">
                            <tr style="line-height: ${setLineSpacing(orderSn.fontSize, orderNumberInfo.block.lineSpace)}px;">
                                <td align="left" style="width: 30%;font-size: ${orderSn.fontSize}px; font-weight: ${orderSn.bold};">
                                    <div>${orderSn.content[0]}</div>
                                </td>
                                <td class="w-50-f" align="right" style="width: 70%;font-size: ${orderSn.fontSize}px; font-weight: ${orderSn.bold};">
                                    <div>${orderSn.content[1]}</div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#list>
        </#if>
        <!-- 小票描述 -->
        <#if ticketConfig.footer.ticketImage?? && ticketConfig.footer.ticketImage>
            <#if footImageInfo?? && footImageInfo.contentList?? && footImageInfo.contentList[0]??>
                <#list footImageInfo.contentList as imgDesc>
                    <tr>
                        <td colspan="12">
                            <table class="w-100-f">
                                <tr style="line-height: ${setLineSpacing(imgDesc.fontSize, footImageInfo.block.lineSpace)}px;">
                                    <td colspan="12" style="font-size: ${imgDesc.fontSize}px; font-weight: ${imgDesc.bold};" align="center" valign="center"><div>${imgDesc.content[0]}</div></td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </#list>
            </#if>
            <!--小票图片-->
            <#if ticketConfig.footer.imageUrl??>
                <tr>
                    <td colspan="12" align="center">
                        <!--如果imagePercent没有值，则默认为百分之100-->
                        <img style="margin-top: 8px; width:${ticketConfig.footer.imagePercent!100}%;" src="${ticketConfig.footer.imageUrl}" alt="">
                    </td>
                </tr>
            </#if>
        </#if>
        <!--底部文案-->
        <#if footerInfo?? && footerInfo.contentList??>
            <#if footerInfo.contentList[0]?? && footerInfo.contentList[0].content?? && ticketConfig.footer.bottomText?? && ticketConfig.footer.bottomText>
                <tr style="line-height: ${setLineSpacing(footerInfo.contentList[0].fontSize, footerInfo.block.lineSpace)}px;">
                    <td style="font-size: ${footerInfo.contentList[0].fontSize}px; font-weight: ${footerInfo.contentList[0].bold};" colspan="12" align="center"><div>${footerInfo.contentList[0].content[0]}</div></td>
                </tr>
            </#if>
        </#if>
        <#-- 现金取整提示文案 -->
        <#if cashRoundingNotice?? && cashRoundingNotice.contentList[0]?has_content && ticketConfig.footer.cashRoundingNotice?? && ticketConfig.footer.cashRoundingNotice>
            <#assign cashRoundingItem = cashRoundingNotice.contentList[0]>
            <tr style="line-height: ${setLineSpacing(cashRoundingItem.fontSize, cashRoundingNotice.block.lineSpace)}px;">
                <td style="font-size: ${cashRoundingItem.fontSize}px; font-weight: ${cashRoundingItem.bold};" colspan="12" align="center"><div>${cashRoundingItem.content[0]}</div></td>
            </tr>
        </#if>

        <#if footerInfo?? && footerInfo.contentList??>
            <!-- --- PAID --- -->
            <#if footerInfo.contentList[1]?? && footerInfo.contentList[1].content?? && ticketConfig.pay.payStatus?? && ticketConfig.pay.payStatus>
                <tr>
                    <td colspan="12">
                        <table class="w-100-f">
                            <tr style="line-height: ${setLineSpacing(footerInfo.contentList[1].fontSize, footerInfo.block.lineSpace)}px;">
                                <td class="half-line">
                                    <div class="half-line-dashed"></div>
                                </td>
                                <td class="w-40-f" style="font-size: ${footerInfo.contentList[1].fontSize}px; font-weight: ${footerInfo.contentList[1].bold};" valign="center" align="center">${footerInfo.contentList[1].content[0]}</td>
                                <td class="half-line">
                                    <div class="half-line-dashed"></div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#if>
            <!-- 商家联 -->
            <#if footerInfo.contentList[2]?? && footerInfo.contentList[2].content?? && footerInfo.contentList[2].content[0]??>
                <tr style="line-height: ${setLineSpacing(footerInfo.contentList[2].fontSize, footerInfo.block.lineSpace)}px;">
                    <td style="font-size: ${footerInfo.contentList[2].fontSize}px; font-weight: ${footerInfo.contentList[2].bold};line-height: 60px;" colspan="12" align="center">${footerInfo.contentList[2].content[0]}</td>
                </tr>
            </#if>
            <!--结账时间-->
            <#if footerInfo.contentList[3]?? && footerInfo.contentList[3].content[0]?? &&  ticketConfig.footer.checkOut?? && ticketConfig.footer.checkOut>
                <tr style="line-height: ${setLineSpacing(footerInfo.contentList[3].fontSize, footerInfo.block.lineSpace)}px;">
                    <td style="font-size: ${footerInfo.contentList[3].fontSize}px; font-weight: ${footerInfo.contentList[3].bold};" colspan="12" align="center">
                        <div>${footerInfo.contentList[3].content[0]} ${footerInfo.contentList[3].content[1]}</div>
                    </td>
                </tr>
            </#if>
            <!--打印时间 请勿换行-->
            <#if footerInfo.contentList[4]?? && footerInfo.contentList[4].content[0]?? && ((ticketConfig.footer.printerTime?? && ticketConfig.footer.printerTime) || (ticketConfig.footer.printerName?? && ticketConfig.footer.printerName))>
                <tr style="line-height: ${setLineSpacing(footerInfo.contentList[4].fontSize, footerInfo.block.lineSpace)}px;">
                    <td style="font-size: ${footerInfo.contentList[4].fontSize}px; font-weight: ${footerInfo.contentList[4].bold};" colspan="12" align="center">
                        <div><#if ticketConfig.footer.printerTime?? && ticketConfig.footer.printerTime>${footerInfo.contentList[4].content[0]} </#if><#if ticketConfig.footer.printerName?? && ticketConfig.footer.printerName>${footerInfo.contentList[4].content[1]}</#if></div>
                    </td>
                </tr>
            </#if>
        </#if>
        <tr>
            <td>
                <div style="height: 20px"></div>
            </td>
        </tr>
        <!--品牌logo-->
        <#if frontLogo??>
            <tr>
                <td align="center">
                    <img height="32" src="${frontLogo}" alt="">
                </td>
            </tr>
            <tr>
                <td>
                    <div style="height: 30px; width: 100%;"></div>
                </td>
            </tr>
        </#if>

        <!-- 底部留白 -->
        <tr>
            <td>
                <div style="height: ${30 * ticketConfig.footer.bottomBlank}px;width: 100%;"></div>
            </td>
        </tr>
    </table>
</div>
</body>
<script type="text/javascript">

</script>
</html>
