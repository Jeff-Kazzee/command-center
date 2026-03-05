# Ops Dashboard Design System Foundations

## Purpose

Define a practical design foundation for the optional observability dashboard in C4.

## Token Foundations

### Color Tokens

- `color.bg.canvas`: `#F5F7FA`
- `color.bg.surface`: `#FFFFFF`
- `color.text.primary`: `#1B2330`
- `color.text.muted`: `#5E6B7A`
- `color.border.default`: `#D7DFE8`
- `color.status.todo`: `#8E9AAF`
- `color.status.in_progress`: `#1F7AE0`
- `color.status.in_review`: `#E0A21F`
- `color.status.done`: `#2D9B5F`
- `color.status.error`: `#C73A3A`

### Typography Tokens

- `font.family.base`: `IBM Plex Sans, Segoe UI, sans-serif`
- `font.family.mono`: `IBM Plex Mono, Consolas, monospace`
- `font.size.xs`: `12`
- `font.size.sm`: `14`
- `font.size.md`: `16`
- `font.size.lg`: `20`
- `font.weight.regular`: `400`
- `font.weight.medium`: `500`
- `font.weight.bold`: `700`

### Spacing + Radius

- `space.1`: `4`
- `space.2`: `8`
- `space.3`: `12`
- `space.4`: `16`
- `space.6`: `24`
- `radius.sm`: `6`
- `radius.md`: `10`
- `radius.lg`: `14`

## Core Dashboard Components

- `StatusBadge`
- `SessionTable`
- `RetryQueue`
- `TokenCards`
- `RateLimitPanel`
- `EventLog`

## Accessibility Baseline

- Body text contrast target: WCAG AA (4.5:1)
- Status color must not be sole signal; add text/icon states
- Keyboard navigation for all actionable controls

