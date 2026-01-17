# Installation

## From FreeCAD Addon Manager (Recommended)

1. Open FreeCAD
2. Go to **Tools → Addon Manager**
3. Search for "Multi Export"
4. Click **Install**
5. Restart FreeCAD

## Manual Installation

### macOS

#### Step 1: Locate Your FreeCAD Macros Folder

The macros folder location on macOS:

```text
~/Library/Application Support/FreeCAD/Macro/
```

**How to access it:**

**Option A - Finder (Recommended):**

1. Open **Finder**
2. Press `Cmd + Shift + G` (Go to Folder)
3. Paste: `~/Library/Application Support/FreeCAD/Macro/`
4. Press **Enter**

**Option B - Terminal:**

```bash
mkdir -p ~/Library/Application\ Support/FreeCAD/Macro/
open ~/Library/Application\ Support/FreeCAD/Macro/
```

**Option C - From FreeCAD:**

1. Open FreeCAD
2. Go to **Macro → Macros...**
3. Note the path shown at the top of the dialog
4. Click **User macros location** to open in Finder

#### Step 2: Install the Macro File

1. Download `MultiExport.FCMacro` from the [releases page](https://github.com/spkane/freecad-macro-3d-print-multi-export/releases)
2. Copy it to the macros folder
3. (Optional) Copy `MultiExport.svg` for the icon

#### Step 3: Verify Installation

1. Open FreeCAD
2. Go to **Macro → Macros...**
3. You should see "MultiExport" in the list

### Linux

```bash
# Create macros directory if it doesn't exist
mkdir -p ~/.local/share/FreeCAD/Macro/

# Copy macro file
cp MultiExport.FCMacro ~/.local/share/FreeCAD/Macro/

# (Optional) Copy icon
cp MultiExport.svg ~/.local/share/FreeCAD/Macro/
```

!!! note "Alternative path"
    Some Linux distributions use `~/.FreeCAD/Macro/` instead.

### Windows

1. Navigate to: `%APPDATA%\FreeCAD\Macro\`
2. Copy `MultiExport.FCMacro` to this folder
3. (Optional) Copy `MultiExport.svg` to the same folder

## Create a Toolbar Button (Optional)

1. Go to **Macro → Macros...**
2. Select **MultiExport**
3. Click **Create** (toolbar button icon)
4. Choose the icon file (`MultiExport.svg`) if you saved it
5. The macro will now appear in your toolbar for quick access
