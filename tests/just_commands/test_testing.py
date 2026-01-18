"""Tests for testing module just commands.

These tests verify that test commands work correctly.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, ClassVar

import pytest

from tests.just_commands.conftest import assert_command_executed

if TYPE_CHECKING:
    from tests.just_commands.conftest import JustRunner


class TestTestingSyntax:
    """Syntax validation tests for testing commands."""

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
        "testing::release-test",
    ]

    @pytest.mark.just_syntax
    @pytest.mark.parametrize("command", TESTING_COMMANDS)
    def test_testing_command_syntax(self, just: JustRunner, command: str) -> None:
        """Testing command should have valid syntax."""
        result = just.dry_run(command)
        assert result.success, f"Syntax error in '{command}': {result.stderr}"

    @pytest.mark.just_syntax
    @pytest.mark.parametrize(
        ("command", "arg"),
        [
            ("testing::freecad-appimage", "/path/to/FreeCAD.AppImage"),
        ],
    )
    def test_testing_command_with_args_syntax(self, just: JustRunner, command: str, arg: str) -> None:
        """Testing command with arguments should have valid syntax."""
        result = just.dry_run(command, arg)
        assert result.success, f"Syntax error in '{command} {arg}': {result.stderr}"


class TestTestingRuntime:
    """Runtime tests for testing commands."""

    @pytest.mark.just_runtime
    def test_check_deps_runs(self, just: JustRunner) -> None:
        """Check-deps command should run and show dependency status."""
        result = just.run("testing::check-deps", timeout=30)
        assert result.success, f"check-deps failed: {result.stderr}"
        # Should show pytest status
        assert "pytest" in result.stdout

    @pytest.mark.just_runtime
    def test_unit_tests_run(self, just: JustRunner) -> None:
        """Unit test command should at least recognize pytest."""
        result = just.run(
            "testing::unit",
            timeout=60,
            env={"PYTEST_ADDOPTS": "--collect-only -q"},
        )
        assert_command_executed(result, "testing::unit")
