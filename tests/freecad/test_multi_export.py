"""FreeCAD integration tests for Multi Export macro.

These tests must be run inside FreeCAD using:
    freecad -c tests/freecad/test_multi_export.py

Or via the test runner script:
    just test-freecad
"""

import os
import sys
import tempfile
import unittest

# Add the macro directory to path
TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(TESTS_DIR))
MACRO_DIR = os.path.join(PROJECT_ROOT, "macro", "Multi_Export")
sys.path.insert(0, MACRO_DIR)

import FreeCAD as App  # noqa: E402
import Part  # noqa: E402

# Import from our modules
from multi_export_fc import (  # noqa: E402
    MultiExporter,
    combine_shapes,
    export_brep,
    export_mesh,
    export_shape,
    export_step,
    get_exportable_objects,
    get_object_type,
    get_shape_from_object,
    is_object_exportable,
    shape_to_mesh,
)


class TestGetObjectType(unittest.TestCase):
    """Tests for get_object_type function."""

    def setUp(self):
        """Create a test document."""
        self.doc = App.newDocument("TestDoc")

    def tearDown(self):
        """Close the test document."""
        App.closeDocument(self.doc.Name)

    def test_part_box_type(self):
        """Test type detection for Part::Box."""
        box = self.doc.addObject("Part::Box", "TestBox")
        self.doc.recompute()
        obj_type = get_object_type(box)
        self.assertEqual(obj_type, "Box")

    def test_part_cylinder_type(self):
        """Test type detection for Part::Cylinder."""
        cyl = self.doc.addObject("Part::Cylinder", "TestCylinder")
        self.doc.recompute()
        obj_type = get_object_type(cyl)
        self.assertEqual(obj_type, "Cylinder")


class TestIsObjectExportable(unittest.TestCase):
    """Tests for is_object_exportable function."""

    def setUp(self):
        """Create a test document."""
        self.doc = App.newDocument("TestDoc")

    def tearDown(self):
        """Close the test document."""
        App.closeDocument(self.doc.Name)

    def test_box_is_exportable(self):
        """Test that a Part::Box is exportable."""
        box = self.doc.addObject("Part::Box", "TestBox")
        self.doc.recompute()
        self.assertTrue(is_object_exportable(box))

    def test_empty_sketch_not_exportable(self):
        """Test that an empty sketch is not exportable."""
        # A sketch without extrusion has no volume
        sketch = self.doc.addObject("Sketcher::SketchObject", "TestSketch")
        self.doc.recompute()
        self.assertFalse(is_object_exportable(sketch))


class TestGetExportableObjects(unittest.TestCase):
    """Tests for get_exportable_objects function."""

    def setUp(self):
        """Create a test document with various objects."""
        self.doc = App.newDocument("TestDoc")
        self.box = self.doc.addObject("Part::Box", "TestBox")
        self.cylinder = self.doc.addObject("Part::Cylinder", "TestCylinder")
        self.doc.recompute()

    def tearDown(self):
        """Close the test document."""
        App.closeDocument(self.doc.Name)

    def test_filters_exportable(self):
        """Test that only exportable objects are returned."""
        all_objects = [self.box, self.cylinder]
        exportable = get_exportable_objects(all_objects)
        self.assertEqual(len(exportable), 2)

    def test_empty_list_returns_empty(self):
        """Test that empty list returns empty list."""
        exportable = get_exportable_objects([])
        self.assertEqual(exportable, [])


class TestGetShapeFromObject(unittest.TestCase):
    """Tests for get_shape_from_object function."""

    def setUp(self):
        """Create a test document."""
        self.doc = App.newDocument("TestDoc")

    def tearDown(self):
        """Close the test document."""
        App.closeDocument(self.doc.Name)

    def test_get_shape_from_box(self):
        """Test getting shape from Part::Box."""
        box = self.doc.addObject("Part::Box", "TestBox")
        self.doc.recompute()
        shape = get_shape_from_object(box)
        self.assertIsInstance(shape, Part.Shape)


class TestCombineShapes(unittest.TestCase):
    """Tests for combine_shapes function."""

    def setUp(self):
        """Create a test document."""
        self.doc = App.newDocument("TestDoc")

    def tearDown(self):
        """Close the test document."""
        App.closeDocument(self.doc.Name)

    def test_single_shape(self):
        """Test combining a single shape returns that shape."""
        box = self.doc.addObject("Part::Box", "TestBox")
        self.doc.recompute()
        shapes = [box.Shape]
        combined = combine_shapes(shapes)
        self.assertIsInstance(combined, Part.Shape)

    def test_multiple_shapes(self):
        """Test combining multiple shapes creates a compound."""
        box = self.doc.addObject("Part::Box", "TestBox")
        cyl = self.doc.addObject("Part::Cylinder", "TestCylinder")
        self.doc.recompute()
        shapes = [box.Shape, cyl.Shape]
        combined = combine_shapes(shapes)
        self.assertIsInstance(combined, Part.Shape)
        # Compound should contain both shapes
        self.assertGreater(combined.Volume, box.Shape.Volume)

    def test_empty_list_raises(self):
        """Test that empty list raises ValueError."""
        with self.assertRaises(ValueError):
            combine_shapes([])


