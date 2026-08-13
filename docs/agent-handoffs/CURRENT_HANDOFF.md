# 当前交接单

- 项目根目录：`/Users/VazeniF/Desktop/工作台/local-ops`
- 当前分支：`codex/local-ops-launch-flow`
- 基线：用户仓库 `origin/main`，基线 commit `a5c3ada`
- 当前所有者：Codex
- 当前任务：`CONSOLE-TASK-002`
- 精确工作范围：`tests/test_server.py`、`tests/test_frontend.py`
- 禁改范围：用户 Library 运行数据、日志、密钥、未授权业务规则
- 已完成：远程切换、规格文档、设计稿和执行计划
- 下一步：只写失败测试并运行 RED 验证，再修改启动器代码
- 验收命令：`make test`、`make check`、真实 localhost health smoke test

## 交接规则

- 修改前先确认 `git status` 和当前任务文件范围。
- 每次完成、交出或阻塞都追加 `AGENT_ACTIVITY_LOG.md`。
- 只有用户批准才能改变需求、架构或价格行为规则；本次不改变业务规则。
