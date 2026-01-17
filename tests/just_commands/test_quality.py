"""Tests for quality module just commands.

These tests verify that code quality commands work correctly.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, ClassVar

import pytest

if TYPE_CHECKING:
    from tests.just_commands.conftest import JustRunner


class TestQualitySyntax:
    """Syntax validation tests for quality module commands."""

    QUALITY_COMMANDS: ClassVar[list[str]] = [
        "quality::check",
        "quality::format",
        "quality::lint",
    ]

    @pytest.mark.just_syntax
    @pytest.mark.parametrize("command", QUALITY_COMMANDS)
    def test_quality_command_syntax(self, just: JustRunner, command: str) -> None:
        """Quality command should have valid syntax."""
        result = just.dry_run(command)
        assert result.success, f"Syntax error in '{command}': {result.stderr}"


class TestQualityRuntime:
    """Runtime tests for quality module commands."""

    @pytest.mark.just_runtime
    @pytest.mark.slow
    def test_lint_runs(self, just: JustRunner) -> None:
        """Lint command should run without crashing."""
        result = just.run("quality::lint", timeout=120)
        # Lint may find issues, but should execute without crashing
        assert result.returncode != 127, f"Lint command not found: {result.stderr}"
        assert result.returncode != -1, f"Lint timed out: {result.stderr}"

    @pytest.mark.just_runtime
    def test_format_runs(self, just: JustRunner) -> None:
        """Format command should run without crashing."""
        result = just.run("quality::format", timeout=60)
        # Format should execute without crashing
        assert result.returncode != 127, f"Format command not found: {result.stderr}"
        assert result.returncode != -1, f"Format timed out: {result.stderr}"
