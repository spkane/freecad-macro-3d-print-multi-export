# Multi Export

![Macro Icon](https://raw.githubusercontent.com/spkane/freecad-macro-3d-print-multi-export/main/macro/Multi_Export/MultiExport.svg){ width="64" }

**Version:** 0.6.2 | **License:** MIT | **FreeCAD:** 0.21+

A FreeCAD macro that exports selected objects to multiple file formats simultaneously with a single click. Supports 8 formats with smart defaults and configurable mesh quality options.

Perfect for preparing files for 3D printing, CAD interchange, or game asset creation!

## Features

- **Multi-Format Export** - Export to up to 8 different formats at once
- **Smart Defaults** - STL, STEP, and 3MF selected by default
- **Intelligent Path Defaults** - Uses document location and object names automatically
- **Mesh Quality Control** - Adjustable tolerance and deflection for mesh formats
- **Preview Mode** - See exactly what files will be created before exporting
- **Progress Feedback** - Real-time progress bar and status messages
- **Batch Export** - Export multiple selected objects together

## Quick Start

1. **Select objects** in the 3D view (Ctrl+click for multiple)
2. **Run the macro:** Macro → Macros... → MultiExport → Execute
3. **Choose formats** (STL, STEP, 3MF are pre-selected)
4. **Set output location** and filename
5. **Click Export**

## Supported Formats

| Format | Extension | Default | Description |
| --- | --- | --- | --- |
| STL | `.stl` | ✓ | Stereolithography - standard 3D printing |
| STEP | `.step` | ✓ | CAD interchange - preserves geometry |
| 3MF | `.3mf` | ✓ | Modern 3D printing with metadata |
| OBJ | `.obj` | | Wavefront - 3D graphics and games |
| IGES | `.iges` | | Legacy CAD interchange |
| BREP | `.brep` | | OpenCASCADE native - exact geometry |
| PLY | `.ply` | | Polygon file - 3D scanning |
| AMF | `.amf` | | Additive manufacturing format |

## Documentation

- [Installation](installation.md) - How to install the macro
- [Usage Guide](usage.md) - Detailed step-by-step instructions
- [Formats](formats.md) - Detailed format information
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
- [Contributing](contributing.md) - How to contribute
- [Changelog](changelog.md) - Version history

## Links

- [GitHub Repository](https://github.com/spkane/freecad-macro-3d-print-multi-export)
- [Report Issues](https://github.com/spkane/freecad-macro-3d-print-multi-export/issues)
- [FreeCAD Wiki](https://wiki.freecad.org/Macro_Multi_Export)
