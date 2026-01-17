"""FreeCAD-dependent export operations for Multi Export macro.

SPDX-License-Identifier: MIT
Copyright (c) 2025 Sean P. Kane (GitHub: spkane)

This module contains FreeCAD-specific export logic. It requires FreeCAD
to be available and is tested using FreeCAD's built-in test framework.
"""

import FreeCAD as App
import Mesh
import Part

from .multi_export_core import build_export_filepath, is_mesh_format


def get_object_type(obj) -> str:
    """Get a human-readable type description for an object.

    Args:
        obj: FreeCAD document object

    Returns:
        Human-readable type string
    """
    if hasattr(obj, "TypeId"):
        type_id = obj.TypeId
        if "Part::" in type_id:
            return type_id.replace("Part::", "")
        if "PartDesign::" in type_id:
            return type_id.replace("PartDesign::", "")
        if "Mesh::" in type_id:
            return "Mesh"
        return type_id
    if hasattr(obj, "Shape"):
        return "Shape"
    return ""


def is_object_exportable(obj) -> bool:
    """Check if an object can be exported.

    Args:
        obj: FreeCAD document object

    Returns:
        True if object can be exported
    """
    # Check for Part shapes with volume
    if hasattr(obj, "Shape") and hasattr(obj.Shape, "Volume"):
        if obj.Shape.Volume > 0.001:
            return True
    # Check for Mesh objects
    if hasattr(obj, "Mesh"):
        return True
    return False


def get_exportable_objects(selection: list) -> list:
    """Filter selection to only include exportable objects.

    Args:
        selection: List of selected FreeCAD objects

    Returns:
        List of objects that can be exported
    """
    return [obj for obj in selection if is_object_exportable(obj)]


def get_shape_from_object(obj):
    """Extract the exportable shape from a FreeCAD object.

    Args:
        obj: FreeCAD document object

    Returns:
        Part.Shape or Mesh.Mesh

    Raises:
        ValueError: If no exportable shape found
    """
    if hasattr(obj, "Shape"):
        return obj.Shape
    if hasattr(obj, "Mesh"):
        return obj.Mesh
    raise ValueError(f"No exportable shape found in object: {obj.Label}")


def combine_shapes(shapes: list):
    """Combine multiple shapes into a single compound.

    Args:
        shapes: List of Part.Shape objects

    Returns:
        Combined Part.Shape (compound if multiple)
    """
    if len(shapes) == 0:
        raise ValueError("No shapes to combine")
    if len(shapes) == 1:
        return shapes[0]
    return Part.makeCompound(shapes)


def shape_to_mesh(shape, tolerance: float = 0.1) -> Mesh.Mesh:
    """Convert a Part.Shape to a Mesh.

    Args:
        shape: Part.Shape to convert
        tolerance: Tessellation tolerance (lower = finer mesh)

    Returns:
        Mesh.Mesh object
    """
    mesh = Mesh.Mesh()

    if hasattr(shape, "tessellate"):
        # Part.Shape - tessellate it
        vertices, facets = shape.tessellate(tolerance)
        mesh_data = []
        for facet in facets:
            triangle = [
                vertices[facet[0]],
                vertices[facet[1]],
                vertices[facet[2]],
            ]
            mesh_data.append(triangle)
        mesh.addFacets(mesh_data)
    elif hasattr(shape, "Facets"):
        # Already a Mesh
        return shape
    else:
        raise ValueError("Cannot create mesh from shape")

    return mesh


def export_mesh(shape, filepath: str, tolerance: float = 0.1):
    """Export shape as a mesh format (STL, OBJ, PLY, 3MF, AMF).

    Args:
        shape: Part.Shape or Mesh.Mesh to export
        filepath: Output file path
        tolerance: Mesh tessellation tolerance
    """
    mesh = shape_to_mesh(shape, tolerance)
    mesh.write(filepath)


def export_step(shape, filepath: str):
    """Export shape as STEP format.

    Args:
        shape: Part.Shape to export
        filepath: Output file path
    """
    shape.exportStep(filepath)


def export_iges(shape, filepath: str):
    """Export shape as IGES format.

    Args:
        shape: Part.Shape to export
        filepath: Output file path
    """
    shape.exportIges(filepath)


def export_brep(shape, filepath: str):
    """Export shape as BREP format.

    Args:
        shape: Part.Shape to export
        filepath: Output file path
    """
    shape.exportBrep(filepath)


def export_shape(shape, filepath: str, extension: str, tolerance: float = 0.1):
    """Export a shape to the specified format.

    Args:
        shape: Part.Shape or Mesh.Mesh to export
        filepath: Output file path
        extension: Format extension (stl, step, etc.)
        tolerance: Mesh tessellation tolerance (for mesh formats)

    Raises:
        ValueError: If format is not supported
    """
    ext = extension.lower()

    if is_mesh_format(ext):
        export_mesh(shape, filepath, tolerance)
    elif ext == "step":
        export_step(shape, filepath)
    elif ext == "iges":
        export_iges(shape, filepath)
    elif ext == "brep":
        export_brep(shape, filepath)
    else:
        raise ValueError(f"Unsupported format: {extension}")


class MultiExporter:
    """Handles exporting objects to multiple formats."""

    def __init__(self, objects: list, params: dict):
        """Initialize the exporter.

        Args:
            objects: List of FreeCAD objects to export
            params: Export parameters dictionary with keys:
                - directory: Output directory path
                - base_filename: Base filename without extension
                - formats: List of format extensions
                - mesh_tolerance: Tessellation tolerance for mesh formats
        """
        self.objects = objects
        self.params = params
        self.exported_files: list[str] = []
        self.errors: list[str] = []

    def export_all(self, progress_callback=None) -> tuple[list[str], list[str]]:
        """Export objects to all selected formats.

        Args:
            progress_callback: Optional callback(progress_percent, message)

        Returns:
            Tuple of (list of exported files, list of errors)
        """
        formats = self.params["formats"]
        total_exports = len(formats)

        if total_exports == 0:
            return [], ["No formats selected"]

        # Get combined shape
        try:
            shapes = [get_shape_from_object(obj) for obj in self.objects]
            combined_shape = combine_shapes(shapes)
        except ValueError as e:
            return [], [str(e)]

        for i, fmt in enumerate(formats):
            if progress_callback:
                progress = int((i / total_exports) * 100)
                progress_callback(progress, f"Exporting {fmt.upper()}...")

            try:
                filepath = self._export_format(combined_shape, fmt)
                self.exported_files.append(filepath)
                App.Console.PrintMessage(f"Exported: {filepath}\n")
            except Exception as e:  # nosec B112
                error_msg = f"Failed to export {fmt.upper()}: {e!s}"
                self.errors.append(error_msg)
                App.Console.PrintError(f"{error_msg}\n")

        if progress_callback:
            progress_callback(100, "Export complete!")

        return self.exported_files, self.errors

    def _export_format(self, shape, extension: str) -> str:
        """Export to a specific format.

        Args:
            shape: Combined shape to export
            extension: File extension (format identifier)

        Returns:
            Path to the exported file
        """
        filepath = build_export_filepath(
            self.params["directory"],
            self.params["base_filename"],
            extension,
        )

        tolerance = self.params.get("mesh_tolerance", 0.1)
        export_shape(shape, filepath, extension, tolerance)

        return filepath
