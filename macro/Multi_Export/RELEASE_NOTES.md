# Multi Export Macro Release Notes

## Version 0.6.2 (2026-01-18)

Release notes for changes between v0.6.1 and v0.6.2.

### Changed

- **Proper FreeCAD Addon**: Release being added to <https://github.com/spkane/FreeCAD-addons>.
- **Dedicated repository**: Migrated to standalone GitHub repository for independent release cycles
  - New home: <https://github.com/spkane/freecad-macro-3d-print-multi-export>
  - Updated all metadata URLs (`__Web__`, `__Wiki__`, `__Communication__`) to point to new repository
- **Modular architecture**: Refactored into separate modules for better maintainability and testability
  - `multi_export_core.py`: Core logic with `ExportFormat` dataclass and utilities (can be unit tested without FreeCAD)
  - `multi_export_fc.py`: FreeCAD-specific export code
  - `__init__.py`: Package initialization
  - FCMacro now imports from modules when available, falls back to embedded code for standalone use
- **Code modernization**: Added `dataclasses` import and `sys.path` manipulation for module discovery
- **Improved test infrastructure**: Added comprehensive just command tests and pytest fixtures

## Version 0.6.1 (2026-01-12)

Release notes for changes between v0.5.0-beta and v0.6.1.

### Added

- **FreeCAD Addon Manager metadata**: Macro now includes standard metadata fields for better Addon Manager integration
- **FreeCAD Wiki page**: Official wiki documentation at [Macro Multi Export](https://wiki.freecad.org/Macro_Multi_Export)
- **Dialog screenshot**: Added screenshot showing the export dialog

### Changed

- **Minimum FreeCAD version**: Updated requirement from FreeCAD 0.19 to FreeCAD 0.21 (for better 3MF support)
- **Version tracking**: Version now managed via `__Version__` metadata field instead of inline comment

### No Functional Changes

The core export functionality remains unchanged from the beta release:

- Multi-format export (STL, STEP, 3MF, OBJ, IGES, BREP, PLY, AMF)
- Configurable mesh tolerance for tessellated formats
- Batch export with progress feedback
- Format-specific options

This macro is stable for production use.

### Installation

**Via FreeCAD Addon Manager:**

1. Open FreeCAD
2. Go to Macro > Macros...
3. Click "Download" tab
4. Search for "Multi Export"
5. Click Install

**Manual Installation:**

Copy `MultiExport.FCMacro` to your FreeCAD macro directory:

- **macOS**: `~/Library/Application Support/FreeCAD/Macro/`
- **Linux**: `~/.local/share/FreeCAD/Macro/`
- **Windows**: `%APPDATA%/FreeCAD/Macro/`
