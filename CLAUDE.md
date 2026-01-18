# CLAUDE.md - AI Assistant Guidelines for This Project

## Project Overview

This is a FreeCAD macro that exports selected objects to multiple file formats simultaneously. It supports 8 export formats (STL, STEP, 3MF, OBJ, IGES, BREP, PLY, AMF) with configurable mesh quality options.

### Critical: Python Version Must Match FreeCAD

**CRITICAL**: This project **MUST** use the same Python version that the current stable FreeCAD release bundles internally. FreeCAD embeds a specific Python version (e.g., `libpython3.11.dylib`), and using a different Python version causes **fatal crashes** due to ABI incompatibility.

Before changing the Python version in `.mise.toml` or `pyproject.toml`:

1. Check which Python version FreeCAD bundles:
   - macOS: `ls /Applications/FreeCAD.app/Contents/Resources/lib/libpython*`
   - Linux: `ls /usr/lib/freecad/lib/libpython*` or check FreeCAD's Python console
1. The Python minor version (e.g., 3.11) **must match exactly**
1. Using Python 3.12+ with FreeCAD that bundles Python 3.11 will crash

Current requirement: **Python 3.11** (matching FreeCAD 1.0.x bundled Python)

---

## Project Structure

```text
freecad-macro-3d-print-multi-export/
├── .github/workflows/        # CI/CD workflows
├── docs/                     # MkDocs documentation
├── just/                     # Just module files
├── macro/Multi_Export/       # Main macro source
│   ├── MultiExport.FCMacro   # Main macro file (GUI + entry point)
│   ├── multi_export_core.py  # Pure Python logic (no FreeCAD imports)
│   ├── multi_export_fc.py    # FreeCAD-dependent logic
│   └── __init__.py           # Package init
├── tests/
│   ├── unit/                 # pytest unit tests (no FreeCAD required)
│   ├── freecad/              # FreeCAD integration tests
│   └── just_commands/        # Just command tests
├── .pre-commit-config.yaml   # Pre-commit hooks
├── justfile                  # Task runner
├── mkdocs.yaml               # Documentation config
└── pyproject.toml            # Project configuration
```

---

## Macro Module Layout

### Why This Structure?

The macro is split into three layers to enable automated testing:

1. **multi_export_core.py** - Pure Python logic (format definitions, validation, filename sanitization). Testable with standard pytest - no FreeCAD installation required.

2. **multi_export_fc.py** - FreeCAD-dependent logic (export functions, shape handling, MultiExporter class). Testable inside FreeCAD using its test framework.

3. **MultiExport.FCMacro** - GUI dialog and entry point. Imports from modules when available, falls back to embedded definitions for standalone use.

### Why `__init__.py` is Required

The `__init__.py` file makes the macro directory a proper Python package. This is required for:

- **Import resolution**: Allows `from multi_export_core import ...` to work
- **Package metadata**: Defines `__version__`, `__author__`, etc.
- **Test discovery**: pytest can properly discover and import modules
- **Consistency**: Both macro repos use the same structure

### Standalone Macro Support

When users install just the `.FCMacro` file (without the module files), the macro still works because:

```python
# In MultiExport.FCMacro
_USE_MODULES = False
try:
    from multi_export_core import (
        EXPORT_FORMATS, ExportFormat, sanitize_filename, ...
    )
    from multi_export_fc import MultiExporter, export_shape, ...
    _USE_MODULES = True
except ImportError:
    pass

if not _USE_MODULES:
    # Fallback: embedded definitions
    @dataclass
    class ExportFormat:
        ...
```

This fallback pattern ensures the macro works in both scenarios:

- **Development/Full install**: Uses modular code (testable)
- **Standalone install**: Uses embedded definitions (works without modules)

---

## Development Environment Setup

### Required Tools (managed via `mise`)

