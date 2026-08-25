# 小票调整-8月week3

> 粘贴说明：飞书里把「一、二、三…」设为**标题**；JSON 段用**代码块**。下面从「需求地址」开始复制即可。

---

需求地址：[订单短信/邮件小票样式优化](https://zath6evqnvz.feishu.cn/wiki/KOokwhaejicNWpkVyG9c5618n8b)

涉及小票：新增小票模版（合并订单小票 + 交易小票信息；结账短信短链打开的顾客 H5 页）

不改动：订单热敏小票、交易热敏小票打印模版

语言：仅英文

# 一、改动说明

1. 结账后短信短链打开一张 H5，合并展示：门店 / 单头 / 顾客 / 餐品 / 金额 / 支付
2. 金额区 Tax / Taxes & Fees / Fees 汇总 + 点击 i 看明细弹层（对齐订单详情 TaxesFeesLine）
3. 支付只用 `tradeInfo`，不做刷卡联
4. 打印侧 order / trade 热敏 FTL 本期不改

# 二、Taxes & Fees 规则（英文）

合并进汇总行 / 弹层：**税 + 商家服务费 + 平台费**

| 情况 | 汇总行文案 |
| --- | --- |
| 仅税 | Tax |
| 税 + 服务费/平台费 | Taxes & Fees |
| 仅服务费/平台费 | Fees |
| 都没有 | 不展示该行 |

- 弹层明细顺序：service → tax → platform
- 弹层合计 = 汇总行金额
- **Processing Fee（信用卡手续费）**：主票单独一行，**不进**弹层

# 三、字段取值口径（重要）

模版对所有文案字段统一按「先取 `content[0]`，取不到再当字符串」的顺序解析，因此三种形态都能正确渲染：

```json
"orderNumber": "#3"
"orderNumber": { "content": ["#3"] }
"orderNumber": Content 对象（未经 JSON 序列化，直接灌进模版）
```

适用字段：`orderNumber` / `diningOption` / `table` / `confirmationNumber` / `orderTime` / `server` / `taxFeeDetailInfo.title`

下发时请遵守两条：

1. **文案一律放在 `content` 数组里。** `content` 为空数组时模版渲染成空串，不会把对象内容暴露到页面上。
2. **时间字段必须下发已格式化好的门店本地时间。** 模版拿不到门店时区，不做任何时间转换，收到什么显示什么。
   目前 `customerInfo` 里的取餐/配送时间仍是 `Pickup / Delivery: 2026-08-24T08:51:42.680734Z` 这种 ISO UTC 原文，
   而同一张单的 `orderTime` 是 `08/24/2026 04:51 PM`，两者差 8 小时，**需按 `orderTime` 的方式统一处理**。

# 四、新增 / 约定 JSON 字段

## 1. 金额汇总行（仍在 orderAmountInfo）

税相关汇总行下发 `showDetailIcon`（有弹层明细时为 true）：

```json
{
  "content": ["Taxes & Fees", "$27.04"],
  "fontSize": 14,
  "bold": 400,
  "showDetailIcon": true
}
```

Total 行下发 `isTotal`：

```json
{
  "content": ["Total", "$44.54"],
  "fontSize": 22,
  "bold": 700,
  "isTotal": true
}
```

**这两个标记请务必下发。** 缺失时模版会退化成按行文案猜，两个方向都会猜错：

- 汇总行文案为 `Fees`（仅服务费/平台费）时不含 tax 字样，i 图标会漏显，弹层点不开
- `Subtotal` 文案里含 total 字样，会被当成总计行，字号放大到 22px 加粗

## 2. 弹层块 taxFeeDetailInfo

```json
{
  "taxFeeDetailInfo": {
    "block": {
      "lineSpace": 4
    },
    "title": "Taxes & Fees",
    "contentList": [
      {
        "content": ["Kiosk Fee (10%)", "$3.16"],
        "fontSize": 14,
        "bold": 400,
        "category": "service"
      },
      {
        "content": ["Tax1 (12%)", "$8.22"],
        "fontSize": 14,
        "bold": 400,
        "category": "tax"
      },
      {
        "content": ["OPF (10%)", "$3.16"],
        "fontSize": 14,
        "bold": 400,
        "category": "platform"
      }
    ]
  }
}
```

字段说明：

- `title`：弹层标题，与汇总行文案一致（Tax / Taxes & Fees / Fees）
- `contentList[].content[0]`：明细名称
- `contentList[].content[1]`：明细金额
- `category`：可选，`service` / `tax` / `platform`（后端排序自检用）
- 无 `taxFeeDetailInfo` 或列表为空：不显示 i、不渲染弹层

## 3. 支付（沿用 tradeInfo，无新增块名）

```json
{
  "tradeInfo": {
    "contentList": [
      { "content": ["Card(****9999)", "$42.00"], "fontSize": 14, "bold": 600 },
      { "content": ["Cash", "$2.54"], "fontSize": 14, "bold": 600 }
    ]
  }
}
```

无数据则 Payment 整块不渲染。

# 五、兼容

- 历史数据无 `taxFeeDetailInfo`：不显示 i
- 打印侧 `ticketConfig` 本期不动
- 顾客区 `customerInfo` 为空：整块不渲染

# 六、单头胶囊（约定）

- 有桌台：只显示 `diningOption`（如 Dine In），不拼桌台号
- OO（`orderChannel=1`）且无桌台有取餐码：`diningOption / confirmationNumber`
- 不显示下单渠道
