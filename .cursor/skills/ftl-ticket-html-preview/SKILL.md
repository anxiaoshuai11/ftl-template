---
name: ftl-ticket-html-preview
description: >-
  Converts POS/SMS FreeMarker ticket templates (.ftl) into a sibling static
  .preview.html so styles can be checked in a browser without deploying to the
  client. Use whenever creating, editing, merging, or generating ticket FTL
  files (order/trade/H5 receipt templates), or when the user asks to preview
  FTL styles, 实时看样式, or 转成 html.
---

# FTL 小票 → HTML 预览

小票 FTL 通常要进客户端/后端渲染才能看样式。本 skill 要求：**改 FTL 或新生成 FTL 时，必须同步产出可浏览器打开的 HTML 预览文件**。

## 何时必须执行

满足任一条件即执行：

- 新建 / 修改 / 合并 `*.ftl` 小票模版（订单、交易、短信 H5 等）
- 用户说：预览、看样式、转成 html、realtime preview、不用上客户端
- 同一次任务里刚写完 FTL

**不要**只交 FTL 不交预览 HTML。

## 产出约定

| 源文件 | 预览文件 |
|--------|----------|
| `foo.ftl` 或 `foo-template.ftl` | 同目录 `foo.preview.html` 或 `foo-template.preview.html` |
| 有 Demo JSON | 优先用同目录 `demo*.json` / `*-demo.json` / 用户指定 JSON 灌数 |
| 无 Demo JSON | 用 FTL 旁最小占位数据，并在 HTML 顶部注释标明「示例数据」 |

推荐命名（与本仓库一致）：

- `h5-sms-ticket-template.ftl` → `h5-sms-ticket-template.preview.html`
- Demo：`demo-merged-ticket.json`

## 转换规则（按优先级）

### 1) 能跑 FreeMarker 时（优先）

若环境有 Java + freemarker 可执行方式，用 Demo JSON 真实渲染 FTL，输出 HTML。

### 2) 不能跑引擎时（默认兜底，必须能完成）

Agent **手工/脚本展开** FTL 为静态 HTML：

1. 保留 FTL 里的 `<style>`、外层 `table/tr/td` 结构、弹层 JS
2. 去掉 `<#function>` / `<#assign>` / `<#if>` / `<#list>` / `${...}` 等指令
3. 按 Demo JSON **走与 FTL 相同的业务分支**（有则显、无则藏、胶囊规则、支付隐藏、Tax&Fee 弹层等）
4. 把最终可见文案写成纯 HTML 文本
5. 文件头加注释：

```html
<!--
  preview of: <ftl文件名>
  data: <json文件名或 inline>
  generated-by: ftl-ticket-html-preview skill
  note: 静态展开，非服务端 FreeMarker 渲染；改 FTL 后请重新生成本文件
-->
```

### 业务分支不要猜错

若项目有 `adr/` / `grill-me-conversation.md` / spec，预览必须遵守已锁定口径（例如胶囊不拼桌台、支付只用 tradeInfo、无 taxFeeDetailInfo 则无 `i`）。

无文档时：严格按当前 FTL 的 `#if` 条件对 Demo 数据求值。

## 工作流程（每次改 FTL）

```text
改/生成 xxx.ftl
  → 确认/更新 demo JSON（字段要对得上）
  → 生成/覆盖 xxx.preview.html
  → 回复用户：预览文件路径 + 「用浏览器打开即可看样式」
```

若只改了样式/结构、数据不变：仍要刷新 preview HTML。  
若用户只要改数据看效果：可只更新 JSON 再重生 preview。

## 质量要求

- 浏览器直接双击 / `open xxx.preview.html` 即可看，无构建步骤
- 手机宽小票：保持 FTL 的 max-width / viewport
- 弹层、虚线、左右栏对齐应与 FTL 意图一致
- 不要引入 Vue/React；预览就是静态 HTML
- 回复用中文，路径用 `/`，不要提 skill 内部实现细节过长

## 禁止

- 只改 FTL 却忘记更新 preview
- 把未展开的 `<#if>` / `${}` 留在 preview 里导致页面空白或原文暴露
- 为了预览去改客户端工程或要求用户部署
