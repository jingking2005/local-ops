# 总控台原生 macOS 启动器设计

- 日期：2026-08-14
- 状态：用户已批准
- 关联需求：`CONSOLE-REQ-001`
- 关联任务：`CONSOLE-TASK-006`

## 1. 目标

将 `总控台.app` 从以 shell 脚本充当可执行文件的 App bundle，改造成真正的 Swift/AppKit 应用。用户从 Finder 双击或从程序坞点击图标时，应用必须启动或复用本地总控台服务，并把 `http://127.0.0.1:9600/` 控制页带到前台。

## 2. 已确认根因

当前 App bundle 的 `CFBundleExecutable` 是 Bash 脚本。Finder/LaunchServices 启动该 App 后，会在约 0.1 秒内将 App 判定为退出，并可能回收由脚本拉起的进程链。相同脚本从终端运行正常，因此终端、`open <app>` 和 Python 单元测试均不能替代 Finder 真实双击验收。

此外，本机普通 `/usr/bin/open <url>` 曾返回成功但未将控制页带到前台；显式 `/usr/bin/open -a "Google Chrome" <url>` 能可靠打开。Python 入口保留“优先 Chrome、失败回退默认浏览器”的行为。

## 3. 目标架构

### 3.1 原生 App

- 使用 Swift 6 与 AppKit，最低系统版本 macOS 12。
- `总控台.app/Contents/MacOS/launcher` 是 Mach-O 可执行文件，不再是 shell 脚本。
- App 使用普通程序坞应用策略，保留图标和退出菜单，不创建业务窗口。
- App 明确关闭 macOS 自动终止与突然终止能力，避免无业务窗口时被系统回收。
- App 进程至少持续运行 30 秒并在用户主动退出前保持存在，负责承载其启动的 `open-console.command` 子进程。

### 3.2 启动与重开

- `applicationDidFinishLaunching`：调用项目根目录的 `open-console.command`。
- 脚本发现无实例时启动 `server.py --launcher`，健康后打开浏览器；该 Python 服务作为原生 App 子进程持续运行。
- `applicationShouldHandleReopen`：用户再次点击程序坞图标或双击 App 时，再运行一次统一脚本。脚本复用已有监听端口，只打开控制页，不启动第二个服务。
- 服务被控制页停止后，原生 App 继续存在；下一次点击图标会重新启动服务。

### 3.3 退出

- 用户退出原生 App 时，终止仍由该 App 持有的长期启动子进程。
- 外部启动、并非由 App 持有的总控台实例不由 App 强制结束。

## 4. 文件边界

| 文件 | 职责 |
| --- | --- |
| `native/macos/main.swift` | AppKit 生命周期、程序坞重开事件、脚本进程管理和错误提示 |
| `tools/build_macos_launcher.sh` | 用系统 Swift 工具链构建 App bundle 内 Mach-O 启动器 |
| `总控台.app/Contents/MacOS/launcher` | 构建后的原生可执行程序 |
| `总控台.app/Contents/Info.plist` | 普通程序坞 App、单实例重开、macOS 12 最低版本 |
| `open-console.command` | 统一的 Python 服务启动/复用入口，继续支持终端双击 |
| `server.py` | 服务实例识别、健康等待、优先 Chrome 打开并回退默认浏览器 |

## 5. 错误处理

- 找不到 `open-console.command`：原生系统警告框显示发行目录不完整。
- 无法运行脚本：系统警告框显示启动失败及底层错误。
- 原生启动器捕获脚本的标准错误；子进程非零退出时追加到 `~/Library/Logs/总控台/console.log` 并显示原生警告框。
- Python、健康检查和服务运行期日志继续由现有脚本与 `server.py` 报告。
- 原生启动器不得读取、修改或迁移用户业务配置。

## 6. 构建与发布

- 构建只依赖 macOS Command Line Tools 自带的 `xcrun swiftc`、`lipo` 和 `codesign`。
- 生成 arm64 与 x86_64 后合并为通用 Mach-O，最低目标 macOS 12。
- 构建脚本对可执行文件进行 ad-hoc 签名；Developer ID 签名和 Apple 公证仍不在本次范围。
- 源码、构建脚本和生成的 App 可执行文件一并提交，确保仓库克隆后可复现。
- 构建脚本把 Swift 源码 SHA-256 嵌入 Mach-O，并提供只读验证模式：在临时 App 副本中重建，同时验证仓库制品的源码哈希、双架构、最低系统版本和签名，防止源码与二进制漂移且不依赖不同 Swift 工具链生成完全相同的字节。

## 7. 验收

### 自动化

- Swift 源码可分别编译 arm64、x86_64，并合并为通用二进制。
- App launcher 是可执行 Mach-O，不能被 Bash 语法检查当成脚本。
- 原生构建验证可确认已提交二进制携带当前 Swift 源码哈希、签名有效且最低目标为 macOS 12。
- `Info.plist` 保持单实例并显示程序坞图标。
- Python 启动器回归、完整 166+ 测试、`make check` 与 `make release-check` 通过。

### 真实界面

1. 停止总控台后，从 Finder 双击 `总控台.app`，服务启动并打开控制页。
2. 服务运行时再次双击 App，或点击程序坞图标，控制页再次被带到前台且没有第二个监听服务。
3. App 进程在服务运行期间保持存在；首次启动 30 秒后仍是同一个 App 与服务 PID，Finder 不再记录快速退出。

## 8. 范围外

- 不修改 Web 控制台业务功能、数据模型、端口范围和回环绑定。
- 不制作 DMG、安装器、Developer ID 签名或公证发布包。
- 不自动把图标写入用户程序坞配置；用户可自行将原生 App 拖入程序坞。
