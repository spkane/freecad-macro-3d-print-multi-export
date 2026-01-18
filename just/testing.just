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
cov:
    cd {{project_root}} && pytest tests/unit -v --cov=macro/Multi_Export --cov-report=term-missing --cov-report=html

# Run unit tests in watch mode (requires pytest-watch)
watch:
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
# Test Utilities
# =============================================================================

# Check if test dependencies are installed
check-deps:
    @python -c "import pytest" 2>/dev/null && echo "✓ pytest installed" || echo "✗ pytest not installed"
    @python -c "import pytest_cov" 2>/dev/null && echo "✓ pytest-cov installed" || echo "✗ pytest-cov not installed"

# =============================================================================
# Just Command Tests
# =============================================================================

# Run just command syntax tests (validates justfile syntax)
just-syntax:
    cd {{project_root}} && pytest tests/just_commands -m "just_syntax" -v

# Run just command runtime tests (executes commands)
just-runtime:
    cd {{project_root}} && pytest tests/just_commands -m "just_runtime" -v

# Run all just command tests
just-all:
    cd {{project_root}} && pytest tests/just_commands -v

# =============================================================================
# Release Testing
# =============================================================================

# Run all tests required before a release can be created
release-test:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "============================================================"
    echo "  RELEASE TEST SUITE"
    echo "  All tests must pass before creating a release"
    echo "============================================================"
    echo ""

    # Track overall test results
    TESTS_PASSED=true

    # -------------------------------------------------------------------------
    # Step 1: Unit Tests with Coverage
    # -------------------------------------------------------------------------
    echo "============================================================"
    echo "  Step 1/3: Unit Tests with Coverage"
    echo "============================================================"
    echo ""

    if just testing::cov; then
        echo ""
        echo "✓ Unit tests passed"
    else
        echo ""
        echo "✗ Unit tests FAILED"
        TESTS_PASSED=false
    fi
    echo ""

    # -------------------------------------------------------------------------
    # Step 2: Just Command Tests
    # -------------------------------------------------------------------------
    echo "============================================================"
    echo "  Step 2/3: Just Command Tests"
    echo "============================================================"
    echo ""

    if just testing::just-all; then
        echo ""
        echo "✓ Just command tests passed"
    else
        echo ""
        echo "✗ Just command tests FAILED"
        TESTS_PASSED=false
    fi
    echo ""

    # -------------------------------------------------------------------------
    # Step 3: Pre-commit Checks
    # -------------------------------------------------------------------------
    echo "============================================================"
    echo "  Step 3/3: Pre-commit Checks"
    echo "============================================================"
    echo ""

    if pre-commit run --all-files; then
        echo ""
        echo "✓ Pre-commit checks passed"
    else
        echo ""
        echo "✗ Pre-commit checks FAILED"
        TESTS_PASSED=false
    fi
    echo ""

    # -------------------------------------------------------------------------
    # Summary
    # -------------------------------------------------------------------------
    echo "============================================================"
    echo "  RELEASE TEST SUMMARY"
    echo "============================================================"
    echo ""

    if [ "$TESTS_PASSED" = true ]; then
        echo "✓ ALL TESTS PASSED - Ready for release!"
        echo ""
        echo "Next steps:"
        echo "  1. Update RELEASE_NOTES.md with version section"
        echo "  2. Create release tag: just release::tag <version>"
    else
        echo "✗ SOME TESTS FAILED - Please fix before releasing"
        exit 1
    fi
