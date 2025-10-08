# Life App Design System (v1.0)

## 1. Foundations
- **Grid**: 8pt base spacing. Major layout gutters = 16pt (mobile), 24pt (tablet/desktop).
- **Breakpoints**:
  - Mobile: ≤600dp
  - Tablet: 601–1024dp
  - Desktop/Web: ≥1025dp (future road map)

## 2. Color
| Token | Light | Dark | Usage |
| --- | --- | --- | --- |
| `color.primary` | #5C4DFF | #A69BFF | Primary actions, focus highlight |
| `color.primaryContainer` | #E8E5FF | #342E6F | Accent backgrounds |
| `color.secondary` | #1EB980 | #5BE7B2 | Success states, healthful cues |
| `color.error` | #FF5370 | #FF8A80 | Destructive actions |
| `color.surface` | #FFFFFF | #121212 | Card backgrounds |
| `color.background` | #F6F6F9 | #0D0D0F | App background |
| `color.neutralHigh` | #1C1F23 | #E4E6EB | Headlines |
| `color.neutralMid` | #5B5F66 | #B9BEC6 | Body text |
| `color.neutralLow` | #A7ABB3 | #7A8089 | Secondary labels |

Gradients allowed only in marketing surfaces (paywall hero). Avoid in core UI.

## 3. Typography (based on Inter)
| Style | Weight | Size | Line Height | Usage |
| --- | --- | --- | --- | --- |
| Display | SemiBold | 32 | 40 | Feature cards, paywall headers |
| Headline | SemiBold | 24 | 32 | Section headers |
| Title | Medium | 20 | 28 | Card titles |
| Body | Regular | 16 | 24 | Body copy |
| Caption | Medium | 14 | 20 | Labels, helper text |
| Button | SemiBold | 16 | 24 | CTA buttons |

Dynamic Type: allow auto-scaling up to 1.3x. Maintain min 44x44 tap targets.

## 4. Components
- **Buttons**: Filled (primary), Tonal (secondary), Text (tertiary). Corner radius 12pt.
- **Cards**: Elevation 1 (shadow 8% black blur 12, spread 0). Padding 16pt.
- **Chips**: Filter chips use Tonal variant; include icon when representing categories.
- **Banners**: Use primaryContainer background with 12pt radius for sync/offline messages.
- **Dialogs**: Title (Headline style), body (Body), actions on right (Button style). Minimum width 320pt.

## 5. Iconography
- Use Material Symbols Outlined set. Stroke weight consistent across screens. Custom icons: focus (timer), rest (cloud), workout (bolt), sleep (moon).

## 6. Imagery
- Paywall hero uses abstract gradient shapes in primary/secondary palette. Avoid photography to keep bundle small.

## 7. Accessibility Checklist
- Color contrast: Primary-on-surface ≥4.5:1, text on primaryContainer ≥4.5:1.
- Focus visible: custom focus ring 2pt #5C4DFF with 25% opacity overlay.
- Haptics: medium impact on start/stop; subtle on skip.

## 8. Documentation
Store component variations in Figma library “Life App DS” with naming `component/state/size`. Reference this document for tokens.
