# 总控台改造 Design

- 版本：2026-08-14-native-macos-launcher
- 状态：原生启动器已实现待发布验收
- 对应需求：CONSOLE-REQ-001, CONSOLE-REQ-002
- 最后更新：2026-08-14

## 1. 设计目标与约束

目标是让 Finder 双击 `.app` 产生确定的“启动/复用服务 → 健康确认 → 打开 Web”流程。保持零第三方运行时依赖、只绑定回环地址、完整项目目录运行和现有配置/日志位置。

## 2. 历史实现（改造前）

- `总控台.app/Contents/MacOS/launcher` 直接执行 `server.py --launcher`。
- `server.py` 已通过 `open` 命令等待健康接口后打开浏览器；旧的已有实例路径曾通过隐藏的 AppleScript 对话框等待选择，导致 Finder 双击看起来无反应。
- 已运行实例通过进程、cwd 和监听端口识别；页面 GitHub 链接仍指向原作者仓库。
- 本地 `origin` 已切换为用户仓库，改造分支从用户仓库 `main` 创建。

## 3. 目标架构（To-Be）

新增项目根目录 `open-console.command` 作为统一 macOS 启动入口：

1. 解析自身所在项目根目录。
2. 通过 Python 启动器模式启动或复用总控台。
3. 从 `server.py` 的输出/进程状态确定端口，并轮询 `GET /api/health`。
4. 健康成功后调用 macOS `open` 打开首页。
5. 超时/异常时写入日志并通过 `osascript` 弹窗。

`.app` 改用 Swift/AppKit 原生可执行程序并作为普通程序坞应用保持运行。首次启动和程序坞 reopen 事件都调用统一的 `open-console.command`；首次脚本子进程承载长期 HTTP 服务，后续调用复用监听端口并打开控制页。现有 `start.command` 和直接运行 `server.py` 的兼容入口保持不变。

## 4. 项目与模块地图

| 路径/模块 | 职责 | 状态 |
| --- | --- | --- |
| `server.py` | 服务、健康接口、实例识别、启动器可调用函数 | 已实现 |
| `open-console.command` | Finder/终端统一入口 | 已实现 |
| `start.command` | 调试入口，转发到统一启动逻辑 | 已实现 |
| `native/macos/main.swift` | AppKit 生命周期、程序坞 reopen 和子进程管理 | 已实现 |
| `tools/build_macos_launcher.sh` | 通用 Mach-O 构建、ad-hoc 签名与制品一致性验证 | 已实现 |
| `总控台.app/Contents/MacOS/launcher` | 原生 Mach-O App 启动器 | 已实现 |
| `static/index.html` | 页面 GitHub 链接 | 已实现 |
| `tests/test_server.py` | 启动器行为测试 | 已实现 |
| `tests/test_frontend.py` | 前端与原生启动合同检查 | 已实现 |

## 5. 关键流程

### 流程 A：双击 `.app`

1. Finder 执行 App bundle 内原生 Mach-O launcher。
2. AppKit 进程解析项目根目录并调用 `open-console.command`。
3. Python launcher 检查同目录已有且正在监听的总控台实例；有则直接取其监听端口，无则启动 `server.py` 服务。是否为服务实例以同目录监听端口为准，不能仅凭 `--launcher` 参数排除。
4. 在端口范围内轮询 `/api/health`，成功后优先使用 Chrome 打开首页，失败再使用系统默认浏览器。
5. AppKit 进程禁用 macOS 自动终止和突然终止，并保持运行；脚本服务进程作为其子进程持续运行。失败则写日志并显示原生或现有错误提示。

### 流程 B：重复双击

1. Finder 双击已运行 App 或用户点击程序坞图标，LaunchServices 向单一 App 进程发送 reopen 事件。
2. App 再次调用统一脚本；脚本发现同项目且正在监听的实例。
3. 不弹出选择对话框，也不启动第二个服务；等待已有端口健康后打开该端口首页。

