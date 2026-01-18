"""Tests for testing module just commands.

These tests verify that test-related commands work correctly.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, ClassVar

import pytest

if TYPE_CHECKING:
    from tests.just_commands.conftest import JustRunner


class TestTestingSyntax:
    """Syntax validation tests for testing module commands."""

    TESTING_COMMANDS: ClassVar[list[str]] = [
        "testing::unit",
        "testing::cov",
        "testing::watch",
        "testing::freecad",
        "testing::all",
        "testing::quick",
        "testing::check-deps",
        "testing::just-syntax",
        "testing::just-runtime",
        "testing::just-all",
    ]

    # Commands that require arguments
    TESTING_COMMANDS_WITH_ARGS: ClassVar[list[tuple[str, str]]] = [
        ("testing::freecad-appimage", "/path/to/FreeCAD.AppImage"),
    ]

    @pytest.mark.just_syntax
    @pytest.mark.parametrize("command", TESTING_COMMANDS)
    def test_testing_command_syntax(self, just: JustRunner, command: str) -> None:
        """Testing command should have valid syntax."""
        result = just.dry_run(command)
        assert result.success, f"Syntax error in '{command}': {result.stderr}"

    @pytest.mark.just_syntax
    @pytest.mark.parametrize("command,arg", TESTING_COMMANDS_WITH_ARGS)
    def test_testing_command_with_args_syntax(self, just: JustRunner, command: str, arg: str) -> None:
        """Testing command with args should have valid syntax."""
        result = just.dry_run(command, arg)
        assert result.success, f"Syntax error in '{command} {arg}': {result.stderr}"


class TestTestingRuntime:
    """Runtime tests for testing module commands."""

    @pytest.mark.just_runtime
    def test_check_deps_runs(self, just: JustRunner) -> None:
        """Check deps command should run and report status."""
        result = just.run("testing::check-deps", timeout=30)
        # Should execute and show some output about pytest
        assert result.returncode != 127, f"Command not found: {result.stderr}"
        assert "pytest" in result.stdout.lower() or "pytest" in result.stderr.lower()

    @pytest.mark.just_runtime
    @pytest.mark.slow
    def test_unit_tests_run(self, just: JustRunner) -> None:
        """Unit tests command should run pytest."""
        result = just.run("testing::unit", timeout=120)
        # Should execute (may pass or fail, but should run)
        assert result.returncode != 127, f"pytest not found: {result.stderr}"
        assert result.returncode != -1, f"Timed out: {result.stderr}"
