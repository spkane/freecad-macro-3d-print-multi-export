# Multi Export Release Plan

**Assessment date:** 2026-09-04  
**Current source version:** 0.6.2  
**Recommended next release:** 0.7.0 after a release candidate and manual UAT  
**Current recommendation:** Do not submit to the official FreeCAD Addon Index yet.

## Executive Summary

This repository is much closer to a release than an experimental macro: it has a
manifest, documentation, unit and FreeCAD test suites, CI, security checks, and an
automated GitHub release workflow. A GitHub release tagged
`macro-multi-export-v0.6.2` already exists. The missing step is not merely creating
another tag; it is making the installed implementation, test implementation, and
documented behavior agree before asking FreeCAD to index the repository.

The primary release blocker is the package import path. The macro imports
`multi_export_fc` as a top-level module, but that module performs a package-relative
import. The top-level import fails with `attempted relative import with no known
parent package`, after which the macro silently runs its embedded fallback. This
means the modular FreeCAD implementation can be bypassed in normal use even though
it is the implementation the integration tests intend to exercise.

The second blocker is behavioral coverage. Eight formats are advertised, but actual
FreeCAD exports are tested for only STL, STEP, and BREP. Mixed Part/Mesh selection,
all mesh formats, overwrite behavior, and the displayed angular-deflection control
also need resolution. These are manageable gaps, but they should be closed before
an official listing exposes the macro to a much wider range of models and platforms.

## Codebase Map

| Area | Purpose | Release relevance |
| --- | --- | --- |
| `macro/Multi_Export/MultiExport.FCMacro` | GUI, entry point, and a second embedded implementation | What standalone users execute; currently 672 lines and able to diverge from modules |
| `macro/Multi_Export/multi_export_core.py` | Format metadata, validation, paths, and summaries without FreeCAD imports | Well-covered pure logic; the best home for reusable policy |
| `macro/Multi_Export/multi_export_fc.py` | FreeCAD object handling, meshing, format export, and `MultiExporter` | Intended production engine; currently vulnerable to the import-path mismatch |
| `macro/Multi_Export/__init__.py` | Package exports and version metadata | Useful for a canonical namespaced package |
| `tests/unit/test_core.py` | Pure-Python tests | 52 tests; core module reached 100% in this audit |
| `tests/freecad/test_multi_export.py` | FreeCAD geometry/export tests | Tests only three real output formats and imports the module through the problematic path |
| `tests/just_commands/` | Syntax/runtime tests for task recipes | 63 tests passed in this audit |
| `package.xml` | Addon Manager metadata and macro content declaration | Must validate against the current FreeCAD manifest schema |
| `docs/`, `README.md`, macro README/wiki source | User and release documentation | Several version/status/feature claims need synchronization |
| `just/`, `scripts/release-helpers.sh` | Local setup, checks, install, and release helpers | Good foundation, but release checks omit key gates |
| `.github/workflows/` and `.github/actions/` | CI, docs, CodeQL, FreeCAD setup, and releases | Good breadth; version matrix, path triggers, pinning, and artifact checks need work |

### Runtime flow today

1. FreeCAD executes `MultiExport.FCMacro`.
2. The macro prepends its directory to `sys.path` and imports top-level modules
   (`MultiExport.FCMacro:49-73`).
3. `multi_export_fc.py` tries `from .multi_export_core ...`
   (`multi_export_fc.py:14`), which requires package context.
4. The macro catches the resulting `ImportError` and silently activates its embedded
   implementation (`MultiExport.FCMacro:71-80`).
5. Export files are written directly to the requested paths without a collision
   policy or atomic replacement.

The target flow should have one canonical implementation, a thin entry point, and a
generated/tested standalone artifact if single-file installation remains supported.

## Verified Baseline

The following checks were run against the working tree during this assessment:

