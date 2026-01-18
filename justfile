# FreeCAD Multi Export Macro - Development Workflow Commands
# https://just.systems/
#
# Commands are organized into modules. Run `just` to see top-level commands,
# or `just list-<module>` to see commands in a specific module:
#   just list-dev           - Development utilities
#   just list-documentation - Documentation commands
#   just list-quality       - Code quality commands
#   just list-release       - Release and tagging commands
#   just list-testing       - Testing commands
#
# Or use `just list-all` to see all commands from all modules at once.

# Import modules
mod dev 'just/dev.just'
mod documentation 'just/documentation.just'
mod quality 'just/quality.just'
mod release 'just/release.just'
mod testing 'just/testing.just'

# Default recipe - show top-level commands and available modules
default:
    @just --list --unsorted

# =============================================================================
# Setup & Installation
# =============================================================================

# Full development environment setup (installs pre-commit hooks)
setup: (dev::install-pre-commit)
    @echo "Development environment ready!"

# =============================================================================
# Combined Workflows
# =============================================================================

# Run all quality checks (use before committing)
all: (quality::check)
    @echo "All checks passed!"

# Run unit tests (quick feedback during development)
test: (testing::unit)
    @echo "Tests complete!"

# Run unit tests with coverage
test-cov: (testing::cov)
    @echo "Coverage report generated!"

# =============================================================================
# Module Listings (use these to explore available commands)
# =============================================================================

# List ALL commands from all modules
list-all:
    @just --list --list-submodules

# List development utility commands
list-dev:
    @just --list dev

# List documentation commands
list-documentation:
    @just --list documentation

# List code quality commands
list-quality:
    @just --list quality

# List release and tagging commands
list-release:
    @just --list release

# List testing commands
list-testing:
    @just --list testing
