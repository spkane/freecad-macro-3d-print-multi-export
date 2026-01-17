# Contributing

Contributions are welcome! This guide will help you get started.

## Ways to Contribute

- **Report bugs** - Open an issue describing the problem
- **Suggest features** - Open an issue with your idea
- **Improve documentation** - Fix typos, clarify instructions
- **Submit code** - Fix bugs or add features

## Development Setup

### Prerequisites

- [FreeCAD](https://www.freecadweb.org/) 0.21+ or 1.0+
- [mise](https://mise.jdx.dev/) - Tool version manager (optional but recommended)
- Python 3.11

### Clone and Setup

```bash
# Clone the repository
git clone https://github.com/spkane/freecad-macro-3d-print-multi-export.git
cd freecad-macro-3d-print-multi-export

# Install mise (if not already installed)
curl https://mise.run | sh

# Install tools and setup pre-commit hooks
mise trust
mise install
just setup
```

### Running Quality Checks

```bash
# Run all pre-commit checks
just all

# Or run specific checks
just quality::lint          # Linting only
just quality::format        # Auto-format code
just quality::markdown-fix  # Fix markdown issues
```

## Code Style

- Follow [PEP 8](https://pep8.org/) for Python code
- Use [ruff](https://github.com/astral-sh/ruff) for linting and formatting
- Keep functions focused and well-documented
- Add comments for complex logic

## Pull Request Process

1. **Fork** the repository
2. **Create a branch** for your changes: `git checkout -b feature/my-feature`
3. **Make your changes** and commit them
4. **Run quality checks**: `just all`
5. **Push** to your fork
6. **Open a Pull Request** with a clear description

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat: add new feature
fix: resolve bug in export
docs: update installation instructions
chore: update dependencies
```

## Testing

### Manual Testing

1. Install the macro in FreeCAD
2. Test with various object types
3. Test all export formats
4. Verify file contents are correct

### Test Cases to Cover

- [ ] Single object export
- [ ] Multiple object export
- [ ] All 8 export formats
- [ ] Custom mesh tolerance values
- [ ] Invalid object handling

## Documentation

Documentation is built with [MkDocs](https://www.mkdocs.org/) and [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

```bash
# Serve documentation locally
just documentation::serve

# Build documentation
just documentation::build
```

## Questions?

- Open an issue for questions about contributing
- Check existing issues for similar discussions
