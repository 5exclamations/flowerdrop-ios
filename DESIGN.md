# FlowerDrop — Design System & UI Rules

This file is the source of truth for all UI work in this project. Read it fully before writing or modifying any SwiftUI view. Every visual decision must be traceable to a rule here. If a rule conflicts with a quick solution, the rule wins.

## 1. Aesthetic direction

FlowerDrop is a premium flower delivery app. The visual identity is grounded in the world of real florists: stem-green wrapping paper, ivory card stock, handwritten tags, a single vivid bloom against neutral paper. The feel is **editorial botanical** — calm, airy, confident. Think high-end Parisian flower atelier, not a generic e-commerce template.

Product photography is the hero. The UI is a quiet frame around flowers; it never competes with them for color.

### Palette (define once in `Theme.swift` + Asset Catalog with dark variants)

| Token | Light | Role |
|---|---|---|
| `paper` | `#FAF7F2` | App background (warm ivory, never pure white) |
| `ink` | `#20302A` | Primary text — deep stem green, NOT black, NOT gray |
| `inkSecondary` | `#5C6B63` | Secondary text, captions |
| `stem` | `#2F5D46` | Brand green: nav accents, selected states, tags |
| `bloom` | `#C94F3D` | The ONE accent — poppy red. CTAs, badges, price highlights only |
| `card` | `#FFFFFF` | Card surfaces |
| `hairline` | `#E7E1D6` | Borders, dividers (use instead of shadows where possible) |

Hard limits: exactly one accent (`bloom`). No gradients on buttons or cards. No system `.blue`. Set the app-wide tint to `stem`.

### Typography

- Display / headings: system serif — `.fontDesign(.serif)` with `.fontWeight(.semibold)`. Screen titles large: `.font(.system(.largeTitle, design: .serif, weight: .semibold))`.
- Body / UI: SF Pro (default). Never serif for body text or buttons.
- Captions/labels: SF Pro, `.footnote` or `.caption`, `inkSecondary`, generous `kerning(0.5)` + uppercase for eyebrow labels (e.g. "SEASONAL PICKS").
- Use the built-in Dynamic Type styles (`.title2`, `.headline`, `.subheadline`, `.footnote`) — never hardcoded point sizes except the display title.
- Max 2 type families total (serif display + SF Pro). Never add a third.

### Signature element

"The Drop": when a bouquet is added to the cart, a single petal detaches from the product image and falls into the cart tab icon with a spring arc + soft haptic. This is the app's one memorable flourish. Nothing else in the app animates this theatrically.

## 2. Layout & spacing

- Spacing scale, no exceptions: **4, 8, 12, 16, 24, 32, 48**. Define as `enum Spacing { static let xs = 4.0 ... }`. Never `padding(10)`, `padding(13)`, `padding(20)`.
- Screen horizontal margin: 16 on compact, content never touches edges except full-bleed photos.
- Left-align by default. Centered layouts only for empty states and confirmation screens.
- Whitespace is a feature: section gaps 32–48. When in doubt, add space, don't add a divider.
- Corner radii: cards 20, buttons 14, thumbnails 12 — always `RoundedRectangle(cornerRadius:, style: .continuous)`. Never the default circular style, never `.cornerRadius()` modifier.
- Product images: fixed aspect ratios (4:5 for cards, 1:1 for thumbnails), `.clipped()`, no borders around photos.

## 3. Depth & surfaces

- Prefer hairline borders (`hairline`, 1px) over shadows for card separation on `paper` background.
- When a shadow is needed (floating CTA, sheets): `.shadow(color: .black.opacity(0.07), radius: 18, y: 8)`. Never default `.shadow(radius: 10)`, never opacity above 0.12.
- Overlays/sheets: `.ultraThinMaterial` or `.regularMaterial`, never `Color.black.opacity(0.5)` rectangles.
- No cards inside cards. Maximum one level of surface elevation per screen.

## 4. Components

- Buttons: one custom `PrimaryButtonStyle` (bloom background, white text, height 52, radius 14, `scaleEffect(0.97)` + opacity on press) and one `SecondaryButtonStyle` (hairline border, ink text). Reuse everywhere; never inline-style a button.
- Icons: SF Symbols only, `.symbolRenderingMode(.hierarchical)`, weight matched to adjacent text weight. Emoji are NEVER icons.
- Tags/chips: capsule, `stem.opacity(0.12)` background, `stem` text, `.footnote`.
- Price: SF Pro `.headline` monospacedDigit, `ink`; old price strikethrough `inkSecondary`.
- Empty states: custom illustration-free composition — serif headline, one-line body, one primary action. Copy is specific ("No bouquets saved yet — browse seasonal picks") never generic ("No data").
- Loading: skeleton shapes with subtle `paper`→`hairline` shimmer, or `ProgressView` tinted `stem`. Never full-screen spinners over content that could skeleton.

## 5. Motion & feedback

- Standard transitions: `.spring(response: 0.35, dampingFraction: 0.85)` or `.snappy`. Never `.linear`, never default `withAnimation {}` with no curve.
- Micro-interactions only where they carry meaning: press states, add-to-cart (the Drop), pull-to-refresh. No ambient/looping animations, no animated gradients.
- Haptics via `.sensoryFeedback`: `.impact(flexibility: .soft)` on add-to-cart, `.success` on order placed. Nothing else.
- Respect `accessibilityReduceMotion`: the Drop degrades to a fade.

## 6. Copy rules

- Sentence case everywhere except uppercase eyebrow labels. No exclamation marks. No "Welcome to FlowerDrop!" filler.
- Buttons name the action's result: "Add to cart", "Place order", "Save address" — never "Submit", "OK", "Continue" where something specific fits.
- Errors say what happened and what to do next, in one sentence.

## 7. Forbidden (instant AI tells — never ship these)

1. Blue/purple gradients anywhere.
2. Default `.blue` tint or unstyled `Button("...")`.
3. Heavy dark shadows, `.shadow(radius: 10)` defaults.
4. Emoji as icons or in headings.
5. `padding()` chaos — mixed arbitrary values off the scale.
6. Same radius on everything, non-continuous corners.
7. Fully centered VStack screens for content.
8. Three+ accent colors, rainbow category chips.
9. Placeholder copy ("Lorem", "Welcome!", "Explore amazing flowers!").
10. Pure `#FFFFFF` app background or pure `#000000` text.

## 8. Working loop (mandatory for every UI task)

1. Before coding, restate which tokens/rules of this file apply to the screen.
2. Implement using tokens from `Theme.swift` only — if a value isn't in the system, add it to the system first or don't use it.
3. Build, run on the iPhone 16 simulator, and **take a screenshot via XcodeBuildMCP**.
4. Self-critique the screenshot against sections 1–7: name at least two concrete violations or weaknesses (spacing off-scale? hierarchy flat? accent overused?).
5. Fix them, screenshot again. Minimum two critique passes per screen before presenting the result.
6. Check dark mode and one Dynamic Type step up (`.xLarge`) before calling a screen done.
