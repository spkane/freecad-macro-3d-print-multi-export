# Multi Export - FreeCAD Macro

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FreeCAD](https://img.shields.io/badge/FreeCAD-0.21+-blue.svg)](https://www.freecadweb.org/)
[![Python](https://img.shields.io/badge/Python-3.11+-3776ab.svg)](https://www.python.org/)
[![Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://spkane.github.io/freecad-macro-3d-print-multi-export/)

[![Tests](https://github.com/spkane/freecad-macro-3d-print-multi-export/actions/workflows/tests.yaml/badge.svg)](https://github.com/spkane/freecad-macro-3d-print-multi-export/actions/workflows/tests.yaml)
[![Pre-commit](https://github.com/spkane/freecad-macro-3d-print-multi-export/actions/workflows/pre-commit.yaml/badge.svg)](https://github.com/spkane/freecad-macro-3d-print-multi-export/actions/workflows/pre-commit.yaml)
[![CodeQL](https://github.com/spkane/freecad-macro-3d-print-multi-export/actions/workflows/codeql.yaml/badge.svg)](https://github.com/spkane/freecad-macro-3d-print-multi-export/actions/workflows/codeql.yaml)

![Macro Icon](macro/Multi_Export/MultiExport.svg)

**Version:** 0.6.1

A FreeCAD macro that exports selected objects to multiple file formats simultaneously with a single click. Supports 8 formats with smart defaults and configurable mesh quality options.

## Features

- **Multi-Format Export** - Export to up to 8 different formats at once
- **Smart Defaults** - STL, STEP, and 3MF selected by default (most common formats)
- **Intelligent Path Defaults** - Uses document location and object names automatically
- **Mesh Quality Control** - Adjustable tolerance and deflection for mesh formats
- **Preview Mode** - See exactly what files will be created before exporting
- **Progress Feedback** - Real-time progress bar and status messages
- **Batch Export** - Export multiple selected objects together

## Quick Start

1. Open your model in FreeCAD
2. Select one or more objects (Ctrl+click for multiple)
3. Run the macro: **Macro -> Macros... -> MultiExport -> Execute**
4. Choose export formats (checkboxes)
5. Set output directory and base filename
6. Click **Export**

## Installation

### From FreeCAD Addon Manager (Recommended)

1. Open FreeCAD
2. Go to **Tools -> Addon Manager**
3. Search for "Multi Export"
4. Click **Install**
5. Restart FreeCAD

### Manual Installation

Download `MultiExport.FCMacro` and `MultiExport.svg` from the `macro/Multi_Export/` directory and copy them to your FreeCAD macro folder:

- **macOS**: `~/Library/Application Support/FreeCAD/Macro/`
- **Linux**: `~/.local/share/FreeCAD/Macro/` or `~/.FreeCAD/Macro/`
- **Windows**: `%APPDATA%/FreeCAD/Macro/`

## Supported Formats

| Format | Extension | Default | Description |
| --- | --- | --- | --- |
| STL | `.stl` | Yes | Stereolithography - standard 3D printing |
| STEP | `.step` | Yes | CAD interchange - preserves geometry |
| 3MF | `.3mf` | Yes | Modern 3D printing with metadata |
| OBJ | `.obj` | No | Wavefront - 3D graphics and games |
| IGES | `.iges` | No | Legacy CAD interchange |
| BREP | `.brep` | No | OpenCASCADE native - exact geometry |
| PLY | `.ply` | No | Polygon file - 3D scanning |
| AMF | `.amf` | No | Additive manufacturing format |

## Parameters

| Parameter | Description | Default |
| --- | --- | --- |
| Directory | Where to save exported files | Document location |
| Base Filename | Filename without extension | Object/Doc label |
| Surface Tolerance | Mesh fineness (lower = finer) | 0.1mm |
| Angular Deflection | Curved surface approximation | 0.1mm |

## Common Use Cases

### 3D Printing Preparation

```text
Formats: STL + 3MF, Tolerance: 0.1mm
```

Export files ready for Cura, PrusaSlicer, Bambu Studio, etc.

### Sharing with CAD Users

```text
Formats: STEP + IGES
```

Editable CAD files that preserve exact geometry for SolidWorks, Fusion 360, etc.

### Game Asset Export

```text
Formats: OBJ + PLY, Tolerance: 0.05mm
```

Standard mesh formats for Unity, Unreal, Blender, etc.

### Complete Backup

```text
Formats: Select All
```

Export in all 8 formats for future compatibility.

## Documentation

For detailed documentation including:

- Step-by-step installation guides
- Detailed usage instructions
- Troubleshooting tips
- Technical details

See the [full documentation](macro/Multi_Export/README-MultiExport.md).

## Requirements

- FreeCAD 0.21 or later (0.19+ may work)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Created for the FreeCAD community to simplify the export workflow and eliminate repetitive export operations.
