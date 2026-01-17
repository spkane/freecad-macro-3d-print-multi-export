# Usage Guide

## Quick Start

1. **Select objects** in the 3D view (Ctrl+click for multiple)
2. **Run the macro:** Macro → Macros... → MultiExport → Execute
3. **Choose formats** (STL, STEP, 3MF are pre-selected)
4. **Set output location** and filename
5. **Click Export**

## Detailed Steps

### Step 1: Select Objects

- Click on one or more objects in the 3D view
- Hold `Ctrl` (or `Cmd` on macOS) to select multiple objects
- Selected objects appear in the "Objects to Export" list

### Step 2: Choose Export Formats

The dialog shows all available formats with checkboxes:

- **STL** - Checked by default (3D printing standard)
- **STEP** - Checked by default (CAD interchange)
- **3MF** - Checked by default (modern 3D printing)

Quick selection buttons:

- **Select All** - Check all formats
- **Select None** - Uncheck all formats
- **Reset Defaults** - Return to STL + STEP + 3MF

### Step 3: Configure Output

**Directory:**

- Defaults to the same folder as the current FreeCAD document
- Click **Browse...** to choose a different location

**Base Filename:**

- Defaults to the selected object's label (single object)
- Or the document name (multiple objects)
- Enter any name (without extension)
- Extensions are added automatically based on selected formats

**Preview:**

- Shows the files that will be created
- Updates in real-time as you change options

### Step 4: Mesh Options (Optional)

For mesh formats (STL, OBJ, PLY, 3MF, AMF):

**Surface Tolerance:**

- Lower values = finer mesh = larger files
- Default: 0.1mm (good balance)
- For fine details: 0.01-0.05mm
- For quick exports: 0.2-0.5mm

**Angular Deflection:**

- Controls curved surface approximation
- Default: 0.1mm
- Lower values = smoother curves

### Step 5: Export

- Click **Export**
- Watch the progress bar
- Review results in the status area

---

## Common Use Cases

### 3D Printing Preparation

**Scenario:** Export a model for printing on different slicers

**Settings:**

- Formats: STL + 3MF
- Tolerance: 0.1mm (standard quality)

**Result:** Files ready for Cura, PrusaSlicer, Bambu Studio, etc.

### Sharing with CAD Users

**Scenario:** Send design to colleague using SolidWorks

**Settings:**

- Formats: STEP + IGES
- (Mesh settings don't apply to these formats)

**Result:** Editable CAD files that preserve exact geometry

### Game Asset Export

**Scenario:** Create 3D model for Unity/Unreal

**Settings:**

- Formats: OBJ + PLY
- Tolerance: 0.05mm (good detail)

**Result:** Standard mesh formats for game engines

### Complete Backup

**Scenario:** Archive a project in all formats

**Settings:**

- Click **Select All** for all formats
- Directory: Your backup location

**Result:** Complete export in 8 formats for future compatibility

---

## Parameters Reference

### Output Configuration

| Parameter | Default | Description |
| --- | --- | --- |
| Directory | Document location | Where to save exported files |
| Base Filename | Object/Doc label | Filename without extension |

### Mesh Settings

| Parameter | Default | Range | Description |
| --- | --- | --- | --- |
| Surface Tolerance | 0.1mm | 0.001-10mm | Mesh fineness (lower = finer) |
| Angular Deflection | 0.1mm | 0.001-10mm | Curved surface approximation |
