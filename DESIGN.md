---
name: Velvet & Gilt Art Deco
colors:
  surface: '#290806'
  surface-dim: '#290806'
  surface-bright: '#582d28'
  surface-container-lowest: '#230403'
  surface-container-low: '#34100d'
  surface-container: '#391411'
  surface-container-high: '#461e1a'
  surface-container-highest: '#532824'
  on-surface: '#ffdad6'
  on-surface-variant: '#dcc0bd'
  inverse-surface: '#ffdad6'
  inverse-on-surface: '#4e2420'
  outline: '#a38b88'
  outline-variant: '#554240'
  surface-tint: '#ffb4aa'
  primary: '#ffb4aa'
  on-primary: '#5f1410'
  primary-container: '#4a0404'
  on-primary-container: '#d26a5f'
  inverse-primary: '#9d4139'
  secondary: '#e9c349'
  on-secondary: '#3c2f00'
  secondary-container: '#af8d11'
  on-secondary-container: '#342800'
  tertiary: '#d4c6a0'
  on-tertiary: '#383015'
  tertiary-container: '#b8ab86'
  on-tertiary-container: '#483f22'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdad5'
  primary-fixed-dim: '#ffb4aa'
  on-primary-fixed: '#410001'
  on-primary-fixed-variant: '#7e2b23'
  secondary-fixed: '#ffe088'
  secondary-fixed-dim: '#e9c349'
  on-secondary-fixed: '#241a00'
  on-secondary-fixed-variant: '#574500'
  tertiary-fixed: '#f0e2ba'
  tertiary-fixed-dim: '#d4c69f'
  on-tertiary-fixed: '#221b03'
  on-tertiary-fixed-variant: '#4f4629'
  background: '#290806'
  on-background: '#ffdad6'
  surface-variant: '#532824'
typography:
  headline-xl:
    fontFamily: Poiret One
    fontSize: 48px
    fontWeight: '400'
    lineHeight: 56px
    letterSpacing: 0.1em
  headline-lg:
    fontFamily: Poiret One
    fontSize: 32px
    fontWeight: '400'
    lineHeight: 40px
    letterSpacing: 0.05em
  headline-lg-mobile:
    fontFamily: Poiret One
    fontSize: 28px
    fontWeight: '400'
    lineHeight: 34px
  body-md:
    fontFamily: Libre Franklin
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Poiret One
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
spacing:
  margin-main: 24px
  gutter-inner: 16px
  border-weight: 1px
  accent-weight: 2px
---

## Brand & Style
This design system embodies the opulence and geometric precision of the Art Deco era. It is a **Retro-Luxury** aesthetic characterized by a sophisticated interplay between deep, tactile textures and sharp, metallic linework. The target audience seeks a premium, curated experience that feels both historically grounded and modernly functional.

The primary brand mark is a clean Art Deco emblem featuring a central camera-aperture motif encased in concentric geometric frames and sunburst rays. Visuals should evoke a sense of exclusivity and craftsmanship, utilizing "etched metal" textures and symmetrical ornamentation to create a structured yet lavish atmosphere.

## Colors
The palette is rooted in a "Dark Crimson" (#4a0404) base that serves as a velvet-like backdrop for "Burnished Gold" (#D4AF37) accents.

- **Primary (Crimson):** Used for deep backgrounds and large surfaces to establish a moody, high-end environment.
- **Secondary (Gold):** Used for borders, iconography, and decorative geometric elements to provide a metallic "etched" contrast.
- **Tertiary (Cream/Champagne):** Used sparingly for high-readability text or primary button backgrounds to create a light, paper-like contrast.
- **Neutral:** A near-black crimson used for shadows and extreme depth.

## Typography
The typography strategy pairs the geometric, stylized elegance of **Poiret One** for display roles with the clarity of **Libre Franklin** for functional body text.

Display text should always utilize increased letter spacing to reflect the architectural nature of Art Deco signage. Headlines are typically set in all-caps or title case to emphasize authority and structure. **Poiret One** acts as the "decorative soul" of the design, while **Libre Franklin** ensures that data-heavy sections remain accessible and grounded.

## Layout & Spacing
The layout follows a **Fixed Grid** philosophy, acting as a "framed canvas." Every screen is treated as a symmetrical composition, often enclosed within an intricate gold border.

- **Symmetry:** Content must be balanced along the vertical axis.
- **Decorative Margins:** Safe areas are not just empty space but are populated by corner flourishes (sunbursts and fans).
- **Dividers:** Use gold etched lines with diamond or geometric centerpieces rather than simple grey lines. 
- **Breakpoints:** On mobile, the density of the gold frame reduces to a single 2px line to maximize content real estate, while tablet and desktop allow for double-framed "etched metal" borders.

## Elevation & Depth
Depth in this design system is achieved through **Tonal Layers** and **Etched Effects** rather than ambient shadows.

- **Base Layer:** The Dark Crimson textured background (resembling velvet or matte paper).
- **Mid Layer:** Content cards with a slightly lighter crimson or gold-bordered outline.
- **Top Layer:** Metallic gold elements that appear "inlaid" or "embossed."
- **Focus State:** Elements do not "glow" with light shadows; instead, they gain a high-contrast Gold stroke or a subtle interior cream glow to simulate a metallic shine.

## Shapes
The shape language is strictly **Sharp (0px)** or **Notched**. 

Avoid soft, organic curves. Elements like cards and buttons should use "stepped" corners or 45-degree angled notches to mimic the architectural motifs of the 1920s. Symmetrical geometry is the rule; use rectangles, diamonds, and triangles to build complex decorative patterns.

## Components
### Buttons
Buttons are primary action drivers and should look like etched metal plaques. Use a Cream (#F5E6BE) background with Dark Crimson text for "Primary" actions, enclosed in a double-line gold border with notched corners.

### Cards
Cards are defined by their borders. They should not have background fills that differ significantly from the screen background; instead, use a 1px Gold border with "Sunburst" corner ornaments to define the card's boundary.

### Decorative Elements
- **Sunbursts:** Place in the corners of major containers or behind central icons.
- **Symmetrical Frames:** Use double-line weights (one thick, one thin) for a premium architectural feel.
- **Dividers:** Horizontal rules must feature a central geometric diamond or stylized "fan" motif.

### Inputs & Fields
Input fields should be underlined with a 1px Gold stroke, with the label in uppercase Poiret One sitting just above the line. Avoid fully enclosed boxes for inputs to maintain a lighter, more elegant feel.

### Navigation Bar
The bottom navigation uses gold wireframe icons. The active state is indicated by a vertical "stylus" or "diamond" marker above the icon.