---
paths:
  - "Packages/CoreUI/Sources/**"
  - "Packages/Feature*/Sources/**"
  - "App/**/*.swift"
---

# Shared UI rules

These rules state ADR 017's target — black, monochrome, flat. Where CoreUI has not reached it yet, the code wins, per CLAUDE.md's final rule.

The design system lives in `CoreUI`: atoms under `Packages/CoreUI/Sources/CoreUI/Atoms/` and tokens in `Packages/CoreUI/Sources/CoreUI/Theme/Tokens.swift` (`Palette`, `Spacing`, `Radius`, `Typography`). Shared sheets, pickers and the Spanish formatters sit beside them. The app shell (`RootView`, the navigation stack) is `App/Root/`, not a feature.

## The iron rule

Feature views call **only** CoreUI atoms. **Never** a raw styled SwiftUI control — no `Button` with a style or a custom label, no `TextField`, `SecureField`, `Toggle`, `Picker`, `Stepper`, `DatePicker`, `Menu`, no `List` or `Form` chrome, no `.buttonStyle(...)`, `.textFieldStyle(...)` or `.toggleStyle(...)` at a feature call site. The atom for a primary action is `PrimaryButton`; every other control gets its atom the first time a feature needs it.

`Text` and `Image` have no atom; they are allowed only with a `Typography` role and a `Palette` token, never an inline `.font(.system(size:))` or a literal `Color`. `.sheet`, `.alert` and `.confirmationDialog` are the system containers in use; an alert's or a dialog's action `Button(role:)` with a plain text label is allowed there and only there. The navigation bar is system chrome and stays native.

A custom control written inside a feature never replaces an atom that exists for that purpose. If the atom does not fit, extend or modify it first.

### Native materials

iOS 26 and later draw Liquid Glass and system materials. They reach this app's own surfaces **only through a CoreUI atom**: `.glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glass)`, `.ultraThinMaterial` and their kin never appear in a feature view. System chrome (the navigation bar, a sheet's grabber, an alert) keeps whatever the OS draws. The rule exists because a material is a style decision, and ADR 017 decided flat: an atom is where that decision is made once.

## Before creating a component

1. **Check `CoreUI/Atoms/` first.** If it exists, use it. No exceptions.
2. **Decide the scope.** Used by a single screen, it belongs in its own feature package, as a sibling file or under `Components/`. Used app-wide, it belongs in `CoreUI/Atoms/`.
3. **If it must be created**, template on `PrimaryButton.swift` (a `ButtonStyle` reading `isEnabled` and `isPressed`, a `touchTarget` height), name it by its role with a matching file name, make its initializer `public`, and include a `#Preview` on `Palette.background` showing every state.

## Theme tokens are the style guide

`Tokens.swift` holds every value. There is no document holding hex codes or point sizes, and none should be created: a second copy drifts. This section says which token to reach for and why; the value is in the file.

Nothing enforces these rules mechanically: the gate sees Swift, not points, and goes green on a 30pt tap target. Conformance is verified with simulator screenshots. A deliberate exception is stated at the site in one line naming the constraint; a screen that needs a new value adds a token, never a literal.

### Principles

1. **Numbers are the hero.** The amount is what the user came for. The `amount*` roles are the largest type in the app and the only monospaced ones. A screen's summary has **one** hero amount; the others step down to `textSecondary` on one line.
2. **Negative space is a component.** Whitespace has a name (`Spacing`), a size and a reason. Crowding is a design failure.
3. **Hierarchy through type and tone, never through hue.** Emphasis is a step down the text ladder (`textPrimary` → `textSecondary` → `textTertiary`) or a change of size and weight. Hue is never decoration: `success`, the status tokens, the category dot, nothing else.
4. **Positive is tinted; negative stays monochrome.** An income amount takes `success`; a spend stays `textPrimary`, never red. `danger` means destructive or broken, not "money leaving". A signed net or balance aggregate (a month net, a total owed) follows the same rule: positive takes `+` and `success`, zero or negative stays monochrome. A magnitude under its own label ("Por cobrar", "Entran") is not a net and keeps the unsigned income/spend semantics. A new net routes its sign and tint through one CoreUI helper; an inline `if` at the call site reopens the monochrome-positive bug.
5. **Hairline over surface.** Rows sit on `background` and separate with space or a `border` hairline at `Spacing.hairline`, never by being lifted onto a lighter ground. No card, no shadow; keep it that way.

### Colour

- **Surface** (`background`, `surface1`…`surface3`, `border`, `borderFocus`): `background` is black and is the ground of every screen. The steps above it are for a sheet and a pressed row, never for containing content.
- **Text** (`textPrimary`, `textSecondary`, `textTertiary`, `textDisabled`): the ladder is the whole hierarchy. The app's one white surface, a screen's primary button, labels itself in `background`.
- **Colour is a datum, never a style.** A hue says something the data said, not something a designer chose: `success` for money in, a status token for a system state, the dot for a category. There is no brand hue to spend.
- **Status** (`success`, `warning`, `danger`, `info`, `positiveMuted`, `negativeMuted`): system state, plus `success` for income. The muted washes are the ground behind an icon or inside a pill; the readable mark on top is the full-strength token.
- **Category** (`category*` tints, `categoryGraphite` the fallback): an 8pt dot beside the category's name, never an icon tint or a surface. The domain stores a colour *name*; one CoreUI map resolves it to a token, so the palette retunes without a migration. The colour picker offers one id per token, and never a hue the dot cannot render.

