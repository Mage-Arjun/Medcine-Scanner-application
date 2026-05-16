# MedScan — Design Specification

## Concept & Vision

**MedScan** is not a pharmacy app. It's a personal medicine intelligence tool — think field researcher meets dark apothecary. The aesthetic pulls from **vintage scientific instrumentation**, **darkroom photography**, and **19th-century botanical illustration** — clinical precision wrapped in warmth.

The goal: make scanning a pill bottle feel like consulting a knowledgeable, slightly mysterious expert — not a corporate health portal.

---

## Aesthetic Direction

**Theme**: Dark apothecary + scientific notebook  
**Mood**: Warm, precise, trustworthy — not cold or sterile  
**Reference**: Old pharmacopoeia books, darkroom amber safelights, engraved botanical prints, analog instrument dials

**One unforgettable thing**: The scanner screen looks like a vintage microscope eyepiece — circular viewport with amber glow on dark background, scan line rendered as a hairline reticle.

---

## Color Palette

```
--bg-base:         #0F0E0C    /* near-black warm */
--bg-surface:      #1A1815    /* card surface */
--bg-raised:       #242119    /* elevated panels */
--amber-glow:      #D4862A    /* primary accent — warm amber */
--amber-dim:       #8A541A    /* muted amber for borders */
--amber-faint:     #2A1F0E    /* amber tint fills */
--ink:             #EDE8DF    /* primary text — warm off-white */
--ink-muted:       #8C8479    /* secondary text */
--ink-faint:       #4A4540    /* disabled / placeholder */
--success:         #4E7C59    /* muted forest green */
--danger:          #8C3A2E    /* muted brick red */
--border:          #2E2B26    /* default border */
--border-accent:   #5C4A2A    /* amber-tinted border */
```

---

## Typography

```
Display font:   "Cormorant Garamond" — for drug names, headings
                (elegant, slightly editorial, scientific publication energy)

Body font:      "IBM Plex Mono" — for composition, data fields, metadata
                (readable monospace that feels like a lab printout)

UI font:        "DM Sans" — for buttons, labels, navigation
                (clean but not generic)
```

Font scale:
```
--text-xs:    11px / mono — timestamps, tags
--text-sm:    13px / sans — labels, captions
--text-base:  15px / sans — body copy
--text-lg:    18px / garamond — section headings
--text-xl:    24px / garamond — drug names
--text-2xl:   34px / garamond — hero names, large display
```

---

## Layout & Grid

- Mobile-first, 390px base width
- 16px horizontal page margin
- Cards use `border-radius: 4px` — deliberately tight, almost architectural
- No floating action buttons — actions live in context
- Generous vertical spacing (24–40px between sections)
- All icons: thin stroke (1.5px), 20×20px — no filled icons

---

## Screen Specifications

---

### Screen 1 — Scanner (Home)

**Layout**: Full dark background. Centered circular viewfinder takes up 60% of screen height.

**Viewfinder**:
- Shape: Circle, not rectangle — references microscope eyepiece
- Border: 1.5px `--amber-glow` ring with subtle outer glow effect
- Inside: dark near-black `#0A0907`
- Crosshair reticle: thin `--amber-dim` lines (1px) with center gap
- Scan animation: single horizontal hairline in `--amber-glow` that sweeps vertically, slow (3s loop), eases in-out
- Corner tick marks: 4 short `--amber-glow` arcs at NE/NW/SE/SW
- Subtle vignette inside the circle

**Below viewfinder**:
- Label: `"align barcode within the field"` — 11px mono, `--ink-muted`, letter-spacing 0.15em, uppercase
- 24px gap
- Two buttons side by side:
  - Primary: `[ scan barcode ]` — amber fill, dark text, full weight
  - Secondary: `[ enter manually ]` — transparent, amber border

**Bottom navigation**:
- 3 tabs: Scanner · Dashboard · History
- Active tab: `--amber-glow` underline + label
- Inactive: `--ink-faint`
- Background: `--bg-surface` with top border `--border`
- Font: 11px DM Sans, uppercase, letter-spacing 0.1em

---

### Screen 2 — Scan Result (Bottom Sheet)

**Trigger**: Slides up from bottom after successful scan. Overlays 70% of screen.

**Sheet handle**: 32px wide, 3px tall, `--border-accent`, centered at top

**Header area**:
- Left: square drug image thumbnail (64×64px), `border-radius: 4px`, amber border
- Right: drug name in Cormorant Garamond 22px, marketer in 12px mono `--ink-muted`
- Below name: composition tag — monospace pill with `--amber-faint` background, `--amber-glow` text, 11px

