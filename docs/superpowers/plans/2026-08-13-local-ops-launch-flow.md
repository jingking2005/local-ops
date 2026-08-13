# Local Ops Launch Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the macOS App reliably open the local Web console after the service is healthy, while aligning the UI link and Git remote with the user's GitHub repository.

**Architecture:** Keep the existing Python standard-library server and add one tested launcher path that discovers or starts the console, polls `/api/health`, then opens the browser. The App bundle and `start.command` delegate to that path; the frontend keeps a static GitHub link pointing to the user's repository.

**Tech Stack:** Python 3.12+, macOS shell/AppleScript/open, native HTML/JavaScript, unittest, Git/GitHub CLI.

## Global Constraints

- Keep the server bound to `127.0.0.1`.
- Do not add third-party runtime dependencies.
- Do not commit tokens, user config, logs, or runtime data.
- Do not change business behavior outside launcher UX and repository ownership.
- Preserve ports 9600-9609 and existing `server.py`, `start.command`, and App bundle entry points.

---

### Task 1: Lock launcher and link behavior with tests

**Files:**
- Modify: `tests/test_server.py`
- Modify: `tests/test_frontend.py`

**Interfaces:**
- Tests consume launcher helper functions exposed by `server.py` and static source files.
- Tests produce executable evidence for health polling, URL creation, failure reporting, and GitHub ownership.

- [ ] **Step 1: Write failing tests** for health URL construction, bounded health polling, and the target GitHub URL in the page.
- [ ] **Step 2: Run `python3 -m unittest tests.test_server tests.test_frontend -v` and confirm the new expectations fail because the helpers/link are missing or still point at the old repository.
- [ ] **Step 3: Keep the assertions platform-safe by mocking network/open calls and inspecting only repository-owned static files.

### Task 2: Implement the unified launcher

**Files:**
- Modify: `server.py`
- Modify: `start.command`
- Modify: `总控台.app/Contents/MacOS/launcher`
- Create: `open-console.command`

**Interfaces:**
- `server.py` exposes a bounded health-wait helper used by launcher mode.
- Launcher mode starts/reuses the service, resolves its port, waits for `/api/health`, calls `open` with the complete root URL, and reports failures through existing log/alert mechanisms.

- [ ] **Step 1:** Add the minimum implementation required by the failing tests.
- [ ] **Step 2:** Make `start.command` and the App launcher invoke the same project-root launcher behavior.
- [ ] **Step 3:** Ensure an already-running console is reused without spawning a duplicate.
- [ ] **Step 4:** Run the focused launcher tests and confirm they pass.

### Task 3: Align repository link and documentation

**Files:**
- Modify: `static/index.html`
- Modify: `README.md`
- Modify: `AGENTS.md`

**Interfaces:**
- The page GitHub anchor points to `https://github.com/jingking2005/local-ops`.
- Documentation describes the user repository and the reliable double-click flow without promising Gatekeeper bypass.

- [ ] **Step 1:** Replace the old repository URL and update launch instructions.
- [ ] **Step 2:** Run frontend contract checks and search for stale `laogou717/local-ops` references.

### Task 4: Verify, publish, and merge

**Files:**
- Modify: `spec/tasks.md`, `PROJECT_STATUS.md`, `docs/agent-handoffs/CURRENT_HANDOFF.md`, `docs/agent-handoffs/AGENT_ACTIVITY_LOG.md`

- [ ] **Step 1:** Run `make test`.
- [ ] **Step 2:** Run `make check` and relevant release checks.
- [ ] **Step 3:** Run a real local smoke test: launch the App/launcher, poll `/api/health`, fetch `/`, and stop only the console process started by the test.
- [ ] **Step 4:** Inspect `git diff` and stage only scoped files.
- [ ] **Step 5:** Commit with `feat: make macOS launcher open console`.
- [ ] **Step 6:** Push `codex/local-ops-launch-flow`, merge it into local `main`, and push `main` to `origin`.
- [ ] **Step 7:** Verify `origin/main` contains the commit and the GitHub URL/remote are correct.
