# 当前交接单

- 项目根目录：在仓库内运行 `git rev-parse --show-toplevel` 获取（不把本机绝对路径写入发布文件）
- 当前分支：`main`
- 基线：用户仓库 `origin/main`，验收 commit `3643e9f`；本次修复基于该 commit
- 当前所有者：Codex
- 当前任务：CONSOLE-TASK-006 原生 macOS 启动器
- 精确工作范围：`native/macos/main.swift`、`tools/build_macos_launcher.sh`、`server.py`、`总控台.app/Contents/`、`tests/test_server.py`、`tests/test_frontend.py`、`tools/check_project.py`、SPEC/状态/交接文件
- 禁改范围：用户 Library 运行数据、日志、密钥、未授权业务规则
- 已完成：Finder 真实复现、根因确认、原生方案用户批准、设计文档和实施计划建立
- 下一步：原生启动器 RED 测试、Swift 实现与构建、完整回归、Finder/程序坞复验、提交推送
- 已知验证：终端脚本可用但 shell App 被 Finder 很快回收；本机 Swift 6.2.3 和 Command Line Tools 可用
- 验收命令：`make test`、`make check`、真实 localhost health smoke test

## 交接规则

- 修改前先确认 `git status` 和当前任务文件范围。
- 每次完成、交出或阻塞都追加 `AGENT_ACTIVITY_LOG.md`。
- 只有用户批准才能改变需求、架构或价格行为规则；本次不改变业务规则。
