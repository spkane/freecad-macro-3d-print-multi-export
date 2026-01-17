"""Tests for release module just commands.

These tests verify that release commands work correctly.
Note: Most release commands are tested with --dry-run only to avoid
accidentally creating real releases.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, ClassVar

import pytest

if TYPE_CHECKING:
    from tests.just_commands.conftest import JustRunner


class TestReleaseSyntax:
    """Syntax validation tests for release module commands."""

    RELEASE_COMMANDS: ClassVar[list[str]] = [
        "release::list-tags",
    ]

    # Commands that require arguments (test with dummy args)
    RELEASE_COMMANDS_WITH_ARGS: ClassVar[list[tuple[str, str]]] = [
        ("release::tag", "0.0.0"),
    ]

    @pytest.mark.just_syntax
    @pytest.mark.parametrize("command", RELEASE_COMMANDS)
    def test_release_command_syntax(self, just: JustRunner, command: str) -> None:
        """Release command should have valid syntax."""
        result = just.dry_run(command)
        assert result.success, f"Syntax error in '{command}': {result.stderr}"

    @pytest.mark.just_syntax
    @pytest.mark.parametrize("command,arg", RELEASE_COMMANDS_WITH_ARGS)
    def test_release_command_with_args_syntax(self, just: JustRunner, command: str, arg: str) -> None:
        """Release command with args should have valid syntax."""
        result = just.dry_run(command, arg)
        assert result.success, f"Syntax error in '{command} {arg}': {result.stderr}"


class TestReleaseRuntime:
    """Runtime tests for release module commands."""

    @pytest.mark.just_runtime
    def test_list_tags_runs(self, just: JustRunner) -> None:
        """List tags command should run without crashing."""
        result = just.run("release::list-tags", timeout=30)
        # Should execute without crashing (may have no tags)
        assert result.returncode != 127, f"Command not found: {result.stderr}"
        assert result.returncode != -1, f"Timed out: {result.stderr}"
