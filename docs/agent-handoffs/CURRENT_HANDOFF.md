# 当前交接单

- 项目根目录：在仓库内运行 `git rev-parse --show-toplevel` 获取（不把本机绝对路径写入发布文件）
- 当前分支：`codex/local-ops-launch-flow`
- 基线：用户仓库 `origin/main`，基线 commit `a5c3ada`
- 当前所有者：Codex
- 当前任务：`CONSOLE-TASK-005`
- 精确工作范围：所有本次改造文件，发布前仅修改状态文档
- 禁改范围：用户 Library 运行数据、日志、密钥、未授权业务规则
- 已完成：远程切换、规格文档、执行计划、RED/GREEN 测试、统一启动器和 GitHub 链接
- 下一步：真实 smoke test、`make check`、提交推送并合并 `main`
- 已知验证：`python3 -m unittest discover -s tests -p 'test_*.py' -v` 通过 165 项
- 验收命令：`make test`、`make check`、真实 localhost health smoke test

## 交接规则

- 修改前先确认 `git status` 和当前任务文件范围。
- 每次完成、交出或阻塞都追加 `AGENT_ACTIVITY_LOG.md`。
- 只有用户批准才能改变需求、架构或价格行为规则；本次不改变业务规则。
