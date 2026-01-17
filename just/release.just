# Release commands for the Multi Export macro
# Usage: just release::bump 1.0.0, just release::tag 1.0.0, etc.
#
# Release Process (two steps):
#   1. Bump version: just release::bump <version>
#      - Updates all version strings in source files
#      - Commit the changes: git add -A && git commit -m "chore: bump to <version>"
#   2. Create tag: just release::tag <version>
#      - Verifies versions match the tag
#      - Creates and pushes the git tag
#      - Tag triggers GitHub Actions workflow
#
# This macro uses git tags for releases:
#   - macro-multi-export-vX.Y.Z  (triggers GitHub release)

# Project root directory
project_root := justfile_directory()

# =============================================================================
# Version Bump Commands
# =============================================================================

# Bump the macro version in all source files
bump version:
    #!/usr/bin/env bash
    set -euo pipefail

    VERSION="{{version}}"
    TODAY=$(date +%Y-%m-%d)

    # Validate version format (SemVer 2.0)
    if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
        echo "ERROR: Version '$VERSION' is not valid semver (X.Y.Z or X.Y.Z-prerelease)"
        echo "Examples: 1.0.0, 1.0.0-alpha, 1.0.0-beta.1, 1.0.0-rc.1"
        exit 1
    fi

    echo "Bumping Multi Export macro to version: $VERSION (date: $TODAY)"
    echo ""

    # Update __version__ in the macro file
    MACRO_FILE="{{project_root}}/macro/Multi_Export/MultiExport.FCMacro"
    if [ -f "$MACRO_FILE" ]; then
        sed 's/^__version__ = "[^"]*"/__version__ = "'"$VERSION"'"/' "$MACRO_FILE" > "$MACRO_FILE.tmp" && mv "$MACRO_FILE.tmp" "$MACRO_FILE"
        echo "Updated $MACRO_FILE:"
        grep "__version__" "$MACRO_FILE" | head -1
    else
        echo "WARNING: File not found: $MACRO_FILE"
    fi

    # Update package.xml version and date
    PACKAGE_XML="{{project_root}}/package.xml"
    if [ -f "$PACKAGE_XML" ]; then
        # Update top-level version
        sed "s|<version>[^<]*</version>|<version>${VERSION}</version>|g" "$PACKAGE_XML" > "$PACKAGE_XML.tmp" && mv "$PACKAGE_XML.tmp" "$PACKAGE_XML"
        sed "s|<date>[^<]*</date>|<date>${TODAY}</date>|g" "$PACKAGE_XML" > "$PACKAGE_XML.tmp" && mv "$PACKAGE_XML.tmp" "$PACKAGE_XML"
        echo ""
        echo "Updated $PACKAGE_XML:"
        grep -E "<version>|<date>" "$PACKAGE_XML" | head -4
    else
        echo "ERROR: File not found: $PACKAGE_XML"
        exit 1
    fi

    # Update wiki-source.txt version and date
    WIKI_FILE="{{project_root}}/macro/Multi_Export/wiki-source.txt"
    if [ -f "$WIKI_FILE" ]; then
        sed "s/|Version=.*/|Version=${VERSION}/" "$WIKI_FILE" > "$WIKI_FILE.tmp" && mv "$WIKI_FILE.tmp" "$WIKI_FILE"
        sed "s/|Date=.*/|Date=${TODAY}/" "$WIKI_FILE" > "$WIKI_FILE.tmp" && mv "$WIKI_FILE.tmp" "$WIKI_FILE"
        echo ""
        echo "Updated $WIKI_FILE:"
        grep -E "^\|Version=|\|Date=" "$WIKI_FILE"
    else
        echo "WARNING: File not found: $WIKI_FILE"
    fi

    echo ""
    echo "Version bump complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Review changes: git diff"
    echo "  2. Commit: git add -A && git commit -m 'chore: bump to $VERSION'"
    echo "  3. Tag and release: just release::tag $VERSION"

# =============================================================================
# Tag Creation Commands
# =============================================================================