| Check | Result |
| --- | --- |
| Python version used for tests | CPython 3.11, matching current stable FreeCAD 1.1.3 packages |
| Unit tests | 52 passed |
| Unit-test coverage | 38% package total; `multi_export_core.py` 100%; FreeCAD module 0% under normal pytest |
| Just command tests | 63 passed |
| MkDocs strict build | Passed |
| Ruff, Ruff format, Bandit, gitleaks, detect-secrets, codespell, Markdown/YAML/action checks | Passed |
| Full `just all` | All substantive hooks passed; command failed only because `no-commit-to-branch` rejects `main` |
| `uv.lock` resolution | Dependencies resolved, but the project entry is stale at 0.6.1 while source metadata is 0.6.2 |
| Local FreeCAD integration suite | Not runnable: the installed weekly macOS build aborts in this execution environment with a Qt `neon` processor-feature error |
| Official Addon Index | Repository URL not present in `FreeCAD/Addons` `Data/Index.json` on 2026-09-04 |
| Scheduled CodeQL | Workflow state is `disabled_inactivity`; the last scheduled success was 2026-07-19 |
| Dependency backlog | 17 open Dependabot pull requests, all development/docs/Actions dependencies |

The local integration limitation must not be treated as a pass. Fresh FreeCAD CI and
manual GUI UAT are required before release.

## Release Blockers

### P0. Make installed and tested code identical

**Evidence:** `MultiExport.FCMacro:49-80`, `multi_export_fc.py:14`, and
`tests/freecad/test_multi_export.py:15-37` use incompatible top-level/package import
styles. A Python 3.11 import with FreeCAD modules stubbed reproduced the failure.

**Work:**

- Adopt FreeCAD's modern `freecad/<AddonName>/` namespace layout and import through
  that package without changing `sys.path`.
- Make the `.FCMacro` file a thin entry point for the installed addon.
- If a single-file macro remains a supported download, generate it from canonical
  modules during the release rather than maintaining copied logic by hand.
- Do not catch every `ImportError` around the whole import block. Distinguish
  “standalone artifact intentionally has no package” from an internal dependency or
  syntax failure, and report unexpected import errors visibly.
- Add an installed-layout smoke test and a standalone-artifact smoke test. Each test
  must assert which implementation ran.

**Acceptance criteria:** Addon Manager-style installation loads the package path;
the standalone artifact loads intentionally; neither path mutates `sys.path`; and CI
fails if either path silently falls back or imports a colliding module.

### P0. Verify all advertised formats and supported object combinations

**Evidence:** The UI advertises STL, STEP, 3MF, OBJ, IGES, BREP, PLY, and AMF, while
`tests/freecad/test_multi_export.py:282-298` only performs a combined STL/STEP/BREP
export. `get_shape_from_object()` returns either a `Part.Shape` or `Mesh.Mesh`, but
`combine_shapes()` sends every multi-object list to `Part.makeCompound()`
(`multi_export_fc.py:71-103`). Native STEP/IGES/BREP export also assumes Part geometry.

**Work:**

- Define a compatibility matrix for Part solids, PartDesign Bodies, Mesh objects,
  multiple Parts, multiple Meshes, and mixed Part/Mesh selections.
- Either implement a correct combination strategy per output family or disable
  incompatible formats with a clear explanation before export begins.
- Export and reopen/inspect every advertised format under current stable FreeCAD.
- Check that each file exists, is non-empty, can be re-imported when FreeCAD supports
  it, and has plausible bounds/facet or solid counts.
- Decide whether zero-volume surfaces are intentionally unsupported and document the
  policy; `is_object_exportable()` currently accepts only volume-bearing Part shapes.

**Acceptance criteria:** Every advertised format has a passing FreeCAD integration
test and a documented input-type policy. Unsupported combinations cannot reach the
export loop.

### P0. Resolve the ineffective mesh control

**Evidence:** `mesh_deflection` is displayed, loaded, saved, and returned by the
dialog (`MultiExport.FCMacro:382-388,502-510,535-581`) but is never used by the
export implementation. The README and docs advertise adjustable tolerance and
deflection.

**Work:** Implement angular deflection through a FreeCAD-supported meshing API and
test that it changes output, or remove the control and all related claims. Clarify
units: angular deflection should not be labeled in millimeters if it is angular.

**Acceptance criteria:** Every visible parameter has a measurable effect covered by
a test, or is removed.

