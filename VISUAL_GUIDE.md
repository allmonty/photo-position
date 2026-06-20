# Photo Position App - Visual Guide

## App Screenshots (Mockup)

### Main App - Home Screen

```
┌─────────────────────────────────────────────┐
│  Photo Position Overlay                     │
├─────────────────────────────────────────────┤
│                                             │
│                                             │
│              ╭────────────╮                 │
│              │     □      │                 │
│              ╰────────────╯                 │
│                                             │
│          Position Overlay App               │
│                                             │
│     Create a positioning overlay that       │
│     stays on top of other apps              │
│                                             │
│                                             │
│        ┌─────────────────────┐              │
│        │  ▶  Start Overlay   │              │
│        └─────────────────────┘              │
│                                             │
│  ─────────────────────────────────          │
│                                             │
│  Instructions:                              │
│  1. Tap "Start Overlay" to create          │
│  2. Drag the circle/square to position     │
│  3. Use controls to change shape and size  │
│  4. Open your camera app to use overlay    │
│  5. Tap the overlay to toggle controls     │
│  6. Close overlay from controls or app     │
│                                             │
└─────────────────────────────────────────────┘
```

### Main App - Overlay Active

```
┌─────────────────────────────────────────────┐
│  Photo Position Overlay                     │
├─────────────────────────────────────────────┤
│                                             │
│                                             │
│              ╭────────────╮                 │
│              │     □      │                 │
│              ╰────────────╯                 │
│                                             │
│          Position Overlay App               │
│                                             │
│     Create a positioning overlay that       │
│     stays on top of other apps              │
│                                             │
│                                             │
│         Overlay is active! ✓                │
│                                             │
│        ┌─────────────────────┐              │
│        │  ■  Stop Overlay    │              │
│        └─────────────────────┘              │
│                                             │
└─────────────────────────────────────────────┘
```

### Overlay Window - Circle Shape

```
┌─────────────────────────────────────────────┐
│                                             │ ← Camera app
│                                             │   (or any app)
│                                       ┌───┐ │
│            ┌─────────┐                │ × │ │ ← Close
│            │         │                ├───┤ │
│            │    ○    │                │ ○ │ │ ← Shape (circle)
│            │         │                ├───┤ │
│            └─────────┘                │ + │ │ ← Increase size
│          (Drag to move)               │200│ │ ← Size display
│                                       │ − │ │ ← Decrease size
│                                       ├───┤ │
│                                       │👁‍🗨│ │ ← Hide controls
│                                       └───┘ │
│                                             │
│  ┌────────────────────────────────────┐    │
│  │ Tap overlay to show controls       │    │
│  └────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

### Overlay Window - Square Shape

```
┌─────────────────────────────────────────────┐
│                                             │ ← Camera app
│                                             │   (or any app)
│                                       ┌───┐ │
│            ┌─────────┐                │ × │ │ ← Close
│            │         │                ├───┤ │
│            │    □    │                │ □ │ │ ← Shape (square)
│            │         │                ├───┤ │
│            └─────────┘                │ + │ │ ← Increase size
│          (Drag to move)               │300│ │ ← Size display
│                                       │ − │ │ ← Decrease size
│                                       ├───┤ │
│                                       │👁‍🗨│ │ ← Hide controls
│                                       └───┘ │
│                                             │
└─────────────────────────────────────────────┘
```

### Overlay Window - Controls Hidden

```
┌─────────────────────────────────────────────┐
│                                             │ ← Camera app
│                                             │   (or any app)
│                                             │
│            ┌─────────┐                      │
│            │         │                      │
│            │    ○    │                      │
│            │         │                      │
│            └─────────┘                      │
│          (Drag to move)                     │
│                                             │
│  ┌────────────────────────────────────┐    │
│  │ Tap overlay to show controls       │    │ ← Hint
│  └────────────────────────────────────┘    │
│                                             │
└─────────────────────────────────────────────┘
```

## User Flow

```
┌─────────────┐
│  Open App   │
└──────┬──────┘
       │
       ▼
┌───────────────────────────┐
│ Request Overlay Permission│
└──────┬──────────────┬─────┘
       │              │
    Allow          Deny
       │              │
       ▼              ▼
┌──────────────┐  ┌──────────────┐
│ Tap "Start   │  │ Error Message│
│  Overlay"    │  │ (Permission  │
└──────┬───────┘  │  Required)   │
       │          └──────────────┘
       ▼
┌──────────────────┐
│ Overlay Appears  │
│ with Controls    │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Drag Overlay to  │◄───────┐
│ Desired Position │        │
└──────┬───────────┘        │
       │                    │
       ▼                    │
┌──────────────────┐        │
│ Toggle Shape     │        │
│ (Circle/Square)  │        │
└──────┬───────────┘        │
       │                    │
       ▼                    │
┌──────────────────┐        │
│ Adjust Size      │        │
│ (+/- buttons)    │        │
└──────┬───────────┘        │
       │                    │
       ▼                    │
┌──────────────────┐        │
│ Hide Controls    │        │
│ (Optional)       │        │
└──────┬───────────┘        │
       │                    │
       ▼                    │
