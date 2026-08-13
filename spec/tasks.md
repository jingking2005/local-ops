# 总控台改造 Tasks

- 对应需求版本：2026-08-13-launch-flow
- 对应设计版本：2026-08-13-launch-flow
- 最后更新：2026-08-13

## 1. 状态说明

- `待办`：已经批准、尚未开始；
- `进行中`：已认领，写明 Agent 和文件范围；
- `阻塞`：写明阻塞条件和恢复方式；
- `完成`：验收通过并记录证据；
- `候选`：尚未获得用户批准，禁止实现。

## 2. 当前交接摘要

- 当前分支：`main`
- 工作区状态：真实 Finder 双击问题复现，修复进行中
- 当前任务：CONSOLE-TASK-006
- 下一任务：无
- 不能触碰：用户 Library 下的运行配置、日志和图标；不得提交密钥
- 已知问题：shell 可执行程序被 Finder 很快判定退出并回收进程链；已批准改用原生 AppKit 启动器

## 3. 任务列表

### CONSOLE-TASK-001 建立事实源并连接用户仓库

- 状态：完成
- 所有者：Codex
- 对应需求：CONSOLE-REQ-001, CONSOLE-REQ-002
- 对应设计：第 1、2、3、10 节
- 依赖：无
- 文件范围：`spec/`、`PROJECT_STATUS.md`、`docs/agent-handoffs/`、`docs/superpowers/specs/`、`docs/superpowers/plans/`
- 验收条件：
  1. 三件套、设计文档、计划和交接状态存在。
  2. `origin` 指向 `jingking2005/local-ops`。
  3. 已在当前分支完成文档自检，无占位符或范围冲突。

### CONSOLE-TASK-002 启动器回归测试

- 状态：完成
- 所有者：Codex
- 对应需求：CONSOLE-REQ-001
- 对应设计：第 5、6、9 节
- 依赖：CONSOLE-TASK-001
- 文件范围：`tests/test_server.py`、`tests/test_frontend.py`
- 验收条件：先出现预期失败，再由实现使测试通过；已验证 5 个启动器测试和 2 个前端合同测试。

### CONSOLE-TASK-003 统一启动实现

- 状态：完成
- 所有者：Codex
- 对应需求：CONSOLE-REQ-001
- 对应设计：第 3、5、7、8 节
- 依赖：CONSOLE-TASK-002
- 文件范围：`server.py`、`open-console.command`、`start.command`、`总控台.app/Contents/MacOS/launcher`
- 验收条件：健康成功后打开首页；已有实例直接复用且不弹隐藏对话框；launcher 自身不被识别为实例；失败弹窗和日志可追溯；统一入口已被 `.app` 和脚本调用。

### CONSOLE-TASK-004 GitHub 链接和项目文档同步

- 状态：完成
- 所有者：Codex
- 对应需求：CONSOLE-REQ-002
- 对应设计：第 4、10 节
- 依赖：CONSOLE-TASK-001
- 文件范围：`static/index.html`、`README.md`、`AGENTS.md`
- 验收条件：页面链接、文档仓库归属和本地 remote 一致；已搜索并清除生产文件中的旧 GitHub URL。

### CONSOLE-TASK-005 验证、提交、推送和合并

- 状态：完成
- 所有者：Codex
- 对应需求：CONSOLE-REQ-001, CONSOLE-REQ-002
- 对应设计：第 9 节
- 依赖：CONSOLE-TASK-003、CONSOLE-TASK-004
- 文件范围：所有本次任务已修改文件
- 验收条件：完整测试通过；提交推送到用户仓库；改造合并到远程 `main`；远程 `main` 包含本次修复 commit。

### CONSOLE-TASK-006 原生 macOS 启动器

- 状态：进行中
- 所有者：Codex
- 对应需求：CONSOLE-REQ-001
- 对应设计：CONSOLE-DES-005、`docs/superpowers/specs/2026-08-14-native-macos-launcher-design.md`
- 依赖：CONSOLE-TASK-005
- 文件范围：`native/macos/main.swift`、`tools/build_macos_launcher.sh`、`server.py`、`总控台.app/Contents/`、`tests/test_server.py`、`tests/test_frontend.py`、`tools/check_project.py`、`spec/design.md`、`spec/tasks.md`、`PROJECT_STATUS.md`、`docs/agent-handoffs/`
- 禁改范围：业务功能、用户 Library 运行数据、端口安全边界
- 验收条件：先以失败测试复现；Finder 真实双击可启动并打开控制页；重复双击或程序坞点击不启动第二个服务；原生 App 进程保持运行；完整测试和发布检查通过。
