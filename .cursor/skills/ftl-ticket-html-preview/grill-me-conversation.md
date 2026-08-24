# grill-me 完整问答对话

> 主题：在 DevTools 工具页新增「FTL → HTML」Tab（上传 FTL 实时预览样式）
> 状态：settled
> 日期：2026-08-21

> 权威副本：`/Users/anxiaoshuai/Desktop/工作/gsPro/browser-extend/grill-me-conversation.md`

## 锁定结论速查

| 项 | 结论 |
|----|------|
| 入口 | DevTools Tab：**`FTL小票预览`**（指令小票右侧） |
| 包 | `dev-tool-extension` + `front-dev-tool-extension` 同步 |
| 数据 | FTL 上传/粘贴；JSON 上传/粘贴/内置样例；storage 记住 JSON |
| 交互 | 自动刷新 + iframe 预览 + 下载 `xxx.preview.html` |
| 编辑 | 只改 FTL；交付仍是 FTL |
| 两档 | 样式预览（默认）+ 尽力求值；手写引擎，无第三方 FreeMarker |
| 范围 | HTML 小票 FTL；非 HTML 提示不支持 |

等用户说「开始做」再实现。
