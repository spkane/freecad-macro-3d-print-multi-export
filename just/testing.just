# Testing commands
# Usage: just testing::unit, just testing::freecad, etc.
#
# Unit tests run with pytest (pure Python, no FreeCAD required)
# Integration tests run inside FreeCAD (requires FreeCAD installation)

# Project root directory
project_root := justfile_directory()

# =============================================================================
# Unit Tests (pytest - no FreeCAD required)
# =============================================================================

# Run all unit tests
unit:
    cd {{project_root}} && pytest tests/unit -v

# Run unit tests with coverage
unit-cov:
    cd {{project_root}} && pytest tests/unit -v --cov=macro/Multi_Export --cov-report=term-missing --cov-report=html

# Run unit tests in watch mode (requires pytest-watch)
unit-watch:
    cd {{project_root}} && pytest-watch tests/unit

# =============================================================================
# FreeCAD Integration Tests
# =============================================================================

# Run FreeCAD integration tests (requires FreeCAD installation)
freecad:
    @echo "Running FreeCAD integration tests..."
    @echo "Note: Requires FreeCAD to be installed and accessible via 'freecadcmd' or 'freecad'"
    @if command -v freecadcmd >/dev/null 2>&1; then \
        freecadcmd {{project_root}}/tests/freecad/test_multi_export.py; \
    elif command -v freecad >/dev/null 2>&1; then \
        freecad -c {{project_root}}/tests/freecad/test_multi_export.py; \
    else \
        echo "Error: FreeCAD not found. Please install FreeCAD and ensure 'freecadcmd' or 'freecad' is in your PATH."; \
        exit 1; \
    fi

# Run FreeCAD integration tests using AppImage (for CI)
freecad-appimage appimage_path:
    @echo "Running FreeCAD integration tests using AppImage..."
    chmod +x {{appimage_path}}
    {{appimage_path}} -c {{project_root}}/tests/freecad/test_multi_export.py

# =============================================================================
# Combined Test Commands
# =============================================================================

# Run all tests (unit + FreeCAD integration)
all: unit freecad
    @echo "All tests complete!"

# Run unit tests only (for quick feedback during development)
quick: unit
    @echo "Quick tests complete!"

# =============================================================================
# Test Setup
# =============================================================================

# Install test dependencies
install:
    pip install -e "{{project_root}}[test]"

# Check if test dependencies are installed
check-deps:
    @python -c "import pytest" 2>/dev/null && echo "✓ pytest installed" || echo "✗ pytest not installed (run 'just testing::install')"
    @python -c "import pytest_cov" 2>/dev/null && echo "✓ pytest-cov installed" || echo "✗ pytest-cov not installed"
