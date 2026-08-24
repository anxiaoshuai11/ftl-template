# 短信 H5 合并小票 · OKR 材料索引（飞书粘贴稿）

> 用途：粘到**前端飞书 / 样板间**索引页。  
> 原因：`./KR1-xxx.md` 这类相对路径只在本地仓库有效，飞书文档**不会**解析，必须换成 `https://….feishu.cn/wiki/…` 或 `…/docx/…` 云文档链接。

---

## 使用前（约 5 分钟）

1. 在样板间目录下**各新建一篇**飞书文档（或 Wiki 子页面），标题建议：
   - `KR1 · 短信 H5 合并小票 · 可复用案例`
   - `KR2 · 短信 H5 合并小票 · 实践文档`
   - `KR3 · 短信 H5 合并小票 · 效率基线报告`
2. 把本地 `KR1-可复用案例.md` / `KR2-实践文档.md` / `KR3-效率基线报告.md` **正文粘进去**（表格可保留；代码块可保留）。
3. 打开每篇文档 → 右上角「分享 / 复制链接」→ 换成下方表格里的占位符。
4. 代码附件：把 `h5-sms-ticket-template.ftl`、`demo-merged-ticket.json` 上传为飞书云文件或挂在 Wiki 附件，再把链接填进「代码与数据」。

粘贴索引正文时：**不要**再贴 `[文案](./xxx.md)`；只保留已替换好的完整 `https://` 链接。

---

## ↓↓↓ 以下复制到飞书 ↓↓↓

**短信 H5 合并小票 · OKR 材料索引**

对应 OKR **O2**：完成前端 AI 样板间核心能力落地，支撑组内规范沉淀与效率基线测算（截止 09-30）

三个 KR 已拆成独立文档，请分别打开：

| KR | 文档 | 一句话 |
|----|------|--------|
| KR1 | 【粘贴：KR1 飞书文档链接】 | 可运行案例包（FTL + Demo JSON + 字段对照） |
| KR2 | 【粘贴：KR2 飞书文档链接】 | 组内默认标准（流程 / 提示词 / Checklist） |
| KR3 | 【粘贴：KR3 飞书文档链接】 | 指标定义 + 采集表 + 初版基线结论 |

业务需求（已有 wiki，可直接点）：[订单短信/邮件小票样式优化](https://zath6evqnvz.feishu.cn/wiki/KOokwhaejicNWpkVyG9c5618n8b)

代码与数据：

- 【粘贴：h5-sms-ticket-template.ftl 云文件链接】（本地文件名：`h5-sms-ticket-template.ftl`）
- 【粘贴：demo-merged-ticket.json 云文件链接】（本地文件名：`demo-merged-ticket.json`）
- 本地预览（可选附件）：`h5-sms-ticket-template.preview.html`

grill-me 文件上下文（同 tip-pool 结构）：

- 【粘贴：h5-sms-ticket-merge 文件夹或说明页链接】：含 `spec.md` + `adr/` + `specs/`
- 【粘贴：grill-me-conversation 飞书文档链接】：完整问答对话

**复用最小步骤（同事照做）：**

1. 打开 KR1 文档，下载 FTL + Demo JSON  
2. 用组内 FreeMarker 渲染入口或本地打开 preview.html  
3. 改字段先改 JSON，再改 FTL 的 `#if` / `#list`  
4. 提示词见 KR2「可复用 AI 提示词」

## ↑↑↑ 以上复制到飞书 ↑↑↑

---

## 链接登记表（填完后回写本地，避免再丢）

| 材料 | 飞书链接 |
|------|----------|
| 索引页（本文所在页） | |
| KR1 | |
| KR2 | |
| KR3 | |
| FTL 附件 | |
| Demo JSON 附件 | |
| grill-me 对话 | |

填好后可把链接同步回 `OKR-样板间材料.md` 的「飞书云文档」一节。
