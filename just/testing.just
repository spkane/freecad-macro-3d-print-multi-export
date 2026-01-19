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

# Run just command syntax tests (fast, validates all commands parse correctly)
just-syntax:
    cd {{project_root}} && pytest tests/just_commands -m "just_syntax" -v

# Run just command runtime tests (slower, actually executes commands)
just-runtime:
    cd {{project_root}} && pytest tests/just_commands -m "just_runtime and not slow" -v

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
    declare -a FAILED_NAMES=()
    declare -a FAILED_COMMANDS=()

    # Helper function to record test failure
    record_failure() {
        TESTS_PASSED=false
        FAILED_NAMES+=("$1")
        FAILED_COMMANDS+=("$2")
    }

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
        record_failure "Unit tests with coverage" "just testing::cov"
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
        record_failure "Just command tests" "just testing::just-all"
    fi
    echo ""

    # -------------------------------------------------------------------------
    # Step 3: Pre-commit Checks
    # -------------------------------------------------------------------------
    echo "============================================================"
    echo "  Step 3/3: Pre-commit Checks"
    echo "============================================================"
    echo ""

    if just quality::check; then
        echo ""
        echo "✓ Pre-commit checks passed"
    else
        echo ""
        echo "✗ Pre-commit checks FAILED"
        record_failure "Pre-commit checks" "just quality::check"
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
        echo "=========================================="
        echo "NEXT STEPS FOR RELEASE"
        echo "=========================================="
        echo ""
        echo "1. UPDATE RELEASE NOTES:"
        echo "   Edit the RELEASE_NOTES.md file for the macro:"
        echo "     - macro/Multi_Export/RELEASE_NOTES.md"
        echo "   Add a new version section with:"
        echo "     - Summary of changes"
        echo "     - Breaking changes (if any)"
        echo "     - New features and improvements"
        echo ""
        echo "   TIP: Use 'just release::draft-notes' to generate a draft from commits."
        echo ""
        echo "2. BUMP VERSIONS:"
        echo "   just release::bump <version>"
        echo "   Example: just release::bump 1.2.0"
        echo ""
        echo "3. COMMIT AND PUSH your RELEASE_NOTES.md and version bump changes:"
        echo "   git add -A && git commit -m 'chore: bump to <version>'"
        echo "   git push"
        echo ""
        echo "4. CREATE RELEASE TAG:"
        echo "   just release::tag <version>"
        echo "   Example: just release::tag 1.2.0"
        echo ""
        echo "NOTE: Release workflows extract notes from the macro's RELEASE_NOTES.md."
        echo ""
    else
        echo "✗ SOME TESTS FAILED - Cannot proceed with release"
        echo ""
        echo "Failed tests:"
        for i in "${!FAILED_NAMES[@]}"; do
            echo "  ✗ ${FAILED_NAMES[$i]}"
        done
        echo ""
        echo "To recreate failures, run:"
        for i in "${!FAILED_COMMANDS[@]}"; do
            echo "  ${FAILED_COMMANDS[$i]}"
        done
        exit 1
    fi
