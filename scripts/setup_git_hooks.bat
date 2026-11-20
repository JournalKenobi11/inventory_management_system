@echo off
rem scripts/setup_git_hooks.bat
rem Configures Git to use version-controlled .githooks directory

git config core.hooksPath .githooks
echo Git hooks configured successfully! Pre-commit checks are now active.
