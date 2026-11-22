# Internal project records

These are the repository's working records: defect registers, engineering
plans, build and design notes, and localization contracts. They are internal,
not part of the published site, and English-only unless a record says
otherwise.

`docs/_config.yml` excludes this whole tree, in every language. `BUGS.md` and
`BUGS_FIXED.md` are never translated. The legacy `docs/zh/project/` tree is a
frozen snapshot and is not maintained against these files.

## Registers

* [BUGS.md](registers/BUGS.md) — the open defect and quirk register.
* [BUGS_FIXED.md](registers/BUGS_FIXED.md) — the archive of fixed defects.
* [TASKS.md](registers/TASKS.md) — the engineering task queue.
* [TODO.md](registers/TODO.md) — the author's product wishlist.
* [ROADMAP.md](registers/ROADMAP.md) — the order the tracks are picked up in.
* [FUTURE_FEATURES.md](registers/FUTURE_FEATURES.md) — the indexed register of
  vision-required features.

`WARNINGS_INVENTORY.md` and `WARNINGS_PLAN.md` live in `registers/` but are
gitignored local-only scratch; they are not in version control.

## Product

* [APPSTORE.md](product/APPSTORE.md) — the App Store listing text.
* [MAD_STRATEGY.md](product/MAD_STRATEGY.md) — the strategic analysis.
* [MAD_FUTURE.md](product/MAD_FUTURE.md) — the long-form vision.

## Design and history

* [MAD_SCRIPTING.md](design/MAD_SCRIPTING.md) — the Scrimpter revival analysis.
* [MAD_STORE_MIGRATION.md](design/MAD_STORE_MIGRATION.md) — the portable-store
  migration plan.
* [MAD_STORE_PHASE_C.md](design/MAD_STORE_PHASE_C.md) — the Phase C mechanism.
* [MIGRATION_KICKOFF.md](design/MIGRATION_KICKOFF.md) — the migration handoff.

## Build

* [DEVELOPER.md](build/DEVELOPER.md) — build commands and local test servers.
  It contains local test credentials; it is internal.
* `TEST-DB-INFO.md` — local test endpoint credentials; gitignored and not in
  version control.

## Localization

* [LOCALIZATION.md](localization/LOCALIZATION.md) — the documentation
  localization contract and validation checklist.
* [MAD_APP_LOCALIZATION.md](localization/MAD_APP_LOCALIZATION.md) — the
  application localization plan and completion record.

## Agents

* [MAD_DATASOURCE_AND_CONNECTION_UX.md](agents/MAD_DATASOURCE_AND_CONNECTION_UX.md)
  — an agent prompt carrying private instructions; never publish it.

## Stable anchors at this root

* [MAD_FORMAT.md](MAD_FORMAT.md) — a pointer to the public specification. It
  stays here so references to it by name keep landing.
* [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) — the licensing register.
  The root `NOTICE` links it by path; it is English-only and verbatim.
* [LICENSE_COMPLIANCE_PLAN.md](LICENSE_COMPLIANCE_PLAN.md) — the licensing
  remediation plan; English-only.

## Promoted to the public site

The following records have moved, or are moving, to `docs/developers/` and are
translated into the five languages. Once moved, the public page is the only
copy:

[MAD_CLI](../developers/cli.md), [MAD_DATA_OBJECT](../developers/data-object.md),
[MAD_MULTI_SOURCE](../developers/multi-source.md), [MAD_SQL_ENTRY](../developers/sql-entry.md),
[SATELLITE_REPOS](../developers/satellites.md), `LIBRARIES`, `MAD_LINUX`, `MAD_WINDOWS`, `MAD_MACOS`,
`MAD_PDF_LINUX`, `MADDataTable_Architecture_Report`, `MADModel_Layer`,
`MAD_ARRAY_CACHING`.
