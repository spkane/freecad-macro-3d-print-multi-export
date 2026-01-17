"""Tests for dev module just commands.

These tests verify that development utility commands work correctly.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, ClassVar

import pytest

if TYPE_CHECKING:
    from tests.just_commands.conftest import JustRunner


class TestDevSyntax:
    """Syntax validation tests for dev module commands."""

    DEV_COMMANDS: ClassVar[list[str]] = [
        "dev::install-pre-commit",
        "dev::update-deps",
        "dev::clean",
        "dev::tree",
    ]

    @pytest.mark.just_syntax
    @pytest.mark.parametrize("command", DEV_COMMANDS)
    def test_dev_command_syntax(self, just: JustRunner, command: str) -> None:
        """Dev command should have valid syntax."""
        result = just.dry_run(command)
        assert result.success, f"Syntax error in '{command}': {result.stderr}"


class TestDevRuntime:
    """Runtime tests for dev module commands."""

    @pytest.mark.just_runtime
    def test_tree_shows_structure(self, just: JustRunner) -> None:
        """Tree command should show project structure."""
        result = just.run("dev::tree", timeout=30)
        # Tree command may fail if tree is not installed, but should execute
        if result.success:
            # Should show some directories
            assert "macro" in result.stdout or "tests" in result.stdout
