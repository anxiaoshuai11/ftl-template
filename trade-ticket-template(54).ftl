<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>交易小票</title>
    <style>
        div {
            width: 99%;
        }
        .line-box{
            width: 576px;
            padding: 0px;
        }
        .line{
            border-top: 2px dashed #000;
        }
        .w-100-f{
            width: 100%;
        }
        .line-double{
            border-top: 2px dashed #000;
            border-bottom: 2px dashed #000;
            margin: 10px 0;
        }
        .tip-label{
            width: 100%;
            background-color: #000;
            color: #ffffff;
        }
        .my-10{
            margin-top: 10px;
            margin-bottom: 10px;
        }
        .check-box{
            float: right;
            border: 1px solid #000;
            position: relative;
        }
        .check-active{
            font-weight: 700;
            position: absolute;
            top: 0;
            left: 0;
        }
        .half-line {
            width: 30%;
            height: 0;
        }
        .half-line-dashed{
            display: block;
            border-top: 2px dashed #000;
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

<div class="w-100-f">
    <div style="height: ${30 * ticketConfig.other.topBlank}px;width: 100%;"></div>
    <table width="576" style="background-color: #ffffff;padding-top: 0px;overflow: hidden;" role="presentation" border="0" cellpadding="0" cellspacing="0">
        <#if updateInfo??>
            <tr>
                <td style="font-size: 24px">
                    ${ updateInfo }
                </td>
            </tr>
        </#if>
        <#if ticketConfig.merchant.showPart?? && ticketConfig.merchant.showPart>
            <#if merchantInfo ?? && merchantInfo.contentList?? && merchantInfo.contentList[0]??>
                <#if ticketConfig.merchant.logo?? && ticketConfig.merchant.logo && merchantInfo.logo?? && merchantInfo.logo !="">
                    <tr>
                        <td colspan="3" style="padding-top: 8px" align="center">
                            <img src="${merchantInfo.logo}" width="220"
                                 height="200"/>
                        </td>
                    </tr>
                </#if>
                <#assign lineSpace = merchantInfo.block.lineSpace />
                <#list merchantInfo.contentList as item>
                    <tr style="line-height: ${setLineSpacing(item.fontSize, lineSpace)}px;">
                        <td style="font-size: ${item.fontSize}px;font-weight:  ${item.bold};word-break: break-word;" colspan="3" align="center">
                            <div>${item.content[0]}</div>
                        </td>
                    </tr>
                </#list>
            </#if>
            <tr>
                <td class="w-100-f line-box">
                    <div class="line"></div>
                </td>
            </tr>
        </#if>

        <!--礼品卡的交易信息-->
        <#if giftOrderInfo??>
            <tr>
                <td>
                    <table width="576">
                        <#list giftOrderInfo.contentList as item>
                            <tr style="line-height: ${setLineSpacing(item.fontSize, giftOrderInfo.block.lineSpace)}px;">
                                <td style="width: 50%;">
                                    <div style="font-size: ${item.fontSize}px;font-weight: ${item.bold};">${item.content[0]}</div>
                                </td>
                                <td style="width: 50%;" align="right">
                                    <div style="font-size: ${item.fontSize}px;font-weight: ${item.bold};text-align: right;">${item.content[1]}</div>
                                </td>
                            </tr>
                        </#list>
                    </table>
                    <table width="576" class="my-10">
                        <tr>
                            <td class="w-100-f line-box">
                                <div class="line"></div>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </#if>

        <!--默认的订单信息内容-->
        <#if orderInfo?? && ticketConfig.order?? && ticketConfig.order.showPart>
            <#assign orderNumber = orderInfo.orderNumber!'' />
            <#assign orderingChannel = orderInfo.orderingChannel!'' />
            <#assign orderingChannelDiningOption = orderInfo.orderingChannelDiningOption!'' />
            <#assign diningOption = orderInfo.diningOption!'' />
            <#assign confirmationNumber = orderInfo.confirmationNumber!'' />
            <#assign orderTime = orderInfo.orderTime!'' />
            <#assign server = orderInfo.server!'' />
            <#assign block = orderInfo.block!'' />
            <#assign guests = orderInfo.guests!'' />
            <#assign table = orderInfo.table!'' />
            <tr>
            <td colspan="12" style="padding: 0;">

        <#--  等于1是online order订单  -->
            <#if orderInfo.orderChannel == 1>
                <table width="576">
                    <tr>
                        <#if ticketConfig.orderSort.showPart?? && ticketConfig.orderSort.showPart>
                            <td style="width: 172px; font-size: ${orderNumber.fontSize}px;font-weight: ${orderNumber.bold};line-height: ${setLineSpacing(orderNumber.fontSize, orderNumber.lineSpace)}px;" valign="center" align="left"><div>${orderNumber.content[0]}</div></td>
                        </#if>
                        <#if ticketConfig.ooOrderType?? && ticketConfig.ooOrderType.showPart?? && ticketConfig.ooOrderType.showPart>
                            <td style="width: 404px; font-size: ${diningOption.fontSize}px;font-weight: ${diningOption.bold};line-height: ${setLineSpacing(diningOption.fontSize, diningOption.lineSpace)}px;" valign="center" align="right"><div>${diningOption.content[0]}</div></td>
                        </#if>
                    </tr>
                </table>
                <table width="576">
                    <tr>
                        <#if ticketConfig.ooChannel?? && ticketConfig.ooChannel.showPart?? && ticketConfig.ooChannel.showPart>
                            <td style="width: 172px;font-size: ${orderingChannel.fontSize}px;font-weight: ${orderingChannel.bold};line-height: ${setLineSpacing(orderingChannel.fontSize, orderingChannel.lineSpace)}px;" valign="center" align="left"><div>${orderingChannel.content[0]}</div></td>
                        </#if>
                        <#if ticketConfig.ticketNum.showPart?? && ticketConfig.ticketNum.showPart>
                            <td style="width: 404px;font-size: ${confirmationNumber.fontSize}px;font-weight:${confirmationNumber.bold};line-height: ${setLineSpacing(confirmationNumber.fontSize, confirmationNumber.lineSpace)}px;" valign="center" align="right"><div>${confirmationNumber.content[0]}</div></td>
                        </#if>
                    </tr>
                </table>
                <#if ticketConfig.createTime.showPart?? && ticketConfig.createTime.showPart>
                    <table width="576">
                        <tr>
                            <td style="font-size:${orderTime.fontSize}px;font-weight:${orderTime.bold};line-height: ${setLineSpacing(orderTime.fontSize, orderTime.lineSpace)}px;" align="left"><div>${orderTime.content[0]}</div></td>
                        </tr>
                    </table>
                </#if>
            <#elseif orderInfo.orderChannel lt 0>
            <#--  小于0是三方外卖/  -->
                <table width="576">
                    <tr>
                        <#if ticketConfig.orderSort.showPart?? && ticketConfig.orderSort.showPart>
                            <td style="width: 172px;font-size:${orderNumber.fontSize}px;font-weight:${orderNumber.bold};line-height: ${setLineSpacing(orderNumber.fontSize, orderNumber.lineSpace)}px;" valign="center" align="left"><div>${orderNumber.content[0]}</div></td>
                        </#if>
                        <#if ticketConfig.ooOrderType?? && ticketConfig.ooOrderType.showPart?? && ticketConfig.ooOrderType.showPart>
                            <td style="width: 404px;font-size:${diningOption.fontSize}px;font-weight:${diningOption.bold};line-height: ${setLineSpacing(diningOption.fontSize, diningOption.lineSpace)}px;" valign="center" align="right"><div>${diningOption.content[0]}</div></td>
                        </#if>
                    </tr>
                </table>
                <table width="576">
                    <tr>
                        <#if ticketConfig.ooChannel?? && ticketConfig.ooChannel.showPart?? && ticketConfig.ooChannel.showPart>
                            <td style="width: 404px;font-size:${orderingChannel.fontSize}px;font-weight:${orderingChannel.bold};line-height: ${setLineSpacing(orderingChannel.fontSize, orderingChannel.lineSpace)}px;" valign="center" align="left"><div>${orderingChannel.content[0]}</div></td>
                        </#if>
                        <#if ticketConfig.ticketNum.showPart?? && ticketConfig.ticketNum.showPart>
                            <td style="width: 404px;font-size:${confirmationNumber.fontSize}px;font-weight:${confirmationNumber.bold};line-height: ${setLineSpacing(confirmationNumber.fontSize, confirmationNumber.lineSpace)}px;" valign="center" align="right"><div>${confirmationNumber.content[0]}</div></td>
                        </#if>
                    </tr>
                </table>
                <#if ticketConfig.createTime.showPart?? && ticketConfig.createTime.showPart>
                    <table width="576">
                        <tr>
                            <td style="font-size:${orderTime.fontSize}px;font-weight:${orderTime.bold};line-height: ${setLineSpacing(orderTime.fontSize, orderTime.lineSpace)}px;" align="left"><div>${orderTime.content[0]}</div></td>
                        </tr>
                    </table>
                </#if>
            <#else>
            <#--  Station使用  -->
                <table width="576">
                    <tr>
                        <#if ticketConfig.orderSort.showPart?? && ticketConfig.orderSort.showPart>
                            <td align="left" style="width: 30%;">
                                <div style="font-size: ${orderNumber.fontSize}px;font-weight: ${orderNumber.bold};line-height: ${setLineSpacing(orderNumber.fontSize, orderNumber.lineSpace)}px;">${orderNumber.content[0]}</div>
                            </td>
                        </#if>
                        <#if ticketConfig.orderType.showPart?? && ticketConfig.orderType.showPart && diningOption?? && diningOption.content?size gt 0>
                            <td  align="right" style="width: 70%;">
                                <div style="font-size: ${diningOption.fontSize}px;font-weight: ${diningOption.bold};line-height: ${setLineSpacing(diningOption.fontSize, diningOption.lineSpace)}px;word-break: break-word;">${diningOption.content[0]}</div>
                            </td>
                        </#if>
                    </tr>
                    <#if (orderingChannel.content?? && orderingChannel.content[0]??) || (confirmationNumber.content?? && confirmationNumber.content[0]??)>
                        <tr>
                            <td align="left" style="width: 50%;">
                                <#if ticketConfig.channel.showPart?? && ticketConfig.channel.showPart && orderingChannel.content?size gt 0>
                                    <div style="font-size:${orderingChannel.fontSize}px;font-weight:${orderingChannel.bold};line-height: ${setLineSpacing(orderingChannel.fontSize, orderingChannel.lineSpace)}px;">${orderingChannel.content[0]}</div>
                                </#if>
                            </td>
                            <td style="width: 50%;" align="right">
                                <#if ticketConfig.ticketNum.showPart?? && ticketConfig.ticketNum.showPart>
                                    <div style="font-size: ${confirmationNumber.fontSize}px;font-weight: ${confirmationNumber.bold};line-height: ${setLineSpacing(confirmationNumber.fontSize, confirmationNumber.lineSpace)}px;">${confirmationNumber.content[0]}</div>
                                </#if>
                            </td>
                        </tr>
                    </#if>
                    <#if (ticketConfig.createTime.showPart?? && ticketConfig.createTime.showPart) || (ticketConfig.server.showPart?? && ticketConfig.server.showPart)>
                        <tr>
                            <#if ticketConfig.createTime.showPart?? && ticketConfig.createTime.showPart>
                                <td style="width: 50%" align="left">
                                    <div style="font-size: ${orderTime.fontSize}px;font-weight: ${orderTime.bold};line-height: ${setLineSpacing(orderTime.fontSize, orderTime.lineSpace)}px;">${orderTime.content[0]}</div>
                                </td>
                            </#if>
                            <#if ticketConfig.server.showPart?? && ticketConfig.server.showPart>
                                <td style="width: 50%" align="right">
                                    <div style="font-size: ${server.fontSize}px;font-weight: ${server.bold};line-height: ${setLineSpacing(server.fontSize, server.lineSpace)}px;">${server.content[0]}</div>
                                </td>
                            </#if>
                        </tr>
                    </#if>
                </table>
            </#if>

            <!--桌台号-顾客人数-->
            <#if ticketConfig.tableInfo.table?? || ticketConfig.tableInfo.customers??>
            <#--  table 不存在或为 null → config = guests，如果guests没有值，则为{}  -->
                <#assign config = (table?? && table?is_hash)?then(table, (guests?? && guests?is_hash)?then(guests, {}))>
            <#-- 抽离公共判断 -->
                <#assign hasTable = table?? && table?is_hash && table.content?? && table.content?size gt 0>
                <#assign hasGuests = guests?? && guests?is_hash && guests.content?? && guests.content?size gt 0>

            <#--  桌台名有值且开关开启，或者 顾客人数有值开关开启，符合一种就显示上横线  -->
                <#if (hasTable?? && hasTable && ticketConfig.tableInfo.table?? && ticketConfig.tableInfo.table) || (hasGuests?? && hasGuests && ticketConfig.tableInfo.customers?? && ticketConfig.tableInfo.customers)>
                    <table class="w-100-f">
                        <tr>
                            <td class="w-100-f line-box">
                                <div class="line"></div>
                            </td>
                        </tr>
                    </table>
                </#if>

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
            </#if>
            <table width="576" class="my-10">
                <tr>
                    <td class="w-100-f line-box">
                        <div class="line"></div>
                    </td>
                </tr>
            </table>
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
            </td>
            </tr>
        </#if>

        <!--交易信息-->
        <#if transInfo?? && transInfo.contentList??>
            <#list transInfo.contentList as item>
                <tr style="line-height: ${setLineSpacing(item.fontSize, transInfo.block.lineSpace)}px;">
                    <td colspan="12" style="padding: 0;">
                        <table width="576">
                            <td style="width: 40%" align="left">
                                <div style="font-size: ${item.fontSize}px;font-weight: ${item.bold};">${item.content[0]}</div>
                            </td>
                            <td style="width: 60%" align="right">
                                <div style="font-size: ${item.fontSize}px;font-weight: ${item.bold};">${item.content[1]}</div>
                            </td>
                        </table>
                    </td>
                </tr>
            </#list>
        </#if>
        <!--付款详情-->
        <#if cardDetail?? && cardDetail.contentList?? && cardDetail.contentList?size gt 0>
            <tr>
                <td>
                    <table width="576" class="my-10">
                        <tr>
                            <td class="w-100-f line-box">
                                <div class="line"></div>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
            <tr>
                <td>
                    <table width="576">
                        <#list cardDetail.contentList as item>
                            <tr style="line-height: ${setLineSpacing(item.fontSize, cardDetail.block.lineSpace)}px;">
                                <td style="width: 100%" align="left">
                                    <div style="font-size: ${item.fontSize}px;font-weight: ${item.bold};">${item.content[0]}</div>
                                </td>
                            </tr>
                        </#list>
                    </table>
                </td>
            </tr>
        </#if>
        <!--金额信息-->
        <#if amountInfo?? && amountInfo.contentList?? && ticketConfig.tranAmount?? && ticketConfig.tranAmount?? && ticketConfig.tranAmount.showPart>
            <tr>
                <td>
                    <table width="576" class="my-10">
                        <tr>
                            <td class="w-100-f line-box">
                                <div class="line"></div>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
            <#if amountInfo?? && amountInfo.contentList??>
                <#list amountInfo.contentList as item>
                    <#if item_has_next || amountInfo.contentList?size == 1 || amountInfo.contentList?size == 2>
                        <tr style="line-height: ${setLineSpacing(item.fontSize, amountInfo.block.lineSpace)}px;">
                            <td>
                                <table width="576">
                                    <tr>
                                        <td style="width: 60%" align="left">
                                            <div style="font-size: ${item.fontSize}px;font-weight: ${item.bold};">${item.content[0]}</div>
                                        </td>
                                        <td style="width: 40%" align="right">
                                            <div style="font-size: ${item.fontSize}px;font-weight: ${item.bold};">${item.content[1]}</div>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    <#else>
                        <!--最后一个-->
                        <tr style="line-height: ${setLineSpacing(item.fontSize, amountInfo.block.lineSpace)}px;">
                            <td>
                                <table width="576">
                                    <tr>
                                        <td style="width: 60%" align="left">
                                            <div style="font-size: ${item.fontSize}px;font-weight: ${item.bold};">${item.content[0]}</div>
                                        </td>
                                        <td style="width: 40%" align="right">
                                            <span style="font-size: ${item.fontSize}px;background-color: #000;color: #ffffff;font-weight:700;padding-left: 4px;padding-right: 4px;">${item.content[1]}</span>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </#if>
                </#list>
            </#if>
        </#if>
        <#if !(tipInfo?? && tipInfo.contentList?? && tipInfo.contentList[0]??) && ticketConfig.tipInfo?? && ticketConfig.extraTip?? && (ticketConfig.tipInfo.showPart || ticketConfig.extraTip.showPart)>
            <tr>
                <td>
                    <table width="576" class="my-10">
                        <tr>
                            <td class="w-100-f line-box">
                                <div class="line"></div>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </#if>
        <!--小费显示类型  0-刷卡样式(add tips) 1-非刷卡样式(tip suggestions)-->
        <#if tipInfo?? && tipInfo.tipType == 1 && tipInfo.contentList?? && tipInfo.contentList[0]?? && ticketConfig.tipInfo?? && ticketConfig.tipInfo.showPart>
            <tr>
                <td>
                    <table width="576" class="my-10">
                        <tr>
                            <td class="line-double" colspan="12"></td>
                        </tr>
                    </table>
                </td>
            </tr>
            <#if tipInfo?? && tipInfo.contentList?? && tipInfo.contentList[0]??>
                <#list tipInfo.contentList as tip>
                    <tr>
                        <td colspan="12">
                            <table class="w-100-f">
                                <tr style="line-height: ${setLineSpacing(tip.fontSize, tipInfo.block.lineSpace)}px;font-size: ${tip.fontSize}px; font-weight: ${tip.bold};">
                                    <#if tip.content?? && tip.content[1]??>
                                        <td align="right" style="padding-right: 20px;width: 50%">
                                            <div>${tip.content[0]}</div>
                                        </td>
                                        <td style="width: 50%" align="left">
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
                    <td style="width: 100%" class="line-box">
                        <div class="line"></div>
                    </td>
                </tr>
            </#if>
        </#if>
        <!--未设置建议小费，tipInfo.tipType == 2，只显示Tips和Total-->
        <#if tipInfo?? && tipInfo.tipType == 2 && tipInfo.contentList?? && tipInfo.contentList[0]?? && ticketConfig.tipInfo?? && ticketConfig.tipInfo.showPart>
            <tr>
                <td>
                    <table width="576" class="my-10">
                        <tr>
                            <td class="line-double" colspan="12"></td>
                        </tr>
                    </table>
                </td>
            </tr>
            <tr>
                <td>
                    <table width="576">
                        <#list tipInfo.contentList as item>
                            <#if item.contentType == 1>
                                <tr>
                                    <td>
                                        <div style="height: 40px"></div>
                                    </td>
                                </tr>
                                <tr style="line-height: ${setLineSpacing(item.fontSize, tipInfo.block.lineSpace)}px;">
                                    <td align="left">
                                        <div style="font-size: ${item.fontSize}px;font-weight: ${item.bold};display: flex;">
                                            <div style="width: 17%;padding-left: 6px; box-sizing: border-box;">TIPS:</div>
                                            <div style="width: 83%;border-bottom: 2px solid #333333;"></div>
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <div style="height: 40px"></div>
                                    </td>
                                </tr>
                                <tr style="line-height: ${setLineSpacing(item.fontSize, tipInfo.block.lineSpace)}px;">
                                    <td align="center">
                                        <div style="font-size: ${item.fontSize}px;font-weight: ${item.bold};display: flex;">
                                            <div style="width: 17%;">TOTAL:</div>
                                            <div style="width: 83%;border-bottom: 2px solid #333333;"></div>
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <div style="height: 40px"></div>
                                    </td>
                                </tr>
                            </#if>
                        </#list>
                    </table>
                </td>
            </tr>
        </#if>

        <#if tipInfo?? && tipInfo.tipType == 0 && tipInfo.contentList?? && tipInfo.contentList[0]?? && ticketConfig.tipInfo?? && ticketConfig.extraTip?? && (ticketConfig.tipInfo.showPart || ticketConfig.extraTip.showPart)>
            <tr>
                <td>
                    <table width="576" style="border: 2px solid #333333;padding: 0">
                        <#list tipInfo.contentList as item>
                            <#if item.contentType == 1>
                                <tr style="line-height: ${setLineSpacing(item.fontSize, tipInfo.block.lineSpace)}px;">
                                    <td align="center">
                                        <div class="tip-label" style="padding-top: 4px;padding-bottom: 4px;font-size: ${item.fontSize}px;font-weight: ${item.bold};">${item.content[0]}</div>
                                    </td>
                                </tr>
                            </#if>
                            <#if item.contentType != 1>
                                <tr>
                                    <td>
                                        <#if item.contentType == 0>
                                            <table style="width: 100%;">
                                                <tr style="line-height: ${setLineSpacing(item.fontSize, tipInfo.block.lineSpace)}px;">
                                                    <!--选择框-->
                                                    <td style="width: 9%;" align="right" valign="center">
                                                        <#if 0 == item.selected>
                                                            <div class="check-box" style="width: ${item.fontSize}px; height: ${item.fontSize}px;"></div>
                                                        </#if>
                                                        <#if 1 == item.selected>
                                                            <div class="check-box" style="width: ${item.fontSize}px; height: ${item.fontSize}px;">
                                                                <span class="check-active" style="font-size: ${item.fontSize * 1.2}px;">√</span>
                                                            </div>
                                                        </#if>
                                                    </td>
                                                    <td style="width: 20%; font-size: ${item.fontSize}px;font-weight: ${item.bold};" align="right" valign="center">
                                                        <span>${item.content[0]}</span>
                                                    </td>
                                                    <td style="width: 1%;"></td>
                                                    <td style="width: 20%;font-size: ${item.fontSize}px;font-weight: ${item.bold};" align="left" valign="center">
                                                        <span>${item.content[1]}</span>
                                                    </td>
                                                    <td style="width: 9%;" align="right"></td>
                                                </tr>
                                            </table>
                                        </#if>
                                        <#if item.contentType == 2>
                                            <table style="width: 100%;">
                                                <tr>
                                                    <td>
                                                        <div style="height: 20px;"></div>
                                                    </td>
                                                </tr>
                                            </table>
                                            <table style="width: 100%;line-height: 36.00px;">
                                                <tr style="line-height: ${setLineSpacing(item.fontSize, tipInfo.block.lineSpace)}px;">
                                                    <td style="width: 9%;" align="right" valign="center">
                                                        <#if 0 == item.selected>
                                                            <div class="check-box" style="width: ${item.fontSize}px; height: ${item.fontSize}px;"></div>
                                                        </#if>
                                                        <#if 1 == item.selected>
                                                            <div class="check-box" style="width: ${item.fontSize}px; height: ${item.fontSize}px;">
                                                                <span class="check-active" style="font-size: ${item.fontSize * 1.2}px;">√</span>
                                                            </div>
                                                        </#if>
                                                    </td>
                                                    <td style="width: 1%;" align="right"></td>
                                                    <td style="width: 20%;border-bottom: 2px solid #333333;" valign="bottom">
                                                        <div style="text-align: center;font-size: ${item.fontSize}px;font-weight: ${item.bold};">${item.content[0]}</div>
                                                    </td>
                                                    <td style="width: 1.6%;" align="right"></td>
                                                    <td style="width: 20%;border-bottom: 2px solid #333333;" valign="bottom">
                                                        <div style="text-align: center;font-size: ${item.fontSize}px;font-weight: ${item.bold};">${item.content[1]}</div>
                                                    </td>
                                                    <td style="width: 9%;" align="right"></td>
                                                </tr>

                                            </table>
                                            <#if tipInfo.contentList?? && tipInfo.contentList[0].content?? && tipInfo.contentList[0].content[0] == 'Extra Tip'>
                                                <table style="width: 100%;">
                                                    <tr style="line-height: ${setLineSpacing(item.fontSize, tipInfo.block.lineSpace)}px;">
                                                        <td style="width: 44%;font-size: ${item.fontSize}px;font-weight: ${item.bold};" align="right">
                                                            <span>EXTRA TIP</span>
                                                        </td>
                                                        <td style="width: 18%;"></td>
                                                        <td style="width: 38%;font-size: ${item.fontSize}px;font-weight: ${item.bold};"align="left">
                                                            <span>TOTAL</span>
                                                        </td>
                                                    </tr>
                                                </table>
                                            <#else>
                                                <table style="width: 100%;">
                                                    <tr style="line-height: ${setLineSpacing(item.fontSize, tipInfo.block.lineSpace)}px;">
                                                        <td style="width: 38%;font-size: ${item.fontSize}px;font-weight: ${item.bold};" align="right">
                                                            <span>TIPS</span>
                                                        </td>
                                                        <td style="width: 24%;"></td>
                                                        <td style="width: 38%;font-size: ${item.fontSize}px;font-weight: ${item.bold};"align="left">
                                                            <span>TOTAL</span>
                                                        </td>
                                                    </tr>
                                                </table>
                                            </#if>

                                        </#if>
                                    </td>
                                </tr>
                            </#if>
                        </#list>
                    </table>
                </td>
            </tr>
        </#if>
        <#if tipInfo?? && tipInfo.tipType != 1 && ticketConfig.signatureArea?? && ticketConfig.signatureArea.showPart>
            <tr>
                <td>
                    <table width="576" style="margin-top: 60px">
                        <tr>
                            <td valign="bottom" align="center" style="font-size: 30px;height: 100px;">
                                <span>X:</span>
                                <#if tipInfo?? && tipInfo.signImg??>
                                    <span style="border-bottom: 2px solid #333333;text-align: center;padding-left: 105px;padding-right: 105px;">
                                        <img style="max-width: 200px;max-height: 140px;" src="${tipInfo.signImg}" alt="">
                                    </span>
                                <#else>
                                    <span>_____________________________</span>
                                </#if>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
            <!--小费固定文案-->
            <#if tipText?? && tipText.contentList??>
                <tr>
                    <td>
                        <div style="height: 20px;"></div>
                    </td>
                </tr>
                <tr>
                    <td style="line-height: ${setLineSpacing(tipText.contentList[0].fontSize, tipText.block.lineSpace)}px;" align="center">
                        <div style="font-size: ${tipText.contentList[0].fontSize}px; font-weight: ${tipText.contentList[0].bold};">${tipText.contentList[0].content[0]}</div>
                    </td>
                </tr>
                <tr>
                    <td>
                        <div style="height: 20px;"></div>
                    </td>
                </tr>
            </#if>
        </#if>
        <!--底部文案-->
        <#if footerInfo?? && footerInfo.contentList?? && footerInfo.contentList[0]??>
            <#if footerInfo.contentList[0]?? && footerInfo.contentList[0].content?? && ticketConfig.footer.bottomText?? && ticketConfig.footer.bottomText>
                <tr>
                    <td>
                        <table width="576" style="margin-top: 20px">
                            <tr style="line-height: ${setLineSpacing(footerInfo.contentList[0].fontSize, footerInfo.block.lineSpace)}px;">
                                <td align="center">
                                    <div style="font-size: ${footerInfo.contentList[0].fontSize}px; font-weight: ${footerInfo.contentList[0].bold};">${footerInfo.contentList[0].content[0]}</div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </#if>
            <!-- --- PAID --- -->
            <#if footerInfo.contentList[1]?? && footerInfo.contentList[1].content?? && ticketConfig.footer.tradingType?? && ticketConfig.footer.tradingType>
                <!--PARTLALLY APPROVED-->
                <tr>
                    <td colspan="12">
                        <#if amountInfo.contentList?size == 3>
                            <table style="width: 100%">
                                <tr style="line-height: ${setLineSpacing(footerInfo.contentList[1].fontSize, footerInfo.block.lineSpace)}px;">
                                    <td style="width: 15%">
                                        <div class="half-line-dashed"></div>
                                    </td>
                                    <td style="width: 70%;" valign="center" align="center">
                                        <div style="font-size: ${footerInfo.contentList[1].fontSize}px; font-weight: ${footerInfo.contentList[1].bold};">${footerInfo.contentList[1].content[0]}</div>
                                    </td>
                                    <td style="width: 15%">
                                        <div class="half-line-dashed"></div>
                                    </td>
                                </tr>
                            </table>
                        <#else>
                            <table style="width: 100%">
                                <tr style="line-height: ${setLineSpacing(footerInfo.contentList[1].fontSize, footerInfo.block.lineSpace)}px;">
                                    <td class="half-line">
                                        <div class="half-line-dashed"></div>
                                    </td>
                                    <td style="width: 40%;" valign="center" align="center">
                                        <div style="font-size: ${footerInfo.contentList[1].fontSize}px; font-weight: ${footerInfo.contentList[1].bold};">${footerInfo.contentList[1].content[0]}</div>
                                    </td>
                                    <td class="half-line">
                                        <div class="half-line-dashed"></div>
                                    </td>
                                </tr>
                            </table>
                        </#if>
                    </td>
                </tr>
            </#if>
            <!-- 商家联 -->
            <#if footerInfo.contentList[2]?? && footerInfo.contentList[2].content?? && footerInfo.contentList[2].content[0]??>
                <tr style="line-height: ${setLineSpacing(footerInfo.contentList[2].fontSize, footerInfo.block.lineSpace)}px;">
                    <td style="font-size: ${footerInfo.contentList[2].fontSize}px; font-weight: ${footerInfo.contentList[2].bold};line-height: 60px;" colspan="12" align="center">${footerInfo.contentList[2].content[0]}</td>
                </tr>
            </#if>
        </#if>
        <!--打印时间 请勿换行-->
        <#if footerInfo.contentList?? && footerInfo.contentList[3]?? && footerInfo.contentList[3].content[0]?? && ((ticketConfig.footer.printerTime?? && ticketConfig.footer.printerTime) || (ticketConfig.footer.printerName?? && ticketConfig.footer.printerName))>
            <tr style="line-height: ${setLineSpacing(footerInfo.contentList[3].fontSize, footerInfo.block.lineSpace)}px;">
                <td style="font-size: ${footerInfo.contentList[3].fontSize}px; font-weight: ${footerInfo.contentList[3].bold};" colspan="12" align="center">
                    <div><#if ticketConfig.footer.printerTime?? && ticketConfig.footer.printerTime>${footerInfo.contentList[3].content[0]} </#if><#if ticketConfig.footer.printerName?? && ticketConfig.footer.printerName>${footerInfo.contentList[3].content[1]}</#if></div>
                </td>
            </tr>
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
        <#if ticketConfig.other?? && ticketConfig.other.bottomBlank??>
            <tr>
                <td>
                    <div style="height: ${30 * ticketConfig.other.bottomBlank}px;width: 100%;"></div>
                </td>
            </tr>
        </#if>
    </table>
</div>
</body>
</html>
