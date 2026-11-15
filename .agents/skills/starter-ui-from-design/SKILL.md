---
name: starter-ui-from-design
description: Turns a screenshot, mockup, Figma frame, or written description into Flutter widgets that follow the starter's theme tokens and structure, then checks it visually on a device. Use when the user shares a design/image or asks to build or restyle a screen.
---

# UI from design

## 1. Read the design

List what you see before coding: sections, components, states (loading/empty/error), spacing rhythm,
colors, typography. Ask about anything ambiguous (scroll behavior, tap targets, data source).

## 2. Map to the starter

| Design element | Use |
|---|---|
| Brand color | `AppTheme.seedColor` (change once, not per widget) |
| Colors / text styles | `context.colors.*`, `context.textTheme.*` |
| Spacing, radius | `AppSpacing.xs/sm/md/lg/xl`, `AppRadius.sm/md/lg` |
| Async section | `AsyncValueView(value: ..., data: ...)` |
| Loading / error / empty | `LoadingView`, `ErrorView`, `EmptyView` |
| Repeated item | small `StatelessWidget` in `presentation/widgets/` |
| Responsive | `context.isWide`, `LayoutBuilder`; official skill `flutter-build-responsive-layout` |

Never hardcode hex colors or pixel spacing in feature widgets. If the design needs a new token,
add it to `app/theme/` first.

## 3. Build

- Pages are thin: compose widgets, read state with `ref.watch`, call controller methods.
- Give interactive widgets `Key('feature.element')`.
- Add a widget preview if useful (official skill `flutter-add-widget-preview`).

## 4. Compare visually

Run on a device (skill `starter-verify-on-device`), take a screenshot with the `mobile` MCP, and compare
with the design side by side. Fix differences in spacing, alignment, and typography; check dark mode and
a small screen. Finish with `make check`.