## 6. 接口与平台集成

| 接口 | 输入 | 输出 | 失败语义 |
| --- | --- | --- | --- |
| `GET /api/health` | localhost 端口 | JSON `ok/status` | HTTP 错误或超时继续重试，超过期限失败 |
| macOS `open` | 完整 `http://127.0.0.1:<port>/` URL | 浏览器打开页面 | 命令失败则记录并提示 |
| macOS `osascript` | 用户可读错误 | 系统弹窗 | 弹窗不可用时仍保留日志和非零退出码 |

## 7. 安全、隐私与权限

- 不向网络暴露监听端口；健康探测仅访问本机回环地址。
- 不把 shell token 或个人路径写入仓库；运行配置继续位于用户 Library 目录。
- 不按端口强杀未知进程；复用逻辑沿用当前用户/cwd/端口身份校验。
- 未签名 App 的 Gatekeeper 行为不由本次代码改变。

## 8. 错误、离线与恢复

- 端口未就绪：按短间隔重试至明确超时。
- 服务进程提前退出：读取并保留日志末尾，弹出包含日志路径的提示。
- 原生入口前置检查非零退出：捕获标准错误，追加到 `~/Library/Logs/总控台/console.log` 并显示原生警告框。
- 已有实例端口无法健康：不启动第二个副本，提示用户查看日志。
- 浏览器打开失败：服务仍保持运行，并提示用户可手动访问实际 URL。

## 9. 测试策略

- 单元测试：测试端口发现、健康 URL 构造、启动失败与复用分支。
- 合同测试：检查 App launcher、`start.command`、GitHub 链接和权限位。
- 集成 smoke test：启动真实服务，访问 `/api/health` 和首页，再清理进程。
- 发布检查：`make check`、`make test`、`make release-check`（若发布工具环境允许）。
- 原生制品检查：构建时嵌入 Swift 源码 SHA-256；临时重建确认可构建，并验证仓库 launcher 内源码哈希、双架构、macOS 12 deployment target 与 ad-hoc 签名。

## 10. 技术决策

| 决策 ID | 决定 | 理由 | 替代方案 | 状态 |
| --- | --- | --- | --- | --- |
| CONSOLE-DES-001 | 以健康接口作为浏览器打开前置条件 | 避免固定 sleep 导致空白页或竞态 | 仅 `sleep` 后 `open` | 已批准 |
| CONSOLE-DES-002 | `.app` 与 `.command` 共用启动行为 | 减少 Finder/终端路径分叉 | 维护两套脚本 | 已批准 |
| CONSOLE-DES-003 | 本次不做 Apple 签名公证 | 用户当前目标是本机双击可用，证书不在范围 | Developer ID 发布 | 已批准 |
| CONSOLE-DES-004 | 已有实例时直接打开，不使用交互对话框 | 后台 App 中 AppleScript 对话框可能不可见并阻塞 launcher | 保留重启/取消选择框 | 已验收 |
| CONSOLE-DES-005 | 使用禁用自动终止的单实例 Swift/AppKit 启动器处理首次启动和程序坞 reopen | shell 可执行程序会被 Finder 很快判定退出；无窗口 App 也可能被系统自动终止，需显式禁用；原生 App 生命周期可稳定承载服务并响应重复点击 | shell App、一次性 App + launchd 后台服务 | 用户已批准，进行中 |

## 11. 已知限制与候选演进

未签名 App 在其他 Mac 上仍可能需要右键打开或系统设置授权；未来可增加 Developer ID 签名、公证和 DMG 发布，但需用户另行提供证书与批准范围。

## 12. 变更记录

| 日期 | 版本 | 变更 | 关联需求/任务 |
| --- | --- | --- | --- |
| 2026-08-13 | 2026-08-13-launch-flow | 建立统一启动器和 GitHub 归属设计 | REQ-001/002 |
