# Supported Formats

## Overview

| Format | Extension | Default | Best For |
| --- | --- | --- | --- |
| STL | `.stl` | ✓ | 3D printing |
| STEP | `.step` | ✓ | CAD interchange |
| 3MF | `.3mf` | ✓ | Modern 3D printing |
| OBJ | `.obj` | | Game engines |
| IGES | `.iges` | | Legacy CAD |
| BREP | `.brep` | | OpenCASCADE |
| PLY | `.ply` | | 3D scanning |
| AMF | `.amf` | | Additive manufacturing |

---

## Format Details

### STL (Stereolithography)

**Extension:** `.stl`
**Default:** Yes

The most widely supported 3D printing format. Stores only geometry as triangular mesh.

**Pros:**

- Universal support in all slicers
- Simple format, small file size
- Fast to process

**Cons:**

- No color or material information
- No units (assumed mm usually)
- No metadata

**Best for:** 3D printing, rapid prototyping

---

### STEP (Standard for Exchange of Product Data)

**Extension:** `.step`
**Default:** Yes

ISO standard for CAD data exchange. Preserves exact geometry (BREP).

**Pros:**

- Exact geometry preservation
- Editable in CAD software
- Industry standard

**Cons:**

- Larger file sizes
- Not suitable for 3D printing directly

**Best for:** Sharing with other CAD users, engineering collaboration

---

### 3MF (3D Manufacturing Format)

**Extension:** `.3mf`
**Default:** Yes

Modern 3D printing format developed by Microsoft and industry consortium.

**Pros:**

- Supports color and materials
- Includes metadata (units, author, etc.)
- Smaller than STL for same quality
- Better error handling

**Cons:**

- Newer format, not universally supported
- Some slicers have limited 3MF support

**Best for:** Modern 3D printing with metadata, color prints

---

### OBJ (Wavefront)

**Extension:** `.obj`
**Default:** No

Standard format for 3D graphics and game engines.

**Pros:**

- Supports materials (MTL files)
- Wide support in 3D software
- Human-readable ASCII format

**Cons:**

- No native color support without MTL
- Large file sizes for ASCII version

**Best for:** Game engines, 3D graphics, visualization

---

### IGES (Initial Graphics Exchange Specification)

**Extension:** `.iges`
**Default:** No

Older CAD interchange format, predecessor to STEP.

**Pros:**

- Wide legacy support
- Preserves curves and surfaces

**Cons:**

- Outdated standard
- Can lose some geometry details
- Larger than STEP

**Best for:** Legacy CAD systems, older software compatibility

---

### BREP (Boundary Representation)

**Extension:** `.brep`
**Default:** No

OpenCASCADE native format for exact geometry.

**Pros:**

- Exact geometry preservation
- Native FreeCAD format
- No conversion losses

**Cons:**

- Only works with OpenCASCADE-based software
- Not widely supported

**Best for:** FreeCAD archives, OpenCASCADE workflows

---

### PLY (Polygon File Format)

**Extension:** `.ply`
**Default:** No

Stanford format commonly used in 3D scanning.

**Pros:**

- Supports vertex colors
- Simple ASCII or binary format
- Good for point clouds

**Cons:**

- No material support
- Less common in CAD

**Best for:** 3D scanning, point clouds, research

---

### AMF (Additive Manufacturing File Format)

**Extension:** `.amf`
**Default:** No

XML-based format designed for additive manufacturing.

**Pros:**

- Supports color and materials
- Curved surfaces (not just triangles)
- Units included in format

**Cons:**

- Limited slicer support
- Large file sizes (XML)

**Best for:** Advanced 3D printing features, color printing

---

## Export Methods

| Format | Export Method |
| --- | --- |
| STL | Mesh tessellation → Mesh.write() |
| STEP | Part.Shape.exportStep() |
| 3MF | Mesh tessellation → Mesh.write() |
| OBJ | Mesh tessellation → Mesh.write() |
| IGES | Part.Shape.exportIges() |
| BREP | Part.Shape.exportBrep() |
| PLY | Mesh tessellation → Mesh.write() |
| AMF | Mesh tessellation → Mesh.write() |

---

## Multiple Objects

When multiple objects are selected:

- **Mesh formats:** Objects are combined into a single compound mesh
- **CAD formats:** Objects are combined into a Part.Compound