# Create and push a release tag (triggers GitHub release workflow)
tag version:
    #!/usr/bin/env bash
    set -euo pipefail

    # Source shared release helper functions
    . "{{project_root}}/scripts/release-helpers.sh"

    TAG="macro-multi-export-v{{version}}"
    VERSION="{{version}}"

    # Run all pre-release checks (version format, main branch, up-to-date, clean tree)
    pre_release_checks "$VERSION" || exit 1

    # Verify version in source files matches tag version
    echo "Verifying version in source files..."

    # Check macro file
    MACRO_FILE="{{project_root}}/macro/Multi_Export/MultiExport.FCMacro"
    if [ -f "$MACRO_FILE" ]; then
        MACRO_VERSION=$(grep -o '__version__ = "[^"]*"' "$MACRO_FILE" | head -1 | cut -d'"' -f2)
        if [ "$MACRO_VERSION" != "$VERSION" ]; then
            echo "ERROR: Version mismatch in $MACRO_FILE"
            echo "  Expected: $VERSION"
            echo "  Found:    $MACRO_VERSION"
            echo ""
            echo "Run 'just release::bump $VERSION' first, then commit the changes."
            exit 1
        fi
        echo "✓ $MACRO_FILE: $MACRO_VERSION"
    fi

    # Check package.xml
    PACKAGE_XML="{{project_root}}/package.xml"
    PKG_VERSION=$(grep -o '<version>[^<]*</version>' "$PACKAGE_XML" | head -1 | sed 's/<[^>]*>//g')
    if [ "$PKG_VERSION" != "$VERSION" ]; then
        echo "ERROR: Version mismatch in $PACKAGE_XML"
        echo "  Expected: $VERSION"
        echo "  Found:    $PKG_VERSION"
        echo ""
        echo "Run 'just release::bump $VERSION' first, then commit the changes."
        exit 1
    fi
    echo "✓ $PACKAGE_XML: $PKG_VERSION"

    echo ""
    echo "Creating tag: $TAG"
    echo ""
    echo "This will trigger a GitHub release with the macro archive."
    echo ""
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi

    git tag -a "$TAG" -m "Release Multi Export v{{version}}"
    git push origin "$TAG"
    echo ""
    echo "Tag $TAG created and pushed!"
    echo "Watch the release at: https://github.com/spkane/freecad-macro-3d-print-multi-export/actions"

# =============================================================================
# Information Commands
# =============================================================================

# Show current version from package.xml
version:
    @grep -o '<version>[^<]*</version>' {{project_root}}/package.xml | head -1 | sed 's/<[^>]*>//g'

# List all release tags
list-tags:
    @git tag -l 'macro-multi-export-v*' | sort -V

# Show the latest release tag
latest-tag:
    @git tag -l 'macro-multi-export-v*' | sort -V | tail -1

# =============================================================================
# FreeCAD Wiki Update Helpers
# =============================================================================

# Helper to update FreeCAD wiki (copies content to clipboard and opens edit page)
wiki-update:
    #!/usr/bin/env bash
    set -euo pipefail

    WIKI_SOURCE="{{project_root}}/macro/Multi_Export/wiki-source.txt"
    WIKI_PAGE="Macro_Multi_Export"
    COMPONENT_NAME="Multi Export"

    WIKI_URL="https://wiki.freecad.org/index.php?title=${WIKI_PAGE}&action=edit"

    echo "=========================================="
    echo "FreeCAD Wiki Update Helper"
    echo "=========================================="
    echo ""
    echo "Macro: $COMPONENT_NAME"
    echo "Wiki Page: https://wiki.freecad.org/${WIKI_PAGE}"
    echo ""

    # Check if wiki-source.txt exists
    if [ ! -f "$WIKI_SOURCE" ]; then
        echo "ERROR: Wiki source file not found: $WIKI_SOURCE"
        exit 1
    fi

    # Extract current version from wiki-source.txt
    CURRENT_VERSION=$(grep -o '|Version=[^|]*' "$WIKI_SOURCE" | cut -d= -f2 | tr -d '\n')
    CURRENT_DATE=$(grep -o '|Date=[^|]*' "$WIKI_SOURCE" | cut -d= -f2 | tr -d '\n')

    echo "Current version in wiki-source.txt:"
    echo "  Version: $CURRENT_VERSION"
    echo "  Date:    $CURRENT_DATE"
    echo ""

    # Try to copy to clipboard (platform-specific)
    COPIED=false
    if command -v pbcopy &> /dev/null; then
        # macOS
        cat "$WIKI_SOURCE" | pbcopy
        COPIED=true
        echo "Content copied to clipboard (macOS pbcopy)"
    elif command -v xclip &> /dev/null; then
        # Linux with xclip
        cat "$WIKI_SOURCE" | xclip -selection clipboard
        COPIED=true
        echo "Content copied to clipboard (xclip)"
    elif command -v xsel &> /dev/null; then
        # Linux with xsel
        cat "$WIKI_SOURCE" | xsel --clipboard --input
        COPIED=true
        echo "Content copied to clipboard (xsel)"
    elif command -v wl-copy &> /dev/null; then
        # Wayland
        cat "$WIKI_SOURCE" | wl-copy
        COPIED=true
        echo "Content copied to clipboard (wl-copy)"
    else
        echo "NOTE: No clipboard utility found (pbcopy, xclip, xsel, wl-copy)"
        echo "      You'll need to manually copy the content."
    fi

    echo ""
    echo "=========================================="
    echo "INSTRUCTIONS"
    echo "=========================================="
    echo ""
    echo "1. The wiki edit page will open in your browser"
    echo "2. Log in to your FreeCAD wiki account if prompted"
    echo "3. Select ALL content in the edit box (Ctrl+A / Cmd+A)"
    echo "4. Paste the new content (Ctrl+V / Cmd+V)"
    echo "5. Add an edit summary like: 'Update to version $CURRENT_VERSION'"
    echo "6. Click 'Show preview' to verify changes"
    echo "7. Click 'Save changes' when satisfied"
    echo ""

    # Ask for confirmation before opening browser
    read -p "Open wiki edit page in browser? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        echo "Aborted. You can manually visit:"
        echo "  $WIKI_URL"
        echo ""
        echo "Wiki source file location:"
        echo "  $WIKI_SOURCE"
        exit 0
    fi

    # Open the wiki edit page in browser (platform-specific)
    if command -v open &> /dev/null; then
        # macOS
        open "$WIKI_URL"
    elif command -v xdg-open &> /dev/null; then
        # Linux
        xdg-open "$WIKI_URL"
    elif command -v wslview &> /dev/null; then
        # WSL
        wslview "$WIKI_URL"
    else
        echo "Could not open browser automatically."
        echo "Please manually visit: $WIKI_URL"
    fi

    echo ""
    echo "Browser opened to: $WIKI_URL"
    if [ "$COPIED" = true ]; then
        echo ""
        echo "The wiki content is in your clipboard - ready to paste!"
    fi

