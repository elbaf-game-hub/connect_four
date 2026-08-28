# 07 — Publish

> Module ships as a pub.dev package. Each module lives in its own
> GitHub repo under `elbaf-game-hub/<slug>`. This doc is the
> per-repo checklist.

## Pre-publish checklist

- [ ] `pubspec.yaml` has:
  - `name: connect_four`
  - `version: 0.1.0` (SemVer: bump patch for fixes, minor for new
    features, major for breaking changes to the state API)
  - `description: <one line, ≤ 180 chars>`
  - `homepage: https://github.com/elbaf-game-hub/connect_four`
  - `repository: https://github.com/elbaf-game-hub/connect_four`
  - `issue_tracker: https://github.com/elbaf-game-hub/connect_four/issues`
  - `topics: [flutter, game, offline, dart]`
- [ ] `LICENSE` (MIT) at the repo root
- [ ] `CHANGELOG.md` with a `## 0.1.0` entry
- [ ] `README.md` with rules, controls, screenshot, run instructions
- [ ] All assets in `assets/LICENSES.md` declared (or file absent
      if 100% original)
- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0, coverage ≥ 90% on the state file
- [ ] `flutter pub publish --dry-run` exits 0
- [ ] GitHub release `v0.1.0` created
- [ ] Wrapper PR opened that adds the submodule and `modules.yaml`
      entry (if first publish of this module)

## Extra dependencies

None. The module depends only on `game_module`, `game_assets`, `flutter_svg`, and `audioplayers`.

## Persistence keys

The wrapper injects a `HighScoreStore` at startup. This module reads
and writes the following keys:

- `wins_red`
- `wins_yellow`
- `draws`

Namespacing convention: keys are stored as `<slug>:<key>` to avoid
collisions. The module's own code uses the bare key; the wrapper
prefixes it.

## CI

The wrapper repo's `.github/workflows/ci.yml` runs against every
submodule. The matrix entry for this module is:

```yaml
- module: {slug}
  path: game_hub_modules/{slug}
```

## Versioning policy

- `0.x.y` — pre-1.0; the state API can change between minors
- `1.0.0` — state API frozen; bug fixes only in patches
- Any change that breaks `GameDescriptor` (e.g. adding a required
  field) is a major version bump of `game_module` AND every
  affected module.
