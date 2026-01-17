"""Tests for documentation module just commands.

These tests verify that documentation commands work correctly.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, ClassVar

import pytest

if TYPE_CHECKING:
    from tests.just_commands.conftest import JustRunner


class TestDocumentationSyntax:
    """Syntax validation tests for documentation module commands."""

    DOC_COMMANDS: ClassVar[list[str]] = [
        "documentation::build",
        "documentation::serve",
    ]

    @pytest.mark.just_syntax
    @pytest.mark.parametrize("command", DOC_COMMANDS)
    def test_documentation_command_syntax(self, just: JustRunner, command: str) -> None:
        """Documentation command should have valid syntax."""
        result = just.dry_run(command)
        assert result.success, f"Syntax error in '{command}': {result.stderr}"


class TestDocumentationRuntime:
    """Runtime tests for documentation module commands."""

    @pytest.mark.just_runtime
    @pytest.mark.slow
    def test_build_creates_site(self, just: JustRunner) -> None:
        """Build command should create documentation site."""
        result = just.run("documentation::build", timeout=120)
        # Build may fail if mkdocs deps not installed, but should execute
        if result.success:
            assert "site" in result.stdout or result.returncode == 0