### P0. Prevent accidental file replacement

**Evidence:** `_export_format()` builds the final path and writes to it directly
(`multi_export_fc.py:267-285`). There is no existing-file check or user-selected
collision policy.

**Work:** Add an explicit `ask`, `skip`, `rename`, or `overwrite` policy; default to
asking or skipping. Validate the destination before starting, show the full set of
collisions once, and write through a temporary sibling file followed by replacement
where the format writer permits it. Extend filename sanitization for control
characters, trailing spaces/dots, reserved Windows device names, and sensible length
limits.

**Acceptance criteria:** Existing files are not changed without explicit consent,
partial failed exports do not replace a valid prior file, and collision behavior is
tested.

### P0. Establish a current FreeCAD compatibility gate

**Evidence:** CI pins FreeCAD 1.0.0 (`.github/workflows/tests.yaml:71-87`) while the
latest stable release is 1.1.3. The manifest claims 0.21+ (`package.xml:16`) without a
tested version matrix. FreeCAD 1.1.3 contains security fixes and still ships Python
3.11, while `pyproject.toml:7` currently permits any Python >=3.11; during this audit
an unqualified `uv run` selected Python 3.13.

**Work:**

- Test current stable FreeCAD 1.1.3 in CI and manually on macOS, Linux, and Windows.
- Test the oldest version that will remain in `<freecadmin>`; otherwise raise the
  minimum to the oldest version actually verified.
- Constrain development Python to `>=3.11,<3.12` (or equivalent) while stable FreeCAD
  embeds 3.11, add a `.python-version`, and make every `just` recipe invoke
  `uv run --python 3.11 ...`.
- Make CI discover the FreeCAD-bundled Python version and fail on mismatch instead of
  merely printing it.

**Acceptance criteria:** The manifest range matches a green CI/manual matrix and all
development commands reliably use Python 3.11.

## Priority Improvements

### P1. Make release automation a real gate

- Change `just testing::unit`, coverage, and just-command recipes from bare `pytest`
  to pinned `uv run` commands (`just/testing.just:14-24,74-84`). They currently
  require a separately activated environment.
- Add FreeCAD integration tests, strict documentation build, manifest validation,
  installed-layout smoke test, standalone archive smoke test, and archive-content
  inspection to `release-test`. The current three steps are unit coverage, just tests,
  and pre-commit only (`just/testing.just:113-164`).
- Reconcile `no-commit-to-branch` with the release flow. `release-test` runs the hook
  on `main`, while `scripts/release-helpers.sh:17-29` requires releases from `main`.
- Add `uv.lock`, `.mise.toml`, `just/**`, `package.xml`, and
  `.github/actions/setup-freecad/action.yaml` to test workflow path filters. A lockfile
  or FreeCAD setup change can currently skip the test suite.
- Add timeouts and make test exit-code propagation explicit in the FreeCAD wrapper.
- Fix release notes: the workflow step named “Extract release notes” constructs a
  generic body and never reads `RELEASE_NOTES.md`
  (`macro-release-reusable.yaml:207-259`).

### P1. Choose and test one distribution contract

The recommended contract is an indexed standalone addon repository using the modern
namespace layout, plus a generated `.FCMacro` asset for manual users.

- Validate `package.xml` with the current Stable Addon Manifest Schema. Its namespace
  currently points at the older wiki metadata URL (`package.xml:2`). Migrate based on
  validator output, not guesswork.
- Confirm that `<content><macro>` and `<subdirectory>` describe the exact files the
  Addon Manager installs.
- Current GitHub archives contain only the `.FCMacro`, icon, README, and LICENSE
  (`macro-release-reusable.yaml:163-202`), not the modules or `package.xml`. Publish
  clearly named addon and standalone artifacts, or publish only the repository source
  archive for addon installation and the generated standalone macro separately.
- Add checksums and, if practical, GitHub artifact attestations for release assets.
- Consider the Addon Academy's recommended stable release branch once the package
  contract is settled; keep the manifest branch attribute consistent with the branch
  submitted to the index.

### P1. Synchronize documentation and metadata