### Typography

- Two jobs, two families: one for language, one monospaced with tabular figures for every `amount*` role. ADR 017 names Inter and IBM Plex Mono; `Typography` is the truth, and a role is picked by intent: `amountHero` for the one number a screen exists to show, `body` for running text, `label` for buttons and chips, `caption` for metadata. A new role is added to `Typography`, never styled inline.
- Text scales with Dynamic Type. A role is built from a text style, never from a fixed point size.
- Number formatting is owned by CoreUI's Spanish formatters and pinned by their golden tests: comma thousands, dot decimals (es-PE, hardcoded), `S/` before the number with one space, the sign before the symbol (`+S/ 1,234.56`), the Unicode minus `−` never the hyphen, two decimals always. In a hero amount the prefix and decimals are deemphasised so the integer part carries the glance.
- Italics are reserved for a secondary meta label (the `Variable` marker, a note). Never an amount.
- Forbidden: all caps outside an eyebrow atom; more than two weights on one screen; mixed alignment inside one vertical column.

### Spacing, radii, elevation, icons

- Base unit 4pt: `Spacing` `s1`…`s16`, plus `hairline`, the one sub-unit value, for every border, rule and selected ring. Screen horizontal padding `s4`, never less; `s6` between sections of distinct purpose.
- Touch targets are `Spacing.touchTarget` square, non-negotiable. A glyph smaller than the target keeps the full target through `.frame` and `.contentShape`, never by shrinking the target; a header target keeps its glyph on the rows' column by giving the padding back at the edge.
- `Radius` `xs`…`xxl`. Default to the smallest radius that reads right. No shadows: a modal that must read as "above" gets `surface1`, a hairline and rounded top corners.
- SF Symbols, outlined; the filled variant only when the symbol represents a state. An icon is `textSecondary` or `textTertiary`, never tinted: an account shows its type's symbol in grey. Never a brand logo or a bank's registered colours.

### Component invariants

- There is no card. Rows sit directly on `background`; a group is separated by space or a `Spacing.hairline` rule and named by a header above it.
- Text inputs are underline-only: `border` at rest, `borderFocus` on focus, `danger` on error with the helper text matching.
- `borderFocus` is the **only** selected or focused boundary, for a pill, chip, tile or day cell as much as for an input underline: a selected control keeps its hairline ring and brightens it, never `textPrimary`. A hand-rolled `isSelected ? textPrimary : border` is the bug this rule closes — a white ring is a second high-contrast element beside the primary button. A control whose selected state is a white *fill* draws no ring against it.
- A screen's primary action is one full-width white `PrimaryButton`, the only high-contrast element on it. A destructive action never takes it: `danger` text and a `danger` hairline on a transparent ground.
- Bars and charts have no track; the bar decorates and the row carries the meaning (the accessibility label on the row, the graphic hidden from VoiceOver).
- A transaction row is titled by what the user wrote, then by the category, never by a placeholder.
- No screen shows an account "balance": accounts have no opening balance, so every per-account figure is a month-scoped net and says so.
- A feature view never reads safe-area insets to pad itself by hand; the stack and its containers own them.

### Interactive states

- **The press is acknowledged at finger-down.** A shaped control draws its pressed state from `configuration.isPressed` in its `ButtonStyle` (`PrimaryButton` is the pattern); a full-width row on `background` swaps its ground to `surface1` while pressed — that swap is what `surface1` is for.
- **A navigable row ends with a `chevron.right`** at `Spacing.s4`, `textTertiary`, hidden from VoiceOver, after the amount column when there is one — navigable meaning the tap pushes a screen that holds more rows. A row that opens an editor, a sheet or a dialog carries none, and a navigable row never ends bare.
- **A disabled or loading control stays in layout** with `.disabled(true)`, so VoiceOver still announces it as a dimmed button. Its label is `textTertiary`. Never `textDisabled` on the label that names the blocked action (that token is for the meta text beside it), never a control hidden because it is disabled.
- **A touch box larger than its artwork** takes `.contentShape` on the box and draws the pressed state on the artwork, clipped to its shape.

### Accessibility floor

Contrast ≥ 4.5:1 for text, ≥ 3:1 for large text, no token grandfathered. Every interactive element carries an accessibility label; a decorative graphic is `.accessibilityHidden(true)`. `+` and `−` are always paired with words VoiceOver can read. Dynamic Type and Reduce Motion are respected.

## Never

- A raw styled SwiftUI control in a feature view.
- A literal `Color`, font size or padding number outside `Tokens.swift`.
- A card, a tinted icon, or a colour that is not a datum; a status token never means a transaction type.
- A material or Liquid Glass effect outside a CoreUI atom.
- An illustrated mascot in an empty state, or emoji as an icon.
- A design document holding token values.
