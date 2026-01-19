# Installation commands for users
# Usage: just install::addon, just install::uninstall, etc.
#
# This module installs the Multi Export macro as a FreeCAD addon to the Mod directory,
# mimicking how the FreeCAD Addon Manager installs packages.

# Project root directory
project_root := justfile_directory()

# Addon name (used for the Mod directory)
addon_name := "freecad-macro-3d-print-multi-export"

# =============================================================================
# Helper: FreeCAD Directory Detection
# =============================================================================
# This function sets MOD_DIR and MACRO_DIR based on the current OS.
# Source it at the start of any recipe that needs FreeCAD paths.
#
# Usage in recipes:
#   eval "$(just install::_freecad-dirs)"
#   echo "Mod directory: $MOD_DIR"

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
        MOD_DIR="$VERSIONED_DIR/Mod"
        MACRO_DIR="$VERSIONED_DIR/Macro"
        echo "Note: Using FreeCAD versioned directory: $VERSIONED_DIR" >&2
    else
        MOD_DIR="$FREECAD_BASE/Mod"
        MACRO_DIR="$FREECAD_BASE/Macro"
    fi
    DIRS_EOF

# =============================================================================
# Addon Installation (like Addon Manager)
# =============================================================================

# Install the Multi Export addon to FreeCAD's Mod directory (like Addon Manager)
addon:
    #!/usr/bin/env bash
    set -euo pipefail
    ADDON_NAME="{{addon_name}}"
    PROJECT_ROOT="{{project_root}}"

    # Set FreeCAD directories
    eval "$(just install::_freecad-dirs)"

    ADDON_DEST="$MOD_DIR/$ADDON_NAME"

    # Verify source exists
    if [[ ! -f "$PROJECT_ROOT/package.xml" ]]; then
        echo "Error: package.xml not found in project root: $PROJECT_ROOT" >&2
        exit 1
    fi

    # Create Mod directory if it doesn't exist
    mkdir -p "$MOD_DIR"

    # Remove existing installation if present
    if [[ -d "$ADDON_DEST" ]]; then
        echo "Removing existing installation at: $ADDON_DEST"
        rm -rf "$ADDON_DEST"
    fi

    # Create addon directory
    mkdir -p "$ADDON_DEST"

    # Copy essential files (mimicking Addon Manager clone)
    echo "Installing addon to: $ADDON_DEST"

    # Copy package.xml (required for FreeCAD to recognize the addon)
    cp "$PROJECT_ROOT/package.xml" "$ADDON_DEST/"

    # Copy the macro directory with all its contents
    cp -r "$PROJECT_ROOT/macro" "$ADDON_DEST/"

    # Copy LICENSE if present
    if [[ -f "$PROJECT_ROOT/LICENSE" ]]; then
        cp "$PROJECT_ROOT/LICENSE" "$ADDON_DEST/"
    fi

    # Copy README if present
    if [[ -f "$PROJECT_ROOT/README.md" ]]; then
        cp "$PROJECT_ROOT/README.md" "$ADDON_DEST/"
    fi

    # Create symlink in Macro directory (mimics Addon Manager behavior)
    # This makes the macro visible in Macro > Macros... menu
    mkdir -p "$MACRO_DIR"
    MACRO_SYMLINK="$MACRO_DIR/MultiExport.FCMacro"
    MACRO_TARGET="$ADDON_DEST/macro/Multi_Export/MultiExport.FCMacro"

    # Remove existing symlink if present
    if [[ -L "$MACRO_SYMLINK" ]]; then
        rm "$MACRO_SYMLINK"
    elif [[ -f "$MACRO_SYMLINK" ]]; then
        echo "Warning: $MACRO_SYMLINK exists as a file, not a symlink. Backing up..."
        mv "$MACRO_SYMLINK" "$MACRO_SYMLINK.backup"
    fi

    # Create new symlink
    ln -s "$MACRO_TARGET" "$MACRO_SYMLINK"
    echo "Created macro symlink: $MACRO_SYMLINK -> $MACRO_TARGET"

    echo ""
    echo "=========================================="
    echo "Multi Export addon installed!"
    echo "=========================================="
    echo ""
    echo "Installation path: $ADDON_DEST"
    echo "Macro symlink:     $MACRO_SYMLINK"
    echo ""
    echo "To use:"
    echo "  1. Start (or restart) FreeCAD"
    echo "  2. Go to Macro > Macros..."
    echo "  3. Select 'MultiExport' and click 'Execute'"
    echo ""
    echo "The macro should also appear in Tools > Addon Manager"
    echo "under 'Installed' addons."
    echo ""

