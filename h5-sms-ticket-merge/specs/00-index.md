# 按交付切片拆分的改动 spec

Status: ready-for-agent

领域总 spec：[`../spec.md`](../spec.md)。ADR：`../adr/0001-*.md` … `0005-*.md`。

每个文件对应一个 **可独立交付/验收** 的切片。依赖顺序从上到下。

| 切片 | 端 | spec | 要做什么 |
|------|----|------|----------|
| h5-ftl-template | 前端模版 | [01](./01-h5-ftl-template.md) | 短信 H5 FTL：`table/tr/td`、六段模块、胶囊/支付/弹层规则 |
| demo-json-contract | 数据占位 | [02](./02-demo-json-contract.md) | 拼盘 Demo JSON + 字段契约与空数据约定 |
| okr-showroom-docs | 文档/OKR | [03](./03-okr-showroom-docs.md) | KR1 案例 / KR2 实践 / KR3 基线三份材料 |

**不在本期改：**

- `order-ticket-template(37).ftl` / `trade-ticket-template(54).ftl`：打印继续用，本需求不改语义。
- Admin / Kiosk / 平板 / KDS / OO 客户端 / 老板手机端。
- 新后端聚合接口（可后续）；本期只占位。

**测试缝：** Demo JSON 灌 FTL 静态预览 + 场景清单见总 spec Testing Decisions。