class TestShapeToMesh(unittest.TestCase):
    """Tests for shape_to_mesh function."""

    def setUp(self):
        """Create a test document."""
        self.doc = App.newDocument("TestDoc")

    def tearDown(self):
        """Close the test document."""
        App.closeDocument(self.doc.Name)

    def test_box_to_mesh(self):
        """Test converting a box to mesh."""
        import Mesh

        box = self.doc.addObject("Part::Box", "TestBox")
        self.doc.recompute()
        mesh = shape_to_mesh(box.Shape, tolerance=0.1)
        self.assertIsInstance(mesh, Mesh.Mesh)
        # Box should have triangulated faces
        self.assertGreater(mesh.CountFacets, 0)


class TestExportFunctions(unittest.TestCase):
    """Tests for individual export functions."""

    def setUp(self):
        """Create a test document and temp directory."""
        self.doc = App.newDocument("TestDoc")
        self.box = self.doc.addObject("Part::Box", "TestBox")
        self.doc.recompute()
        self.temp_dir = tempfile.mkdtemp()

    def tearDown(self):
        """Close the test document and clean up temp files."""
        App.closeDocument(self.doc.Name)
        # Clean up temp files
        import shutil

        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_export_step(self):
        """Test STEP export."""
        filepath = os.path.join(self.temp_dir, "test.step")
        export_step(self.box.Shape, filepath)
        self.assertTrue(os.path.exists(filepath))
        self.assertGreater(os.path.getsize(filepath), 0)

    def test_export_brep(self):
        """Test BREP export."""
        filepath = os.path.join(self.temp_dir, "test.brep")
        export_brep(self.box.Shape, filepath)
        self.assertTrue(os.path.exists(filepath))
        self.assertGreater(os.path.getsize(filepath), 0)

    def test_export_mesh_stl(self):
        """Test STL mesh export."""
        filepath = os.path.join(self.temp_dir, "test.stl")
        export_mesh(self.box.Shape, filepath, tolerance=0.1)
        self.assertTrue(os.path.exists(filepath))
        self.assertGreater(os.path.getsize(filepath), 0)

    def test_export_shape_step(self):
        """Test export_shape with STEP format."""
        filepath = os.path.join(self.temp_dir, "test.step")
        export_shape(self.box.Shape, filepath, "step")
        self.assertTrue(os.path.exists(filepath))

    def test_export_shape_stl(self):
        """Test export_shape with STL format."""
        filepath = os.path.join(self.temp_dir, "test.stl")
        export_shape(self.box.Shape, filepath, "stl")
        self.assertTrue(os.path.exists(filepath))


class TestMultiExporter(unittest.TestCase):
    """Tests for MultiExporter class."""

    def setUp(self):
        """Create a test document and temp directory."""
        self.doc = App.newDocument("TestDoc")
        self.box = self.doc.addObject("Part::Box", "TestBox")
        self.box.Length = 10
        self.box.Width = 10
        self.box.Height = 10
        self.doc.recompute()
        self.temp_dir = tempfile.mkdtemp()

    def tearDown(self):
        """Close the test document and clean up temp files."""
        App.closeDocument(self.doc.Name)
        import shutil

        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_export_single_format(self):
        """Test exporting to a single format."""
        params = {
            "directory": self.temp_dir,
            "base_filename": "test",
            "formats": ["stl"],
            "mesh_tolerance": 0.1,
        }
        exporter = MultiExporter([self.box], params)
        exported, errors = exporter.export_all()

        self.assertEqual(len(exported), 1)
        self.assertEqual(len(errors), 0)
        self.assertTrue(os.path.exists(os.path.join(self.temp_dir, "test.stl")))

    def test_export_multiple_formats(self):
        """Test exporting to multiple formats."""
        params = {
            "directory": self.temp_dir,
            "base_filename": "test",
            "formats": ["stl", "step", "brep"],
            "mesh_tolerance": 0.1,
        }
        exporter = MultiExporter([self.box], params)
        exported, errors = exporter.export_all()

        self.assertEqual(len(exported), 3)
        self.assertEqual(len(errors), 0)
        self.assertTrue(os.path.exists(os.path.join(self.temp_dir, "test.stl")))
        self.assertTrue(os.path.exists(os.path.join(self.temp_dir, "test.step")))
        self.assertTrue(os.path.exists(os.path.join(self.temp_dir, "test.brep")))

    def test_export_no_formats(self):
        """Test that empty formats list returns error."""
        params = {
            "directory": self.temp_dir,
            "base_filename": "test",
            "formats": [],
            "mesh_tolerance": 0.1,
        }
        exporter = MultiExporter([self.box], params)
        exported, errors = exporter.export_all()

        self.assertEqual(len(exported), 0)
        self.assertGreater(len(errors), 0)

    def test_export_with_progress_callback(self):
        """Test that progress callback is called."""
        progress_values = []

        def callback(progress, message):
            progress_values.append((progress, message))

        params = {
            "directory": self.temp_dir,
            "base_filename": "test",
            "formats": ["stl", "step"],
            "mesh_tolerance": 0.1,
        }
        exporter = MultiExporter([self.box], params)
        exporter.export_all(progress_callback=callback)

        self.assertGreater(len(progress_values), 0)
        # Should end with 100%
        self.assertEqual(progress_values[-1][0], 100)


def run_tests():
    """Run all tests and return the result."""
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromModule(sys.modules[__name__])
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    return result


if __name__ == "__main__":
    result = run_tests()
    # Exit with appropriate code for CI
    sys.exit(0 if result.wasSuccessful() else 1)