┌──────────────────┐        │
│ Open Camera App  │        │
└──────┬───────────┘        │
       │                    │
       ▼                    │
┌──────────────────┐        │
│ Position Subject │        │
│ within Overlay   │        │
└──────┬───────────┘        │
       │                    │
       ▼                    │
┌──────────────────┐        │
│ Take Photos      │        │
│ (using camera)   │        │
└──────┬───────────┘        │
       │                    │
       ▼                    │
┌──────────────────┐        │
│ Close Overlay    │        │
│ (from controls   │        │
│  or main app)    │        │
└──────┬───────────┘        │
       │                    │
       └────────────────────┘
    Reposition/Adjust again
```

## Color Scheme

Design system: **Velvet & Gilt Art Deco** (`DESIGN.md`)

| Token | Hex | Role |
|---|---|---|
| Surface / Background | `#290806` | Main app background (velvet crimson) |
| Surface Dark | `#230403` | AppBar, control panel |
| Surface Mid | `#391411` | Outlined button fill, snackbar |
| Secondary / Gold | `#E9C349` | Borders, icons, accents, headlines |
| Tertiary / Cream | `#D4C6A0` | Primary button background |
| On-Surface | `#FFDAD6` | Body text |

- **Main App Background**: Dark Crimson (`#290806`)
- **AppBar**: Darkest Crimson (`#230403`) with Burnished Gold (`#E9C349`) title
- **Overlay Background**: Transparent
- **Overlay Border**: Burnished Gold (`#E9C349`) at 80% opacity
- **Border Width**: 5 pixels
- **Control Panel Background**: Darkest Crimson at 90% opacity, 1px gold border
- **Control Icons**: Burnished Gold (`#E9C349`)
- **Primary Action Button**: Cream (`#D4C6A0`) fill, Crimson text, 2px Gold border, beveled corners
- **Secondary Action Button**: Mid Crimson fill, Gold text, 1px Gold border, beveled corners

## Typography

Typefaces: **Poiret One** (display / headings) + **Libre Franklin** (body / steps)

| Role | Font | Size | Letter Spacing | Color |
|---|---|---|---|---|
| App Title | Poiret One | 20px | 0.05em | Gold |
| Section Headline | Poiret One | 28px | 0.05em | Gold |
| Section Label | Poiret One | 14px, w600 | 0.1em | Gold |
| Button Label | Poiret One | 16px, w600 | 0.05em | — |
| Body / Instructions | Libre Franklin | 14px | — | On-Surface |

## Interactions

### Main App Buttons
- **START OVERLAY**: Creates overlay window
  - Visual: Cream (`#D4C6A0`) plaque with Crimson text, 2px Gold beveled border, play icon
  - Feedback: Button switches to "STOP OVERLAY" state; "OVERLAY ACTIVE" label appears in Gold
- **STOP OVERLAY**: Removes overlay window
  - Visual: Mid-Crimson fill, Gold text and icon, 1px Gold beveled border

### Overlay Controls
- **Close (×)**: Removes overlay; panel is sharp-cornered, dark crimson with 1px gold border
- **Shape Toggle (○/□)**: Switches between circle and square; icon reflects current shape

### Drag Gesture
- **Tap and Drag**: Move overlay anywhere on screen
- **Tap**: Toggle control panel visibility

### Resize Handles
- Bottom edge (circle): drag vertically — Gold divider tick mark
- Right edge (square): drag horizontally — Gold divider tick mark
- Bottom edge (square): drag vertically — Gold divider tick mark

## Responsive Behavior

- Overlay size: 50–500 pixels, absolute
- Controls panel anchored to top-right of overlay window
- Overlay position is screen-relative, persisted across restarts
- Transparent areas allow interaction with underlying apps

## Accessibility

- Large touch targets for all buttons
- High contrast: Gold on Crimson throughout
- Instruction steps visible on home screen at all times
- Beveled button corners provide tactile visual affordance

## Performance

- Minimal CPU/GPU usage (simple geometric shapes)
- No impact on underlying apps
- Instant shape switching
- Smooth drag interactions via native overlay drag
- Lightweight overlay Flutter engine

## Example Use Case: Aligned Product Photos

```
Photo 1:        Photo 2:        Photo 3:
┌─────────┐     ┌─────────┐     ┌─────────┐
│  ┌───┐  │     │  ┌───┐  │     │  ┌───┐  │
│  │ 🎁│  │     │  │ 📦│  │     │  │ 📱│  │
│  └───┘  │     │  └───┘  │     │  └───┘  │
└─────────┘     └─────────┘     └─────────┘

All products aligned in the exact same position!
Perfect for e-commerce, documentation, or social media.
```

## Example Use Case: Portrait Photography

```
Photo 1:        Photo 2:        Photo 3:
┌─────────┐     ┌─────────┐     ┌─────────┐
│  ┌─○─┐  │     │  ┌─○─┐  │     │  ┌─○─┐  │
│  │😊│  │     │  │😃│  │     │  │😄│  │
│  └───┘  │     │  └───┘  │     │  └───┘  │
└─────────┘     └─────────┘     └─────────┘

Consistent face positioning across multiple shots!
Perfect for passport photos, ID cards, or headshots.
```