- Change Addon Manager instructions to “not yet indexed” until acceptance. The README
  and install docs currently describe Addon Manager as available/recommended.
- Update `README.md:14` from 0.6.1 and add the missing 0.6.2 changelog entry.
- Remove the obsolete claim that the release is being added to the maintainer's
  `FreeCAD-addons` fork (`macro/Multi_Export/RELEASE_NOTES.md:17`). The modern official
  index is `FreeCAD/Addons`.
- Make one version/date source update `pyproject.toml`, both manifest versions/dates,
  package `__init__`, macro metadata, README badges/text, docs changelog, wiki source,
  and release notes. Fail CI if values differ. The stale `uv.lock` project version is
  direct evidence that the current bump set is incomplete.
- Document the exact supported object types, overwrite policy, per-format limitations,
  privacy posture (no network activity), and recovery from partial export failures.

### P1. Refresh dependencies and CI supply-chain controls

- Review the 17 open Dependabot PRs in small batches: security/transitive packages,
  test/lint tools, docs tools, then GitHub Actions. Run the full release gate after
  each batch and close superseded duplicates.
- Remove the Docker Dependabot ecosystem; no Dockerfile exists
  (`.github/dependabot.yaml:41-60`).
- Pin third-party GitHub Actions to full commit SHAs, with version comments, and keep
  Dependabot enabled for updates. Major tags are mutable supply-chain references.
- Re-enable CodeQL, confirm a fresh successful run, and verify GitHub private
  vulnerability reporting is enabled.
- Add `SECURITY.md` with supported versions, private reporting instructions, and a
  response/update policy. Add `CODEOWNERS` if branch protection will require review.

### P2. Maintainability and UX

- Reset `MultiExporter.exported_files` and `errors` at the start of each `export_all()`
  call or make instances single-use (`multi_export_fc.py:223-265`).
- Remove behavioral differences between embedded and modular summary/error handling.
- Add cancellation and prevent re-entrant export clicks during long mesh operations.
- Use structured internal result objects so the dialog can distinguish validation,
  unsupported input, collision, writer, and partial-success failures.
- Add translations only after the UI and terminology stabilize.
- Add the GitHub repository topics `freecad` and singular `addon`; the latter is one
  of the current discoverability recommendations.

## Security Assessment

The macro has a small remote attack surface: runtime code performs no network calls,
starts no subprocesses, accepts no credentials, and has no third-party runtime Python
dependencies. No critical or high-severity code-execution issue was identified in the
macro itself. Bandit, gitleaks, detect-secrets, and the last active CodeQL runs were
clean.

The meaningful trust boundaries are:

| Boundary | Main risk | Planned control |
| --- | --- | --- |
| Selected FreeCAD document objects | Malformed or unsupported geometry causing crashes/incorrect export | Current FreeCAD security release, type validation, per-format integration tests |
| User-selected output directory | Silent overwrite or partial/corrupt replacement | Collision policy, preflight, temporary files, actionable summary |
| Addon/module import path | Loading an unintended top-level module after `sys.path` mutation | Namespaced package, no `sys.path` manipulation, asserted import origin |
| CI and release dependencies | Compromised mutable Actions tag or stale dependency | SHA pinning, Dependabot batches, CodeQL re-enable, least-privilege permissions |
| Release artifacts | Users cannot easily verify contents/provenance | Deterministic build, content smoke test, checksums/attestation |

Keep workflow permissions job-scoped. The current release job's `contents: write` is
appropriate for creating a GitHub release; other jobs should remain read-only except
for Pages or security-event permissions that they specifically require.

## Required Test and UAT Matrix

### Automated FreeCAD tests

- FreeCAD 1.1.3 plus the oldest supported release.
- Part solid, PartDesign Body, Mesh, multiple Parts, multiple Meshes, mixed selection,
  empty shape, surface-only shape, hidden object, and invalid selection.
- Every one of STL, STEP, 3MF, OBJ, IGES, BREP, PLY, and AMF.
- Unicode names, reserved names, long names, missing/unwritable destination, existing
  files under every collision policy, and a writer failure after another format has
  succeeded.
