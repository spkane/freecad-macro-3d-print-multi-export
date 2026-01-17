"""Core business logic for Multi Export macro.

SPDX-License-Identifier: MIT
Copyright (c) 2025 Sean P. Kane (GitHub: spkane)

This module contains pure Python logic that doesn't depend on FreeCAD,
making it testable with standard pytest.
"""

from dataclasses import dataclass


@dataclass
class ExportFormat:
    """Represents an export format with its properties."""

    name: str
    extension: str
    description: str
    default_enabled: bool = False


# Define available export formats
EXPORT_FORMATS = [
    ExportFormat(
        name="STL",
        extension="stl",
        description="Stereolithography - common for 3D printing",
        default_enabled=True,
    ),
    ExportFormat(
        name="STEP",
        extension="step",
        description="Standard for Exchange of Product Data - CAD interchange",
        default_enabled=True,
    ),
    ExportFormat(
        name="3MF",
        extension="3mf",
        description="3D Manufacturing Format - modern 3D printing format",
        default_enabled=True,
    ),
    ExportFormat(
        name="OBJ",
        extension="obj",
        description="Wavefront OBJ - 3D graphics and game engines",
        default_enabled=False,
    ),
    ExportFormat(
        name="IGES",
        extension="iges",
        description="Initial Graphics Exchange Specification - legacy CAD format",
        default_enabled=False,
    ),
    ExportFormat(
        name="BREP",
        extension="brep",
        description="OpenCASCADE native format - preserves exact geometry",
        default_enabled=False,
    ),
    ExportFormat(
        name="PLY",
        extension="ply",
        description="Polygon File Format - 3D scanning and printing",
        default_enabled=False,
    ),
    ExportFormat(
        name="AMF",
        extension="amf",
        description="Additive Manufacturing Format - XML-based 3D printing",
        default_enabled=False,
    ),
]

# Formats that require mesh conversion (vs native CAD formats)
MESH_FORMATS = {"stl", "obj", "ply", "3mf", "amf"}

# Native CAD formats that preserve exact geometry
CAD_FORMATS = {"step", "iges", "brep"}


def get_format_by_extension(extension: str) -> ExportFormat | None:
    """Get an ExportFormat by its extension.

    Args:
        extension: File extension (without dot)

    Returns:
        ExportFormat if found, None otherwise
    """
    for fmt in EXPORT_FORMATS:
        if fmt.extension == extension.lower():
            return fmt
    return None


def get_default_formats() -> list[str]:
    """Get list of default-enabled format extensions.

    Returns:
        List of extensions that are enabled by default
    """
    return [fmt.extension for fmt in EXPORT_FORMATS if fmt.default_enabled]


def is_mesh_format(extension: str) -> bool:
    """Check if a format requires mesh conversion.

    Args:
        extension: File extension (without dot)

    Returns:
        True if format is a mesh format
    """
    return extension.lower() in MESH_FORMATS


def is_cad_format(extension: str) -> bool:
    """Check if a format is a native CAD format.

    Args:
        extension: File extension (without dot)

    Returns:
        True if format is a CAD format
    """
    return extension.lower() in CAD_FORMATS


def sanitize_filename(name: str) -> str:
    """Sanitize a string for use as a filename.

    Args:
        name: The original name

    Returns:
        Sanitized filename (without extension)
    """
    # Replace problematic characters
    invalid_chars = '<>:"/\\|?*'
    result = name
    for char in invalid_chars:
        result = result.replace(char, "_")

    # Remove leading/trailing whitespace and dots
    result = result.strip(" .")

    # Ensure non-empty
    return result if result else "export"


def validate_export_params(params: dict) -> list[str]:
    """Validate export parameters and return list of errors.

    Args:
        params: Export parameters dictionary with keys:
            - directory: Output directory path
            - base_filename: Base filename without extension
            - formats: List of format extensions to export

    Returns:
        List of validation error messages (empty if valid)
    """
    errors = []

    if not params.get("formats"):
        errors.append("No export formats selected")

    if not params.get("base_filename") or not params["base_filename"].strip():
        errors.append("No base filename provided")

    if not params.get("directory"):
        errors.append("No output directory specified")

    # Validate format extensions are known
    unknown_formats = []
    for ext in params.get("formats", []):
        if get_format_by_extension(ext) is None:
            unknown_formats.append(ext)
    if unknown_formats:
        errors.append(f"Unknown formats: {', '.join(unknown_formats)}")

    return errors


def build_export_filepath(directory: str, base_filename: str, extension: str) -> str:
    """Build the full filepath for an export.

    Args:
        directory: Output directory path
        base_filename: Base filename without extension
        extension: File extension (without dot)

    Returns:
        Full file path
    """
    import os

    return os.path.join(directory, f"{base_filename}.{extension}")


def format_export_summary(
    exported_files: list[str],
    errors: list[str],
    max_files_shown: int = 5,
    max_errors_shown: int = 3,
) -> str:
    """Format a summary of export results for display.

    Args:
        exported_files: List of successfully exported file paths
        errors: List of error messages
        max_files_shown: Maximum number of files to list explicitly
        max_errors_shown: Maximum number of errors to list explicitly

    Returns:
        Formatted summary string
    """
    import os

    lines = []

    if exported_files:
        lines.append(f"Successfully exported {len(exported_files)} file(s):")
        for f in exported_files[:max_files_shown]:
            lines.append(f"  • {os.path.basename(f)}")
        if len(exported_files) > max_files_shown:
            lines.append(f"  ... and {len(exported_files) - max_files_shown} more")

    if errors:
        if lines:
            lines.append("")
        lines.append(f"Warnings ({len(errors)}):")
        for e in errors[:max_errors_shown]:
            lines.append(f"  • {e}")
        if len(errors) > max_errors_shown:
            lines.append(f"  ... and {len(errors) - max_errors_shown} more")

    if not lines:
        return "No files exported and no errors reported"

    return "\n".join(lines)