This project uses [`mise`](https://mise.jdx.dev/) for local development tool management. All tool versions are pinned in `.mise.toml`.

```bash
# Install mise via the Official mise installer script (if not already installed)
curl https://mise.run | sh

# Install all project tools
mise install

# Activate mise in your shell (add to .bashrc/.zshrc)
eval "$(mise activate bash)"  # or zsh/fish
```

### Package Management

This project uses `pip` for Python dependencies (not `uv` like the MCP server).

```bash
# Install development dependencies
pip install -e ".[dev]"

# Install test dependencies
pip install -e ".[test]"

# Install documentation dependencies
pip install -e ".[docs]"
```

### Workflow Commands (via `just`)

This project uses [`just`](https://just.systems/) as a command runner.

```bash
# List all commands and modules
just
just list-all

# List commands in specific modules
just list-dev           # Development utilities
just list-documentation # Documentation commands
just list-install       # Installation commands
just list-quality       # Code quality commands
just list-release       # Release commands
just list-testing       # Test commands

# Common workflows
just setup              # Full dev setup (install pre-commit hooks)
just all                # Run all quality checks
just test               # Run unit tests
just test-cov           # Run unit tests with coverage

# Quality commands
just quality::check     # Run all pre-commit checks
just quality::format    # Format code with ruff
just quality::lint      # Run linting

# Testing commands
just testing::unit      # Run pytest unit tests
just testing::unit-cov  # Run with coverage
just testing::freecad   # Run FreeCAD integration tests

# Documentation commands
just documentation::build  # Build documentation
just documentation::serve  # Serve documentation locally
```

---

## Code Quality Standards

### Pre-commit Hooks

**CRITICAL**: This project uses `pre-commit` for all code quality checks. Before finishing ANY code changes:

1. Run `just quality::check` or `pre-commit run --all-files`
1. Fix ALL issues reported
1. Re-run until all checks pass

Pre-commit runs these checks:

**Python Quality:**

- **Ruff**: Linting and import sorting
- **Ruff Format**: Code formatting
- **Bandit**: Security vulnerability scanning (excludes tests)

**Secrets Detection:**

- **Gitleaks**: Fast regex-based secrets scanning
- **detect-secrets**: Baseline tracking for known/approved secrets

**Documentation & Config:**

- **Markdownlint**: Markdown linting with auto-fix
- **Codespell**: Spell checking in code and docs
- **YAML/JSON validation**: Config file validation

**Infrastructure:**

- **Actionlint**: GitHub Actions workflow linting
- **check-github-workflows**: GitHub workflow schema validation

### Linting Rules

- Follow PEP 8 style guidelines
- Use type hints for function signatures
- Maximum line length: 120 characters
- Use modern Python syntax (3.11+ features)

### Running Pre-commit on Specific Files

**IMPORTANT**: After editing any files, always run pre-commit hooks:

```bash
# Run pre-commit on specific files
pre-commit run --files path/to/file1.py path/to/file2.py

# Or run on all files
pre-commit run --all-files
```

---

## Testing

### Test Structure

```text
tests/
├── conftest.py           # Shared pytest fixtures
├── unit/                 # Unit tests (pytest, no FreeCAD required)
│   └── test_core.py      # Tests for multi_export_core.py
├── freecad/              # FreeCAD integration tests
│   └── test_multi_export.py  # Tests run inside FreeCAD
└── just_commands/        # Just command tests
    ├── conftest.py       # Shared fixtures
    └── test_*.py         # Tests for each just module
```

### Running Tests

```bash
# Unit tests (fast, no FreeCAD required)
just test                    # or: pytest tests/unit -v
just test-cov                # with coverage

# FreeCAD integration tests (requires FreeCAD installation)
just testing::freecad        # Uses freecadcmd or freecad -c

# Run all tests
just testing::all

# Run just command syntax tests (fast)
just testing::just-syntax

# Run just command runtime tests
just testing::just-runtime

# Run all just command tests
just testing::just-all

# Run full release test suite
just testing::release-test
```

### Writing Tests

**Unit tests** (in `tests/unit/`):

- Test pure Python logic in `multi_export_core.py`
- Run with standard pytest
- Use fixtures from `conftest.py`

**FreeCAD integration tests** (in `tests/freecad/`):

- Test FreeCAD-dependent logic in `multi_export_fc.py`
- Run inside FreeCAD using `freecad -c tests/freecad/test_multi_export.py`
- Use Python's unittest framework (compatible with FreeCAD's test runner)

**Just command tests** (in `tests/just_commands/`):

- Verify all just commands work correctly
- Syntax tests use `--dry-run` to validate parsing
- Runtime tests actually execute commands

---

## Documentation

### Building Documentation

```bash
just documentation::build  # Build documentation
just documentation::serve  # Serve locally at http://localhost:8000
```

Documentation is built with MkDocs and deployed to GitHub Pages.

### GitHub Pages Deployment

This repo uses **artifact-based deployment** (`actions/deploy-pages@v4`), which does **not** require a `gh-pages` branch.

**Initial Setup** (one-time):

1. Go to repo **Settings** → **Pages**
2. Under **Build and deployment** → **Source**, select **"GitHub Actions"**
3. Save

**Deployment triggers**:

- Push to `main` branch (if docs paths changed)
- Manual trigger via **Actions** → **Documentation** → **Run workflow**

The workflow builds MkDocs and deploys directly via GitHub's artifact system. No branch management required.

---

## File Extension Conventions

**Use full file extensions, not DOS-style shortened versions:**

| Correct Extension | Incorrect (DOS-style) |
| ----------------- | --------------------- |
| `.yaml`           | `.yml`                |
| `.jpeg`           | `.jpg`                |
| `.html`           | `.htm`                |

---

## Macro Installation

### Quick Install (via just commands)

The easiest way to install the macro locally:

```bash
just install::macro     # Install macro to FreeCAD
just install::status    # Check installation status
just install::uninstall # Remove macro from FreeCAD
just install::cleanup   # Alias for uninstall
```

The install commands automatically detect FreeCAD's location based on your OS:

- **macOS**: `~/Library/Application Support/FreeCAD/`
- **Linux**: `~/.local/share/FreeCAD/`
- **Windows**: `%APPDATA%/FreeCAD/`

For FreeCAD 1.x+, the commands also detect versioned directories (e.g., `v1-1`, `v1-2`).

### Other Installation Methods

1. **Addon Manager**: Search for "Multi Export" in FreeCAD's Addon Manager
2. **Manual**: Copy the `macro/Multi_Export/` directory to FreeCAD's Macro folder

When installed via Addon Manager, the full package (with modules) is installed. When copying just the `.FCMacro` file, it uses embedded fallback definitions.

---

## Release Process

Releases follow a two-step process: bump, then tag.

### Step 1: Bump Version

```bash
# Update version in all source files
just release::bump 1.0.0

# Review changes
git diff

# Commit
git add -A && git commit -m "chore: bump to 1.0.0"
```

The bump command updates:

- `macro/Multi_Export/MultiExport.FCMacro` (`__version__`)
- `package.xml` (`<version>` and `<date>`)
- `macro/Multi_Export/wiki-source.txt` (`|Version=` and `|Date=`)

### Step 2: Create Release Tag

```bash
# Create and push the tag (triggers GitHub workflow)
just release::tag 1.0.0
```

The tag command:

1. Verifies version in source files matches the tag
2. Creates annotated git tag
3. Pushes tag to origin
4. Triggers GitHub Actions release workflow

### Release Commands

```bash
just release::bump 1.0.0     # Update version in source files
just release::tag 1.0.0      # Create and push release tag
just release::version        # Show current version
just release::list-tags      # List all release tags
just release::latest-tag     # Show latest release tag
```

### Update FreeCAD Wiki (After Release)

```bash
just release::wiki-diff      # Check differences from live wiki
just release::wiki-show      # View wiki source content
just release::wiki-update    # Copy to clipboard & open wiki edit page
```

---

## Summary Checklist

When working on this project, ALWAYS:

- [ ] Use `mise` for tool management
- [ ] Use `just` commands for workflows
- [ ] Write docstrings for all functions
- [ ] Write tests for new code
- [ ] Run `just all` before finishing - everything must pass
- [ ] Keep unit tests in `tests/unit/` (pytest, no FreeCAD)
- [ ] Keep FreeCAD tests in `tests/freecad/` (run inside FreeCAD)
