# 项目状态

- 项目：总控台（local-ops）
- 当前阶段：Finder 双击启动器根因修复中
- 当前分支：`main`
- 当前任务：CONSOLE-TASK-006 原生 macOS 启动器
- 规则/版本：现有业务规则不变；启动流程设计版本 `2026-08-13-launch-flow`

## 已完成

- 已确认用户 GitHub 仓库 `https://github.com/jingking2005/local-ops` 可访问。
- 本地 `origin` 已切换到用户仓库。
- 已建立本次改造的需求、设计、任务范围和交接记录。

## 进行中

- 已通过 Finder 真实双击复现 shell App 被启动后约 0.1 秒退出；用户已批准改用 Swift/AppKit 原生启动器，设计与实施计划已建立。

## 下一步

- 按 TDD 实现原生 AppKit launcher，构建通用 Mach-O，再用 Finder 和程序坞真实复验。

## 阻塞项

- 无代码实现阻塞。
- 未签名 App 的 Gatekeeper 首次授权仍是 macOS 系统行为，不在源码可控范围内。

## 变更日志

2026-08-13 09:20 +0800 | Codex
- 修改：切换本地 GitHub origin 到 `jingking2005/local-ops`，建立 `codex/local-ops-launch-flow` 分支，写入本次改造事实源。
- 验证：`git fetch origin --prune` 成功；远程 `main` 可见。
- 下一步：建立启动器回归测试并实现健康等待打开流程。

2026-08-13 09:25 +0800 | Codex
- 修改：完成 SPEC 三件套、设计稿、执行计划和交接记录自检。
- 验证：检查文档结构、状态和占位符扫描通过。
- 下一步：执行启动器测试的 RED 阶段。

2026-08-13 09:40 +0800 | Codex
- 修改：新增健康等待与 macOS `open` 启动逻辑，统一 `.app`、`start.command`、`open-console.command`，更新用户 GitHub 链接和文档。
- 验证：RED 阶段按预期失败；随后 `python3 -m unittest discover -s tests -p 'test_*.py' -v` 通过 165 项。
- 下一步：执行真实启动、项目检查和发布合并。

2026-08-13 09:45 +0800 | Codex
- 修改：将交接单中的本机绝对路径改为运行时解析命令，避免发布扫描把工作区路径当作敏感信息。
- 验证：真实 App smoke test 通过；发布检查待重跑。
- 下一步：完成发布检查后提交并推送。

2026-08-13 10:05 +0800 | Codex
- 修改：完成 `main` 合并、远程推送和验收状态同步。
- 验证：`make release-check` 通过 15 项检查、165 个测试；本地与远程 `main` 均为 `3643e9f`；工作区干净。
- 下一步：修复实际双击时已有实例分支的隐藏对话框阻塞。

2026-08-13 10:30 +0800 | Codex
- 修改：修复启动器把 `server.py --launcher` 自身识别为总控台实例的问题；已有健康实例时直接打开控制页，不再调用隐藏的交互对话框；同步修正回归测试。
- 验证：聚焦启动器测试 5 项通过；完整 `unittest` 通过 166 项；`make check` 通过 13 项；真实 `open 总控台.app` 保持已有 `127.0.0.1:9600` 服务健康且未产生隐藏对话框。
- 下一步：本次修复已提交为 `51b219c` 并推送到远程 `main`。
