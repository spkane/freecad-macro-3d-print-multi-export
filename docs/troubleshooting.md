# Troubleshooting

## Common Errors

### "No Selection"

**Cause:** No objects are selected in the 3D view.

**Solution:** Select one or more objects in the 3D view before running the macro.

---

### "No Exportable Objects"

**Cause:** Selected items are not solid objects (groups, annotations, etc.)

**Solution:** Select actual Part or PartDesign bodies with solid geometry.

---

### "Invalid Directory"

**Cause:** The chosen directory doesn't exist.

**Solution:** Click Browse and select a valid folder.

---

### "Format export failed"

**Possible causes:**

1. **Object has invalid geometry**
    - Try Part → Check Geometry first
    - Use Part → Refine Shape to clean up geometry

2. **Disk full**
    - Check available disk space

3. **Permission denied**
    - Choose a folder you have write access to

---

### Export produces empty or corrupted files

**Possible causes:**

1. **Object is a shell, not a solid**
    - Check if object is a valid solid
    - Use Part → Check Geometry

2. **Mesh tolerance too high**
    - Lower the surface tolerance value
    - Try 0.01mm for fine details

3. **Object has self-intersecting faces**
    - Repair geometry before exporting

---

## Quality Issues

### STL has visible facets/triangles

**Cause:** Mesh tolerance is too high.

**Solution:**

- Lower surface tolerance (try 0.05mm or 0.01mm)
- Lower angular deflection for curved surfaces

### File is too large

**Cause:** Mesh tolerance is too low, creating very detailed mesh.

**Solution:**

- Increase surface tolerance (try 0.2mm or 0.5mm)
- Use CAD formats (STEP) when detail isn't needed

### Colors not exported

**Cause:** Most formats don't support color.

**Solution:**

- Use 3MF or OBJ with MTL for color support
- Export materials separately if needed

---

## Performance Issues

### Macro is slow to export

**Possible causes:**

1. **Very complex geometry**
    - Simplify the model before exporting
    - Use higher mesh tolerance

2. **Many objects selected**
    - Export in smaller batches

3. **Very low mesh tolerance**
    - Increase tolerance for faster exports

### FreeCAD freezes during export

**Possible causes:**

1. **Extremely complex mesh**
    - Use higher tolerance values
    - Export one object at a time

2. **Insufficient memory**
    - Close other applications
    - Export in smaller batches

---

## Getting Help

If you encounter an issue not covered here:

1. Check the [GitHub Issues](https://github.com/spkane/freecad-macro-3d-print-multi-export/issues) for similar problems
2. Open a new issue with:
    - FreeCAD version
    - Operating system
    - Steps to reproduce
    - Error message (if any)
    - Object type and complexity (if relevant)
