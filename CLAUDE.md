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
│   └── freecad/              # FreeCAD integration tests
├── .pre-commit-config.yaml   # Pre-commit hooks
├── justfile                  # Task runner
├── mkdocs.yaml               # Documentation config
└── pyproject.toml            # Project configuration
```

### Code Architecture

The macro is split into three layers for testability:

1. **multi_export_core.py** - Pure Python logic (format definitions, validation, filename sanitization). Testable with standard pytest.

2. **multi_export_fc.py** - FreeCAD-dependent logic (export functions, shape handling, MultiExporter class). Testable inside FreeCAD.

3. **MultiExport.FCMacro** - GUI dialog and entry point. Imports from modules when available, falls back to embedded definitions for standalone use.

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
└── freecad/              # FreeCAD integration tests
    └── test_multi_export.py  # Tests run inside FreeCAD
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

---

## Documentation

### Building Documentation

```bash
just documentation::build  # Build documentation
just documentation::serve  # Serve locally at http://localhost:8000
```

Documentation is built with MkDocs and deployed to GitHub Pages.

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

The macro can be installed in FreeCAD via:

1. **Addon Manager**: Search for "Multi Export" in FreeCAD's Addon Manager
2. **Manual**: Copy the `macro/Multi_Export/` directory to FreeCAD's Macro folder

When installed via Addon Manager, the full package (with modules) is installed. When copying just the `.FCMacro` file, it uses embedded fallback definitions.

---

## Release Process

Releases are created by pushing git tags:

```bash
# Create a release tag (triggers GitHub workflow)
just release::tag 0.6.2

# View release tags
just release::list-tags
```

The release workflow:

1. Validates tag format
2. Updates version in source files
3. Creates GitHub Release with macro archive

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
