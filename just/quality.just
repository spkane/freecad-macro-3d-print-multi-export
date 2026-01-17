# Code quality commands
# Usage: just quality::check, just quality::format, etc.
#
# Note: Tools installed via mise (gitleaks, markdownlint-cli2, etc.) use `mise exec`.

# Project root directory (justfile_directory() returns the main justfile's directory)
project_root := justfile_directory()

# Run all pre-commit checks
check:
    pre-commit run --all-files

# Format code with ruff
format:
    mise exec -- ruff format {{project_root}}/macros
    mise exec -- ruff check --fix {{project_root}}/macros

# Run linting
lint:
    mise exec -- ruff check {{project_root}}/macros

# Run type checking (via pre-commit mypy hook)
typecheck:
    @echo "Running type checking..."
    @pre-commit run mypy --all-files && echo "✓ Type checking passed" || echo "✗ Type checking found issues"

# Run security scanning (via pre-commit bandit hook)
security:
    @echo "Running security scan..."
    @pre-commit run bandit --all-files && echo "✓ Security scan passed" || echo "✗ Security scan found issues"

# Run spell checking
spellcheck:
    mise exec -- codespell --ignore-words {{project_root}}/.codespell-ignore-words.txt {{project_root}}/macros {{project_root}}/README.md

# =============================================================================
# Secrets Scanning (quality::scan-* commands)
# =============================================================================

# Run all secrets scanners
scan: scan-gitleaks scan-detect
    @echo "All secrets scans complete!"

# Run gitleaks secrets scanner (installed via mise)
scan-gitleaks:
    mise exec -- gitleaks detect --source {{project_root}} --config {{project_root}}/.gitleaks.toml --verbose

# Run gitleaks on git history
scan-gitleaks-history:
    mise exec -- gitleaks detect --source {{project_root}} --config {{project_root}}/.gitleaks.toml --verbose --log-opts="--all"

# Check for new secrets against baseline
scan-detect:
    @echo "Checking for new secrets against baseline..."
    @pre-commit run detect-secrets --all-files && echo "✓ No new secrets detected"

# Audit detect-secrets baseline (interactive)
scan-audit:
    detect-secrets audit {{project_root}}/.secrets.baseline

# Update detect-secrets baseline
scan-baseline-update:
    cd {{project_root}} && detect-secrets scan \
        --exclude-files '\.secrets\.baseline$$' \
        --exclude-files '\.gitleaks\.toml$$' \
        --update .secrets.baseline
    @echo "✓ Baseline updated (run 'just quality::scan-audit' to review any findings)"

# =============================================================================
# Markdown Linting
# =============================================================================

# Lint all markdown files (markdownlint-cli2 installed via mise)
markdown-lint:
    cd {{project_root}} && mise exec -- markdownlint-cli2 "**/*.md" "#.venv" "#.pytest_cache" "#node_modules"

# Lint and fix markdown files
markdown-fix:
    cd {{project_root}} && mise exec -- markdownlint-cli2 --fix "**/*.md" "#.venv" "#.pytest_cache" "#node_modules"
