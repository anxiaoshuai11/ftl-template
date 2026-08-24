# Tax&Fee 弹层用 taxFeeDetailInfo 占位，无数据则隐藏

金额区 Tax & Fee 行可展示 `i`；点击后原生 JS 弹层展示明细。明细数据块名为 `taxFeeDetailInfo`（contentList 左右文案）。若该块缺失或为空：**不显示 `i`，不渲染弹层 DOM**。

## 为什么

产品希望有图 1 右侧弹层。现有 `orderAmountInfo` 未必已拆好 Tax1/OPF 等行。新增占位不堵模版交付；有数据才交互，避免空弹层。

## 关键权衡（被否决的备选）

- **不做弹层，只显示一行合计**：被否决（产品要弹层）。
- **明细直接展开在金额区下方**：备选，但不如弹层贴设计。
- **明细写死在模版**：仅 Demo 可写示例数据，逻辑仍走 `#if` 数据驱动。

## 后果

- 后端需在后续灌 `taxFeeDetailInfo`；在此之前 H5 仍可上线（无 `i`）。
- 弹层用原生 JS，不引 jQuery。
- 可用 `showDetailIcon` 或 label 含 `tax` 决定哪一行出 `i`（需同时有明细数据）。
