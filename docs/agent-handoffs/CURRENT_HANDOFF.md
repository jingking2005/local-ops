# 当前交接单

- 项目根目录：在仓库内运行 `git rev-parse --show-toplevel` 获取（不把本机绝对路径写入发布文件）
- 当前分支：`main`
- 基线：用户仓库 `origin/main`，原生设计 commit `04afcfe`
- 当前所有者：Codex
- 当前任务：CONSOLE-TASK-006 原生 macOS 启动器
- 精确工作范围：`native/macos/main.swift`、`tools/build_macos_launcher.sh`、`server.py`、`总控台.app/Contents/`、`tests/test_server.py`、`tests/test_frontend.py`、`tools/check_project.py`、SPEC/状态/交接文件
- 禁改范围：用户 Library 运行数据、日志、密钥、未授权业务规则
- 已完成：原生 launcher RED/GREEN、通用 Mach-O 构建与签名、Python 复用修复、完整回归、Finder 双击与重复双击实测
- 下一步：提交实现，在干净 Git 边界执行 `make release-check`，更新最终验收状态并推送 `main`
- 已知验证：最终二进制经 Finder 启动 39 秒后 App PID `32277`/服务 PID `32280` 不变；重复双击仍各一个进程和一个 9600 监听；Chrome 显示控制页；独立代码复审通过
- 验收命令：`python3 -m unittest discover -s tests -p 'test_*.py' -v`（170 项）、`make check`（14 项，含 7 个 JS 测试与原生制品校验）、`make release-check`

## 交接规则

- 修改前先确认 `git status` 和当前任务文件范围。
- 每次完成、交出或阻塞都追加 `AGENT_ACTIVITY_LOG.md`。
- 只有用户批准才能改变需求、架构或价格行为规则；本次不改变业务规则。
