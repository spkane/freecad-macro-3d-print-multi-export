"""Tests for install module just commands.

These tests verify that installation commands work correctly.
Note: Most install commands are tested with --dry-run only to avoid
actually installing/uninstalling the macro during tests.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, ClassVar

import pytest

if TYPE_CHECKING:
    from tests.just_commands.conftest import JustRunner


class TestInstallSyntax:
    """Syntax validation tests for install module commands."""

    INSTALL_COMMANDS: ClassVar[list[str]] = [
        "install::macro",
        "install::uninstall",
        "install::cleanup",
        "install::status",
    ]

    @pytest.mark.just_syntax
    @pytest.mark.parametrize("command", INSTALL_COMMANDS)
    def test_install_command_syntax(self, just: JustRunner, command: str) -> None:
        """Install command should have valid syntax."""
        result = just.dry_run(command)
        assert result.success, f"Syntax error in '{command}': {result.stderr}"


class TestInstallRuntime:
    """Runtime tests for install module commands.

    Note: We only test 'status' at runtime to avoid actually
    installing/uninstalling the macro during tests.
    """

    @pytest.mark.just_runtime
    def test_status_runs(self, just: JustRunner) -> None:
        """Status command should run and show installation status."""
        result = just.run("install::status", timeout=30)
        # Should execute without crashing
        assert result.returncode != 127, f"Command not found: {result.stderr}"
        assert result.returncode != -1, f"Timed out: {result.stderr}"
        # Should show some status output
        assert (
            "Installation Status" in result.output or "INSTALLED" in result.output or "NOT INSTALLED" in result.output
        )
