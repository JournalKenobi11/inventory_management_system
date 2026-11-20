#!/usr/bin/env bash
# scripts/setup_git_hooks.sh
# Configures Git to use version-controlled .githooks directory

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
echo "Git hooks configured successfully! Pre-commit checks are now active."
