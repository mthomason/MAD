# Document-type badge — design

Status: approved 2026-11-25. Report 1, P0: make the document type and its next action explicit
(badge portion only).

## Intent and why

The document type is currently a small secondary `TextBlock` after the filename in the
main command bar (`MainWindow.xaml:88`). It is easy to miss, and it does not stand out
from the filename. The audit asks for a visible pill next to the filename — neutral for a
standard report, accent for a composition report — with a tooltip that explains the type.

## Goals

- A read-only pill badge after the filename, visible whenever a document is open.
- Standard report: neutral surface. Composition report: accent surface.
- A localized tooltip that explains the type currently shown.
- Localized strings in all six dictionaries, with the pinned English count updated.
- A structural test that pins the badge's bindings and localized tooltip.

## Non-goals / anti-goals

- No composition first-run guidance ("import a report, then join…"). That belongs to
  Report 2 (`MAD_COMPOSITION_UX.md`) and must wait.
- No restructure of the command bar beyond replacing the type text with the badge.
- No interaction: the badge is informational and must not look or behave like a button.
- No change to the Query/Designer tooltip convention gate; it stays scoped to those views.
- Do not change `Localizer` behaviour.

## Constraints

- Every new key goes into `Strings-en.xaml`, `-de`, `-es`, `-ja`, `-pt-BR`, `-zh-Hans`;
  English is authoritative. `LocalizerTests.EveryShippedDictionary_HasEveryEnglishKey`
  pins the English count (currently 353) and must be bumped.
- New UI strings are AI-drafted translations per D14.
- Tooltip and accessible name stay conceptually separate; a tooltip may be a sentence.

## Approaches considered

1. **Themed pill style + view-level DataTrigger (chosen).** `MAD.DocumentTypeBadge` in
   `Theme.xaml` is neutral; `MainWindow.xaml` layers a `DataTrigger` on
   `Document.IsComposed` for the accent colours. Keeps theme colours in XAML and the
   view-model property knowledge in the one view that has it.
2. **`bool → Brush` converter.** Rejected: moves theme colour choice into C# and adds a
   class for a single badge.
3. **Reuse a button style.** Rejected: a read-only badge would look clickable.

## Decisions

- Text remains "Standard Report" / "Composition Report" (`Document.TypeStandard`,
  `Document.TypeComposition`).
- Per-type tooltip, not one static sentence: `Document.TypeStandard.Tooltip` and
  `Document.TypeComposition.Tooltip`, selected by a new `DocumentTypeTooltip` computed
  property on `DocumentViewModel` that raises alongside `DocumentTypeText`.
- Tooltip copy is descriptive only ("queries one database" / "built from reports
  imported as sources"), never instructional.
- Badge chrome: pill corner radius, semibold, `MAD.FontSize.Secondary`, padding
  `8,0,8,4` (optical centering: the glyphs sit 4 px from the top and bottom of the
  20 px pill; measured from a live capture), margin `8,0,0,0` after the filename.
- Neutral: `SubtleFillColorSecondaryBrush` background, `TextFillColorPrimaryBrush`
  foreground. Accent: `AccentFillColorDefaultBrush` background,
  `TextOnAccentFillColorPrimaryBrush` foreground.
- Accessibility: the badge is a `Border` wrapping a `TextBlock`, so the text is exposed
  naturally; no `AutomationProperties.Name` is added (it is not an action control).

## Test plan (TDD)

1. New `DocumentTypeBadgeTests` reads `MainWindow.xaml` and the theme, asserting a
   `Border` styled `MAD.DocumentTypeBadge` exists, its text binds
   `Document.DocumentTypeText`, its tooltip binds a localized key, it has an
   `IsComposed` accent trigger, and it is visible only when `Document.HasDocument`.
2. A `DocumentViewModel` test that `DocumentTypeTooltip` follows `IsComposed` and is
   localized.
3. The localization gate covers the new keys and the bumped count.
4. Full suite: `dotnet test Windows/App/Mad.Designer.Windows.Tests`.

## Left to the builder

Exact padding/typography may be tuned after a screenshot from the user; the accent and
neutral brush pair is fixed.