**Divider**: `--border` 0.5px full width

**Data rows** (label + value pairs, mono font):
```
USES          Antacid, bloating relief...
SIDE EFFECTS  Nausea, dizziness...
```
- Labels: 10px mono uppercase `--ink-faint`
- Values: 13px mono `--ink-muted`
- Expand chevron (right-aligned) for truncated text

**Footer**:
- `[ view on 1mg ↗ ]` — text button, amber color
- `[ save to history ]` — filled amber button, full width

---

### Screen 3 — Dashboard

**Top bar**:
- Left: app wordmark "medscan" — Cormorant Garamond 18px, `--amber-glow`
- Right: status badge — `"8 loaded"` in 11px mono pill, green bg + text
- Below: search input — full width, `--bg-raised` background, 1px `--border`, monospace placeholder `"search drugs or composition..."`
- Far right of search: `[ rescrape ]` — small text button, amber

**Drug cards** (2-column grid, 8px gap):

Each card:
- Background: `--bg-surface`
- Border: 1px `--border`
- Border-radius: 4px
- Padding: 12px
- Top: drug image (full width, 80px tall, `object-fit: cover`, slight desaturation filter)
- Below image: name in 14px Garamond, marketer in 11px mono muted
- Composition pill: amber tint
- 2 lines of uses text in 12px mono muted, clipped with fade

**Skeleton loading state**:
- Same card shape but filled with animated shimmer blocks
- Shimmer color cycles between `--bg-surface` and `--bg-raised`
- Amber shimmer highlight passes left-to-right (CSS animation)

**Error state card**:
- Red-tinted border `--danger`
- Icon: small X circle (16px)
- Label: `"fetch failed"` mono red
- `[ retry ]` text button below

---

### Screen 4 — History

**List layout**: Full width, no grid

**Each history row**:
- Left: 48×48px drug thumbnail with amber border
- Center: drug name (14px Garamond) + composition (11px mono muted) + scan timestamp (10px mono faint — e.g. `23 APR 2026 · 14:32`)
- Right: chevron `>`
- Bottom border: `--border` separator

**Swipe-to-delete indicator**:
- On one row, show partially swiped state
- Revealed action: brick red `--danger` background, trash icon (white, 16px stroke)
- "delete" label in 11px mono white

**Empty state**:
- Centered, generous padding
- Icon: microscope outline SVG, 48px, `--amber-dim`
- Heading: `"no scans yet"` — Garamond 20px `--ink-muted`
- Subtext: `"point the scanner at any medicine to begin"` — 12px mono `--ink-faint`

---

## Interaction & Motion

- **Scanner pulse**: The amber ring around the viewfinder pulses (opacity 0.6 → 1.0) at 2s interval when actively scanning
- **Successful scan**: Ring flashes green briefly, then bottom sheet slides up with spring easing (300ms)
- **Card hover** (web): Border brightens to `--border-accent`, subtle 1px translate-Y upward
- **Bottom sheet**: Slides up with `cubic-bezier(0.22, 1, 0.36, 1)` spring — not linear
- **Scan line**: `animation: scan 3s ease-in-out infinite` — hairline sweeps top to bottom inside viewfinder

---

## Component Tokens

```css
/* Buttons */
--btn-primary-bg:      var(--amber-glow)
--btn-primary-text:    #0F0E0C
--btn-secondary-bg:    transparent
--btn-secondary-border: var(--amber-dim)
--btn-secondary-text:  var(--amber-glow)
--btn-radius:          3px
--btn-font:            DM Sans, 13px, letter-spacing 0.06em, uppercase

/* Tags / Pills */
--tag-bg:    var(--amber-faint)
--tag-text:  var(--amber-glow)
--tag-font:  IBM Plex Mono, 11px, uppercase

/* Cards */
--card-bg:      var(--bg-surface)
--card-border:  var(--border)
--card-radius:  4px

/* Input */
--input-bg:      var(--bg-raised)
--input-border:  var(--border)
--input-text:    var(--ink)
--input-placeholder: var(--ink-faint)
--input-focus-border: var(--amber-dim)
```

---

## What Makes This Unique

- **Dark warm palette** — zero cold blues or clinical whites; amber light feels like candlelight intelligence, not a hospital
- **Circular scanner** — breaks every pharmacy app convention; feels like scientific discovery
- **Mixed typography** — Garamond for names (trust, authority), mono for data (precision, honesty)
- **Tight radius (4px)** — architectural and intentional, not the rounded-everything look of modern health apps
- **Monospace data fields** — makes composition strings and metadata feel like a lab readout, not a database
- **Amber as the only accent** — single-color discipline creates visual coherence across all states