# =============================================================================
# Uninstallation
# =============================================================================

# Uninstall the Multi Export addon
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    ADDON_NAME="{{addon_name}}"

    # Set FreeCAD directories
    eval "$(just install::_freecad-dirs)"

    ADDON_DEST="$MOD_DIR/$ADDON_NAME"
    MACRO_SYMLINK="$MACRO_DIR/MultiExport.FCMacro"

    # Remove macro symlink first
    if [[ -L "$MACRO_SYMLINK" ]]; then
        rm "$MACRO_SYMLINK"
        echo "Removed macro symlink: $MACRO_SYMLINK"
    fi

    # Remove addon directory
    if [[ -d "$ADDON_DEST" ]]; then
        rm -rf "$ADDON_DEST"
        echo "Multi Export addon uninstalled from: $ADDON_DEST"
    else
        echo "Addon not found at: $ADDON_DEST"
        echo ""
        echo "Checking for legacy Macro directory installation..."
        LEGACY_DEST="$MACRO_DIR/Multi_Export"
        if [[ -d "$LEGACY_DEST" ]]; then
            rm -rf "$LEGACY_DEST"
            echo "Legacy installation removed from: $LEGACY_DEST"
        else
            echo "No installation found."
        fi
    fi

# Cleanup (alias for uninstall)
cleanup: uninstall

# =============================================================================
# Status Check
# =============================================================================

# Check installation status of the addon
status:
    #!/usr/bin/env bash
    set -euo pipefail
    ADDON_NAME="{{addon_name}}"

    # Set FreeCAD directories
    eval "$(just install::_freecad-dirs)"

    ADDON_DEST="$MOD_DIR/$ADDON_NAME"

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

    MACRO_SYMLINK="$MACRO_DIR/MultiExport.FCMacro"

    # Check Mod directory (preferred location)
    if [[ -d "$ADDON_DEST" ]]; then
        PACKAGE_XML="$ADDON_DEST/package.xml"
        MACRO_FILE="$ADDON_DEST/macro/Multi_Export/MultiExport.FCMacro"
        if [[ -f "$PACKAGE_XML" && -f "$MACRO_FILE" ]]; then
            MACRO_MOD_TIME=$(get_mod_time "$MACRO_FILE")
            # Extract version from package.xml
            VERSION=$(grep -o '<version>[^<]*</version>' "$PACKAGE_XML" | head -1 | sed 's/<[^>]*>//g')
            echo "✓ Multi Export: INSTALLED (Mod directory)"
            echo "  Version: ${VERSION:-unknown}"
            echo "  Updated: $MACRO_MOD_TIME"
            echo "  Path: $ADDON_DEST"

            # Check symlink status
            if [[ -L "$MACRO_SYMLINK" ]]; then
                SYMLINK_TARGET=$(readlink "$MACRO_SYMLINK")
                if [[ "$SYMLINK_TARGET" == "$MACRO_FILE" ]]; then
                    echo "  Symlink: ✓ $MACRO_SYMLINK"
                else
                    echo "  Symlink: ⚠ Points to wrong target"
                    echo "           Run 'just install::addon' to fix"
                fi
            else
                echo "  Symlink: ✗ Missing (macro may not appear in FreeCAD menu)"
                echo "           Run 'just install::addon' to fix"
            fi
        else
            echo "⚠ Multi Export: INCOMPLETE"
            echo "  Path exists but required files missing"
            echo "  Reinstall: just install::addon"
        fi
    else
        echo "✗ Multi Export: NOT INSTALLED"
        echo "  Install: just install::addon"
    fi

    # Check for legacy Macro directory installation
    LEGACY_DEST="$MACRO_DIR/Multi_Export"
    if [[ -d "$LEGACY_DEST" ]]; then
        echo ""
        echo "⚠ Legacy installation found at: $LEGACY_DEST"
        echo "  This may cause conflicts. Remove with:"
        echo "  rm -rf \"$LEGACY_DEST\""
    fi

    echo ""
    echo "=========================================="
