# Local Ops 双击启动与 GitHub 归属设计

## 已批准目标

用户在 macOS Finder 双击 `总控台.app` 后，无需终端即可启动或复用总控台服务，等待本地健康接口确认可用，再打开完整 Web 控制页；页面 GitHub 图标和本地 Git 远程统一指向 `jingking2005/local-ops`。

## 方案

统一启动逻辑负责项目根目录解析、已有实例复用、服务启动、健康轮询、浏览器打开和失败提示。`.app` 的后台 launcher 与 `start.command` 使用同一套逻辑，避免 Finder 环境和终端环境分叉。健康探测只访问 `127.0.0.1`，不改变现有安全边界。

## 验证

- 单元/合同测试覆盖健康等待、已有实例复用、启动失败和 GitHub 链接。
- `make test`、`make check` 和真实启动 smoke test 必须通过。
- Finder 双击验证要求浏览器出现 `http://127.0.0.1:<port>/`，并能读取 `/api/health`。

## 限制

本次不做 Apple Developer ID 签名、公证或 DMG 分发。未签名 App 在新 Mac 上仍可能需要一次系统授权；这是 Gatekeeper 行为，不是项目启动逻辑。
