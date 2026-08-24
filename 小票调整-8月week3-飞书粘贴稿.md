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

# 三、新增 / 约定 JSON 字段

## 1. 金额汇总行（仍在 orderAmountInfo）

税相关汇总行增加标记 `showDetailIcon`（有弹层明细时为 true）：

```json
{
  "content": ["Taxes & Fees", "$27.04"],
  "fontSize": 14,
  "bold": 400,
  "showDetailIcon": true
}
```

Total 行可选：

```json
{
  "content": ["Total", "$44.54"],
  "fontSize": 22,
  "bold": 700,
  "isTotal": true
}
```

## 2. 新增弹层块 taxFeeDetailInfo

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

# 四、兼容

- 历史数据无 `taxFeeDetailInfo`：不显示 i
- `orderNumber` 兼容字符串与 `{ "content": [] }`
- 打印侧 `ticketConfig` 本期不动

# 五、单头胶囊（约定）

- 有桌台：只显示 `diningOption`（如 Dine In），不拼桌台号
- OO（`orderChannel=1`）且无桌台有取餐码：`diningOption / confirmationNumber`
- 不显示下单渠道
