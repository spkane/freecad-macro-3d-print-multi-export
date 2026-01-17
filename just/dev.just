# Development utility commands
# Usage: just dev::clean, just dev::install-pre-commit, etc.

# Project root directory (justfile_directory() returns the main justfile's directory)
project_root := justfile_directory()

# =============================================================================
# Setup & Dependencies
# =============================================================================

# Install pre-commit hooks (for git commit/push integration)
install-pre-commit:
    cd {{project_root}} && pre-commit install
    cd {{project_root}} && pre-commit install --hook-type commit-msg
    @echo "Pre-commit hooks installed!"

# Update all dependencies (mise tools, pre-commit hooks)
update-deps:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{project_root}}"

    echo "Updating mise-managed tools..."
    mise upgrade
    echo ""

    echo "Updating pre-commit hooks..."
    pre-commit autoupdate

    echo ""
    echo "All dependencies updated!"
    echo "  - mise tools: updated (see .mise.toml)"
    echo "  - pre-commit hooks: updated (see .pre-commit-config.yaml)"

# =============================================================================
# Development Utilities
# =============================================================================

# Clean build artifacts and caches
clean:
    rm -rf {{project_root}}/.pytest_cache {{project_root}}/.mypy_cache {{project_root}}/.ruff_cache
    find {{project_root}} -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
    find {{project_root}} -type f -name "*.pyc" -delete 2>/dev/null || true

# Show project structure (tree view, requires 'tree' command)
tree:
    #!/usr/bin/env bash
    if ! command -v tree &> /dev/null; then
        echo "The 'tree' command is not installed."
        echo "Install it with: brew install tree (macOS) or apt install tree (Linux)"
        exit 1
    fi
    cd "{{project_root}}" && tree -I '__pycache__|*.egg-info|.git|.mypy_cache|.pytest_cache|.ruff_cache' -a
