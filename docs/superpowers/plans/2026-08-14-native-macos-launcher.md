# Native macOS Launcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the shell executable inside `总控台.app` with a reproducible Swift/AppKit launcher that survives Finder launch, starts or reuses the console, and responds to Dock reopen events.

**Architecture:** A small AppKit process remains alive without a business window and launches the existing `open-console.command` on initial launch and reopen. The existing Python launcher remains the service authority for locking, health checks, logging, and browser opening.

**Tech Stack:** Swift 6, AppKit, Bash build tooling, Python `unittest`, macOS LaunchServices.

## Global Constraints

- Minimum supported system is macOS 12.
- Runtime continues to bind only to `127.0.0.1` and ports `9600-9609`.
- No third-party runtime dependency, Developer ID signing, notarization, DMG, or installer.
- Do not modify user data under `~/Library/Application Support/总控台` or logs under `~/Library/Logs/总控台`.
- Preserve `open-console.command`, `start.command`, and direct `python3 server.py` compatibility.
- Preserve the untracked user-owned `工作台.app` directory.

---

### Task 1: Lock the native App contract with failing tests

**Files:**
- Modify: `tests/test_frontend.py`
- Modify: `tools/check_project.py`

**Interfaces:**
- Consumes: `总控台.app/Contents/Info.plist`, `总控台.app/Contents/MacOS/launcher`.
- Produces: automated contract that requires a Mach-O launcher, visible Dock app, and single-instance reopen behavior.

- [ ] **Step 1: Replace the shell-source assertion**

Update the launcher contract to assert that `native/macos/main.swift` and `tools/build_macos_launcher.sh` exist, `launcher` starts with a Mach-O magic value, and `Info.plist` has `LSMultipleInstancesProhibited=true` and `LSUIElement=false`.

- [ ] **Step 2: Run the focused tests and observe RED**

Run: `python3 -m unittest tests.test_frontend.FrontendAccessibilityContractTests -v`

Expected: FAIL because the current launcher is a Bash script and the native source/build script do not exist.

- [ ] **Step 3: Update the project checker contract**

Change `check_shell_and_plist()` so Bash syntax is checked only for `start.command` and `open-console.command`; validate `launcher` by executable permission and Mach-O magic instead.

### Task 2: Implement and build the AppKit launcher

**Files:**
- Create: `native/macos/main.swift`
- Create: `tools/build_macos_launcher.sh`
- Replace: `总控台.app/Contents/MacOS/launcher`
- Modify: `总控台.app/Contents/Info.plist`

**Interfaces:**
- Consumes: project-relative `open-console.command` executable.
- Produces: `LauncherAppDelegate.runEntrypoint()`, initial launch behavior, Dock reopen behavior, child process cleanup, universal Mach-O executable.

- [ ] **Step 1: Implement the minimal AppKit lifecycle**

Create an `NSApplicationDelegate` that resolves the project directory as three parents above `Bundle.main.bundleURL`, calls `/bin/bash <project>/open-console.command` on `applicationDidFinishLaunching` and `applicationShouldHandleReopen`, tracks running `Process` objects, and terminates owned processes in `applicationWillTerminate`.

- [ ] **Step 2: Add a reproducible universal build script**

Compile `native/macos/main.swift` for `arm64-apple-macos12.0` and `x86_64-apple-macos12.0`, combine with `lipo`, set executable permission, ad-hoc sign the binary, and validate both architectures with `lipo -archs`.

- [ ] **Step 3: Configure the App as a visible single instance**

Set `LSMultipleInstancesProhibited=true` and `LSUIElement=false`. Keep `CFBundleExecutable=launcher`, bundle ID `local.laogou.console`, and minimum macOS `12.0`.

- [ ] **Step 4: Build and run focused checks**

Run: `tools/build_macos_launcher.sh`

Run: `python3 -m unittest tests.test_frontend.FrontendAccessibilityContractTests tests.test_server.LauncherTests -v`

Expected: PASS; `file 总控台.app/Contents/MacOS/launcher` reports a universal Mach-O executable.

### Task 3: Preserve Python reuse and browser behavior

**Files:**
- Modify: `server.py`
- Modify: `tests/test_server.py`

**Interfaces:**
- Consumes: listener discovery from `find_console_instances()` and URLs from `console_url(port)`.
- Produces: legacy `server.py --launcher` listeners remain discoverable; browser open prefers Google Chrome and falls back to the default handler.

- [ ] **Step 1: Run the already-written regression tests**

Run: `python3 -m unittest tests.test_server.LauncherTests tests.test_server.ConsoleRestartTests.test_instance_discovery_is_limited_to_same_project -v`

Expected: PASS for listener discovery, existing-instance reuse, Chrome preference, and default-browser fallback.

- [ ] **Step 2: Keep only changes required by those tests**

Retain the listening-port-based instance rule and Chrome fallback. Remove any abandoned launchd/background-server helpers and tests.

### Task 4: Finder, Dock, and release verification

**Files:**
- Modify: `spec/design.md`
- Modify: `spec/tasks.md`
- Modify: `PROJECT_STATUS.md`
- Modify: `docs/agent-handoffs/CURRENT_HANDOFF.md`
- Modify: `docs/agent-handoffs/AGENT_ACTIVITY_LOG.md`

**Interfaces:**
- Consumes: built App bundle and running localhost service.
- Produces: verification evidence, accepted status, Git commits, and remote `main` update.

- [ ] **Step 1: Run complete automated verification**

Run: `python3 -m unittest discover -s tests -p 'test_*.py' -v`

Run: `make check`

Expected: all tests and project checks pass.

- [ ] **Step 2: Verify a true cold Finder launch**

Stop only the verified console PID from this project, double-click `总控台.app` through Finder UI, then verify `/api/health`, one `9600` listener, a running native `launcher` process, and Chrome on the console page.

- [ ] **Step 3: Verify reopen behavior**

With the service running, double-click the App again and click its Dock icon. Verify Chrome is brought to the console and the listener PID remains unchanged.

- [ ] **Step 4: Run release verification**

Run: `make release-check`

Expected: release checks pass; any existing `REVIEW_REQUIRED` asset reminder is reported without being misrepresented as a code failure.

- [ ] **Step 5: Commit and push**

Stage only the approved launcher, tests, specs, status, and handoff files. Commit implementation and final acceptance separately, push `main`, and verify `git ls-remote origin refs/heads/main` matches local HEAD.