- Coarse/fine tolerance and angular-deflection behavior if retained.
- Package import origin and generated standalone parity.

### Manual GUI UAT

Run the release candidate on macOS arm64, Windows x64, and Linux x64 with FreeCAD
1.1.3. Verify selection display, directory picker, remembered settings, progress,
cancellation/error recovery, overwrite prompts, all output files, Addon Manager-style
installation, uninstall/reinstall, and the generated standalone macro. Record the
FreeCAD build, OS, input model, result, and output artifacts in the release issue.

## Ordered Release Sequence

1. **Distribution decision:** Adopt namespaced addon source plus a generated
   standalone macro; identify the branch the official index will track.
2. **0.7 import/architecture change:** Make modules canonical, remove `sys.path`
   mutation, and add installed/standalone smoke tests.
3. **Correctness change:** Resolve mixed object handling, implement/remove angular
   deflection, add overwrite protection, and validate all eight formats.
4. **Compatibility change:** Pin Python 3.11, test FreeCAD 1.1.3 and the declared
   minimum, and repair local/CI release gates.
5. **Packaging and metadata change:** Validate the manifest, define artifact contents,
   synchronize versions/docs, add security policy, and refresh dependencies/actions.
6. **Release candidate:** Publish `0.7.0-rc.1`, perform the cross-platform GUI UAT,
   fix all release-blocking findings, and rerun every gate from a clean checkout.
7. **Stable release:** Publish 0.7.0 with real release notes, checksums, and install
   verification. Do not call it 1.0 until it has survived indexed-user feedback and a
   subsequent maintenance release.
8. **Official submission:** Open an “Addon - Addition” request in the current
   `FreeCAD/Addons` project, link the manifest, security policy, compatibility matrix,
   latest release, documentation, and UAT evidence, and address reviewer feedback.
9. **Post-release:** Verify appearance and installation in Addon Manager after the
   index refresh, monitor issues, and schedule a 0.7.1 maintenance window.

## Release Go/No-Go Checklist

- [ ] Installed addon and standalone asset execute the same canonical behavior.
- [ ] No runtime `sys.path` mutation or ambiguous top-level addon imports remain.
- [ ] All eight advertised formats pass artifact-level FreeCAD tests.
- [ ] Part, Mesh, multi-object, and mixed-selection behavior is explicit and tested.
- [ ] Existing output files cannot be overwritten unintentionally.
- [ ] Every visible mesh option affects output or has been removed.
- [ ] FreeCAD 1.1.3 and the declared minimum version pass CI/manual tests.
- [ ] Every dev/test command is constrained to the FreeCAD Python 3.11 ABI.
- [ ] Current manifest schema validation passes with accurate content and branch data.
- [ ] Strict docs, FreeCAD integration, package/archive smoke tests, static checks,
      secrets scans, and CodeQL all pass from a clean checkout.
- [ ] Version/date values and `uv.lock` agree everywhere.
- [ ] Addon Manager is not advertised as available until the listing is live.
- [ ] `SECURITY.md`, supported versions, and a private reporting route are published.
- [ ] Open dependency updates are triaged and release Actions are SHA-pinned.
- [ ] 0.7.0 release assets, notes, checksums, install, and uninstall are verified.
- [ ] Official Addon Index review is complete and installation from the index works.

## Authoritative References

- [FreeCAD Addon Index](https://github.com/FreeCAD/Addons)
- [FreeCAD Addon Index quality requirements](https://freecad.github.io/Addon-Academy/Topics/Addon-Index/Index/Qualities)
- [FreeCAD addon types](https://freecad.github.io/Addon-Academy/Topics/Types/)
- [FreeCAD compatibility guidance](https://freecad.github.io/Addon-Academy/Guides/Maintaining/Compatibility/)
- [FreeCAD metadata and discoverability guidance](https://freecad.github.io/Addon-Academy/Guides/Polish/Metadata/)
- [FreeCAD Addon Manifest Schema](https://github.com/FreeCAD/Addon-Manifest-Schema/tree/Stable)
- [FreeCAD releases](https://github.com/FreeCAD/FreeCAD/releases)
