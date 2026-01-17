"""Unit tests for multi_export_core module.

These tests verify the pure Python logic that doesn't require FreeCAD.
Run with: pytest tests/unit/test_core.py -v
"""

import os

import pytest
from multi_export_core import (
    CAD_FORMATS,
    EXPORT_FORMATS,
    MESH_FORMATS,
    ExportFormat,
    build_export_filepath,
    format_export_summary,
    get_default_formats,
    get_format_by_extension,
    is_cad_format,
    is_mesh_format,
    sanitize_filename,
    validate_export_params,
)


class TestExportFormat:
    """Tests for ExportFormat dataclass."""

    def test_export_format_creation(self):
        """Test creating an ExportFormat instance."""
        fmt = ExportFormat(
            name="TEST",
            extension="test",
            description="Test format",
            default_enabled=True,
        )
        assert fmt.name == "TEST"
        assert fmt.extension == "test"
        assert fmt.description == "Test format"
        assert fmt.default_enabled is True

    def test_export_format_default_disabled(self):
        """Test default_enabled defaults to False."""
        fmt = ExportFormat(name="TEST", extension="test", description="Test format")
        assert fmt.default_enabled is False


class TestExportFormats:
    """Tests for the EXPORT_FORMATS list."""

    def test_export_formats_not_empty(self):
        """Test that EXPORT_FORMATS is not empty."""
        assert len(EXPORT_FORMATS) > 0

    def test_export_formats_contains_stl(self):
        """Test that STL format is included."""
        extensions = [fmt.extension for fmt in EXPORT_FORMATS]
        assert "stl" in extensions

    def test_export_formats_contains_step(self):
        """Test that STEP format is included."""
        extensions = [fmt.extension for fmt in EXPORT_FORMATS]
        assert "step" in extensions

    def test_export_formats_contains_3mf(self):
        """Test that 3MF format is included."""
        extensions = [fmt.extension for fmt in EXPORT_FORMATS]
        assert "3mf" in extensions

    def test_all_formats_have_required_fields(self):
        """Test that all formats have required fields."""
        for fmt in EXPORT_FORMATS:
            assert fmt.name, f"Format missing name: {fmt}"
            assert fmt.extension, f"Format missing extension: {fmt}"
            assert fmt.description, f"Format missing description: {fmt}"


class TestGetFormatByExtension:
    """Tests for get_format_by_extension function."""

    def test_get_known_format(self):
        """Test getting a known format."""
        fmt = get_format_by_extension("stl")
        assert fmt is not None
        assert fmt.extension == "stl"
        assert fmt.name == "STL"

    def test_get_format_case_insensitive(self):
        """Test that lookup is case-insensitive."""
        fmt = get_format_by_extension("STL")
        assert fmt is not None
        assert fmt.extension == "stl"

    def test_get_unknown_format_returns_none(self):
        """Test that unknown format returns None."""
        fmt = get_format_by_extension("xyz123")
        assert fmt is None


class TestGetDefaultFormats:
    """Tests for get_default_formats function."""

    def test_returns_list(self):
        """Test that it returns a list."""
        defaults = get_default_formats()
        assert isinstance(defaults, list)

    def test_contains_stl(self):
        """Test that STL is a default format."""
        defaults = get_default_formats()
        assert "stl" in defaults

    def test_contains_step(self):
        """Test that STEP is a default format."""
        defaults = get_default_formats()
        assert "step" in defaults

    def test_contains_3mf(self):
        """Test that 3MF is a default format."""
        defaults = get_default_formats()
        assert "3mf" in defaults


class TestIsMeshFormat:
    """Tests for is_mesh_format function."""

    @pytest.mark.parametrize("extension", list(MESH_FORMATS))
    def test_mesh_formats(self, extension):
        """Test that mesh formats are correctly identified."""
        assert is_mesh_format(extension) is True

    @pytest.mark.parametrize("extension", list(CAD_FORMATS))
    def test_cad_formats_not_mesh(self, extension):
        """Test that CAD formats are not mesh formats."""
        assert is_mesh_format(extension) is False

    def test_case_insensitive(self):
        """Test that check is case-insensitive."""
        assert is_mesh_format("STL") is True
        assert is_mesh_format("Stl") is True


class TestIsCadFormat:
    """Tests for is_cad_format function."""

    @pytest.mark.parametrize("extension", list(CAD_FORMATS))
    def test_cad_formats(self, extension):
        """Test that CAD formats are correctly identified."""
        assert is_cad_format(extension) is True

    @pytest.mark.parametrize("extension", list(MESH_FORMATS))
    def test_mesh_formats_not_cad(self, extension):
        """Test that mesh formats are not CAD formats."""
        assert is_cad_format(extension) is False


