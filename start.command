#!/bin/bash
set -u
umask 077
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$PROJECT_DIR/open-console.command"
