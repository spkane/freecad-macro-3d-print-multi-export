# Installation commands for users
# Usage: just install::macro, just install::uninstall, etc.
#
# This module installs the Multi Export macro to FreeCAD's Macro directory.

# Project root directory
project_root := justfile_directory()

# Macro name and source directory
macro_name := "Multi_Export"
macro_source := project_root + "/macro/" + macro_name

# =============================================================================
# Helper: FreeCAD Directory Detection
# =============================================================================
# This function sets MACRO_DIR based on the current OS.
# Source it at the start of any recipe that needs FreeCAD paths.
#
# Usage in recipes:
#   eval "$(just install::_freecad-dirs)"
#   echo "Macro directory: $MACRO_DIR"

# Private recipe that outputs shell code to set FreeCAD directories
[private]
_freecad-dirs:
    #!/usr/bin/env bash
    cat << 'DIRS_EOF'
    # Determine base FreeCAD directory based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        FREECAD_BASE="$HOME/Library/Application Support/FreeCAD"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        FREECAD_BASE="$HOME/.local/share/FreeCAD"
    else
        # Windows: validate APPDATA or use fallback
        if [[ -n "$APPDATA" ]]; then
            FREECAD_BASE="$APPDATA/FreeCAD"
        elif [[ -n "$HOME" ]]; then
            FREECAD_BASE="$HOME/AppData/Roaming/FreeCAD"
            echo "Warning: APPDATA not set, using fallback: $FREECAD_BASE" >&2
        else
            echo "Error: Neither APPDATA nor HOME is set. Cannot determine FreeCAD directory." >&2
            exit 1
        fi
    fi

    # FreeCAD 1.x+ uses versioned directories (v1-1, v1-2, v2-0, etc.)
    # Find the latest versioned directory if present
    VERSIONED_DIR=""
    if [[ -d "$FREECAD_BASE" ]]; then
        # Use sort -V for proper version sorting (handles v1-10 > v1-2 correctly)
        LATEST_VERSION=$(ls -d "$FREECAD_BASE"/v*-* 2>/dev/null | sort -V | tail -n 1)
        if [[ -n "$LATEST_VERSION" && -d "$LATEST_VERSION" ]]; then
            VERSIONED_DIR="$LATEST_VERSION"
        fi
    fi

    # Use versioned directory if found, otherwise use base directory
    if [[ -n "$VERSIONED_DIR" ]]; then
        MACRO_DIR="$VERSIONED_DIR/Macro"
        echo "Note: Using FreeCAD versioned directory: $VERSIONED_DIR" >&2
    else
        MACRO_DIR="$FREECAD_BASE/Macro"
    fi
    DIRS_EOF

# =============================================================================
# Macro Installation
# =============================================================================

# Install the Multi Export macro to FreeCAD's Macro directory
macro:
    #!/usr/bin/env bash
    set -euo pipefail
    MACRO_NAME="{{macro_name}}"
    MACRO_SRC="{{macro_source}}"

    # Set FreeCAD directories
    eval "$(just install::_freecad-dirs)"

    MACRO_DEST="$MACRO_DIR/$MACRO_NAME"

    # Verify source exists
    if [[ ! -d "$MACRO_SRC" ]]; then
        echo "Error: Macro source directory not found: $MACRO_SRC" >&2
        exit 1
    fi

    # Create Macro directory if it doesn't exist
    mkdir -p "$MACRO_DIR"

    # Remove existing installation if present
    if [[ -d "$MACRO_DEST" ]]; then
        echo "Removing existing installation at: $MACRO_DEST"
        rm -rf "$MACRO_DEST"
    fi

    # Copy the macro directory
    cp -r "$MACRO_SRC" "$MACRO_DEST"

    echo ""
    echo "=========================================="
    echo "Multi Export macro installed!"
    echo "=========================================="
    echo ""
    echo "Installation path: $MACRO_DEST"
    echo ""
    echo "To use:"
    echo "  1. Start FreeCAD"
    echo "  2. Go to Macro > Macros..."
    echo "  3. Select 'MultiExport' and click 'Execute'"
    echo ""

# Uninstall the Multi Export macro
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    MACRO_NAME="{{macro_name}}"

    # Set FreeCAD directories
    eval "$(just install::_freecad-dirs)"

    MACRO_DEST="$MACRO_DIR/$MACRO_NAME"

    if [[ -d "$MACRO_DEST" ]]; then
        rm -rf "$MACRO_DEST"
        echo "Multi Export macro uninstalled from: $MACRO_DEST"
    else
        echo "Macro not found at: $MACRO_DEST"
    fi

# Cleanup (alias for uninstall)
cleanup: uninstall

# =============================================================================
# Status Check
# =============================================================================

# Check installation status of the macro
status:
    #!/usr/bin/env bash
    set -euo pipefail
    MACRO_NAME="{{macro_name}}"

    # Set FreeCAD directories
    eval "$(just install::_freecad-dirs)"

    MACRO_DEST="$MACRO_DIR/$MACRO_NAME"

    # Helper function to get file modification time (cross-platform)
    get_mod_time() {
        local file="$1"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || echo "unknown"
        else
            stat -c "%y" "$file" 2>/dev/null | cut -d'.' -f1 || echo "unknown"
        fi
    }

    echo "=========================================="
    echo "Installation Status"
    echo "=========================================="
    echo ""

    if [[ -d "$MACRO_DEST" ]]; then
        MACRO_FILE="$MACRO_DEST/MultiExport.FCMacro"
        if [[ -f "$MACRO_FILE" ]]; then
            MACRO_MOD_TIME=$(get_mod_time "$MACRO_FILE")
            echo "✓ Multi Export: INSTALLED"
            echo "  Updated: $MACRO_MOD_TIME"
            echo "  Path: $MACRO_DEST"
        else
            echo "⚠ Multi Export: INCOMPLETE"
            echo "  Path exists but FCMacro file missing"
            echo "  Reinstall: just install::macro"
        fi
    else
        echo "✗ Multi Export: NOT INSTALLED"
        echo "  Install: just install::macro"
    fi
    echo ""
    echo "=========================================="