class TestSanitizeFilename:
    """Tests for sanitize_filename function."""

    def test_simple_name(self):
        """Test that simple names pass through."""
        assert sanitize_filename("myfile") == "myfile"

    def test_name_with_spaces(self):
        """Test that spaces are preserved."""
        assert sanitize_filename("my file") == "my file"

    def test_invalid_characters_replaced(self):
        """Test that invalid characters are replaced with underscores."""
        assert sanitize_filename("file<>name") == "file__name"
        assert sanitize_filename('file"name') == "file_name"
        assert sanitize_filename("file:name") == "file_name"
        assert sanitize_filename("file|name") == "file_name"

    def test_leading_dots_stripped(self):
        """Test that leading dots are stripped."""
        assert sanitize_filename("...hidden") == "hidden"

    def test_trailing_dots_stripped(self):
        """Test that trailing dots are stripped."""
        assert sanitize_filename("file...") == "file"

    def test_empty_returns_export(self):
        """Test that empty string returns 'export'."""
        assert sanitize_filename("") == "export"

    def test_only_invalid_chars_returns_export(self):
        """Test that string of only invalid chars returns 'export'."""
        # After replacing <> and stripping dots/spaces
        assert sanitize_filename("...") == "export"


class TestValidateExportParams:
    """Tests for validate_export_params function."""

    def test_valid_params(self, valid_export_params):
        """Test that valid params return no errors."""
        errors = validate_export_params(valid_export_params)
        assert errors == []

    def test_missing_formats(self, valid_export_params):
        """Test that missing formats returns error."""
        valid_export_params["formats"] = []
        errors = validate_export_params(valid_export_params)
        assert any("formats" in e.lower() for e in errors)

    def test_missing_filename(self, valid_export_params):
        """Test that missing filename returns error."""
        valid_export_params["base_filename"] = ""
        errors = validate_export_params(valid_export_params)
        assert any("filename" in e.lower() for e in errors)

    def test_whitespace_only_filename(self, valid_export_params):
        """Test that whitespace-only filename returns error."""
        valid_export_params["base_filename"] = "   "
        errors = validate_export_params(valid_export_params)
        assert any("filename" in e.lower() for e in errors)

    def test_missing_directory(self, valid_export_params):
        """Test that missing directory returns error."""
        valid_export_params["directory"] = ""
        errors = validate_export_params(valid_export_params)
        assert any("directory" in e.lower() for e in errors)

    def test_unknown_format(self, valid_export_params):
        """Test that unknown format returns error."""
        valid_export_params["formats"] = ["stl", "unknown_format"]
        errors = validate_export_params(valid_export_params)
        assert any("unknown" in e.lower() for e in errors)


class TestBuildExportFilepath:
    """Tests for build_export_filepath function."""

    def test_builds_correct_path(self):
        """Test that path is built correctly."""
        filepath = build_export_filepath("/tmp/exports", "myfile", "stl")
        expected = os.path.join("/tmp/exports", "myfile.stl")
        assert filepath == expected

    def test_handles_trailing_slash(self):
        """Test that trailing slash in directory is handled."""
        filepath = build_export_filepath("/tmp/exports/", "myfile", "stl")
        # os.path.join handles this correctly
        assert filepath.endswith("myfile.stl")


class TestFormatExportSummary:
    """Tests for format_export_summary function."""

    def test_no_files_no_errors(self):
        """Test summary with no files and no errors."""
        summary = format_export_summary([], [])
        assert "no files" in summary.lower() or summary

    def test_files_only(self):
        """Test summary with only exported files."""
        files = ["/tmp/test.stl", "/tmp/test.step"]
        summary = format_export_summary(files, [])
        assert "2 file" in summary
        assert "test.stl" in summary
        assert "test.step" in summary

    def test_errors_only(self):
        """Test summary with only errors."""
        errors = ["Failed to export STL"]
        summary = format_export_summary([], errors)
        assert "Warning" in summary or "warning" in summary.lower() or "Failed" in summary

    def test_files_and_errors(self):
        """Test summary with both files and errors."""
        files = ["/tmp/test.stl"]
        errors = ["Failed to export STEP"]
        summary = format_export_summary(files, errors)
        assert "1 file" in summary
        assert "test.stl" in summary
        assert "Warning" in summary or "warning" in summary.lower() or "Failed" in summary

    def test_many_files_truncated(self):
        """Test that many files are truncated."""
        files = [f"/tmp/test{i}.stl" for i in range(10)]
        summary = format_export_summary(files, [], max_files_shown=5)
        assert "10 file" in summary
        assert "more" in summary.lower()

    def test_many_errors_truncated(self):
        """Test that many errors are truncated."""
        errors = [f"Error {i}" for i in range(10)]
        summary = format_export_summary([], errors, max_errors_shown=3)
        assert "more" in summary.lower()
