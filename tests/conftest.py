"""Pytest configuration for Multi Export macro tests."""

import sys
from pathlib import Path

import pytest

# Add the macro directory to the path so we can import the modules
MACRO_DIR = Path(__file__).parent.parent / "macro" / "Multi_Export"
sys.path.insert(0, str(MACRO_DIR))


@pytest.fixture
def temp_export_dir(tmp_path):
    """Create a temporary directory for export tests."""
    export_dir = tmp_path / "exports"
    export_dir.mkdir()
    return export_dir


@pytest.fixture
def valid_export_params(temp_export_dir):
    """Provide valid export parameters for testing."""
    return {
        "directory": str(temp_export_dir),
        "base_filename": "test_export",
        "formats": ["stl", "step"],
        "mesh_tolerance": 0.1,
        "mesh_deflection": 0.1,
    }