# Show the wiki source content (for review)
wiki-show:
    #!/usr/bin/env bash
    set -euo pipefail

    WIKI_SOURCE="{{project_root}}/macro/Multi_Export/wiki-source.txt"

    echo "=========================================="
    echo "Wiki Source: Multi Export"
    echo "=========================================="
    echo "File: $WIKI_SOURCE"
    echo ""

    # Show version info
    CURRENT_VERSION=$(grep -o '|Version=[^|]*' "$WIKI_SOURCE" | cut -d= -f2 | tr -d '\n')
    CURRENT_DATE=$(grep -o '|Date=[^|]*' "$WIKI_SOURCE" | cut -d= -f2 | tr -d '\n')
    echo "Version: $CURRENT_VERSION"
    echo "Date:    $CURRENT_DATE"
    echo ""
    echo "=========================================="
    echo ""

    cat "$WIKI_SOURCE"

# Diff the local wiki source against the current wiki page (requires curl)
wiki-diff:
    #!/usr/bin/env bash
    set -euo pipefail

    WIKI_SOURCE="{{project_root}}/macro/Multi_Export/wiki-source.txt"
    WIKI_PAGE="Macro_Multi_Export"

    WIKI_RAW_URL="https://wiki.freecad.org/index.php?title=${WIKI_PAGE}&action=raw"

    echo "Fetching current wiki content..."
    echo ""

    # Create temp file for wiki content
    TEMP_WIKI=$(mktemp)
    trap "rm -f $TEMP_WIKI" EXIT

    # Fetch current wiki content
    if ! curl -sS "$WIKI_RAW_URL" > "$TEMP_WIKI" 2>/dev/null; then
        echo "ERROR: Could not fetch wiki page. The page may not exist yet."
        echo "URL: $WIKI_RAW_URL"
        exit 1
    fi

    # Check if page exists (MediaWiki returns specific content for missing pages)
    if grep -q "There is currently no text in this page" "$TEMP_WIKI"; then
        echo "NOTE: Wiki page does not exist yet."
        echo "This will be a new page creation."
        echo ""
        echo "Local content to be uploaded:"
        echo "=========================================="
        head -20 "$WIKI_SOURCE"
        echo "..."
        echo "(truncated - run 'just release::wiki-show' to see full content)"
        exit 0
    fi

    echo "Comparing local wiki-source.txt with live wiki page..."
    echo ""

    # Show diff
    if diff -u "$TEMP_WIKI" "$WIKI_SOURCE"; then
        echo "No differences found - wiki is up to date!"
    else
        echo ""
        echo "=========================================="
        echo "Differences found (above)"
        echo "Run 'just release::wiki-update' to update the wiki"
    fi
