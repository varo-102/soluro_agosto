---
name: Soluro Financial
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f4'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#43474d'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f0f1f1'
  outline: '#74777e'
  outline-variant: '#c4c6ce'
  surface-tint: '#49607e'
  primary: '#000f22'
  on-primary: '#ffffff'
  primary-container: '#0a2540'
  on-primary-container: '#768dad'
  inverse-primary: '#b0c8eb'
  secondary: '#785900'
  on-secondary: '#ffffff'
  secondary-container: '#fdc003'
  on-secondary-container: '#6c5000'
  tertiary: '#1a0b00'
  on-tertiary: '#ffffff'
  tertiary-container: '#381d00'
  on-tertiary-container: '#ae835a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d2e4ff'
  primary-fixed-dim: '#b0c8eb'
  on-primary-fixed: '#001c37'
  on-primary-fixed-variant: '#314865'
  secondary-fixed: '#ffdf9e'
  secondary-fixed-dim: '#fabd00'
  on-secondary-fixed: '#261a00'
  on-secondary-fixed-variant: '#5b4300'
  tertiary-fixed: '#ffdcbe'
  tertiary-fixed-dim: '#eebd90'
  on-tertiary-fixed: '#2d1600'
  on-tertiary-fixed-variant: '#613f1c'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
  azul-profundo: '#0A2540'
  amarillo-sol: '#FFC107'
  surface-muted: '#F1F4F9'
  text-on-light: '#0A2540'
  text-on-dark: '#FFFFFF'
typography:
  headline-xl:
    fontFamily: Geist
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Geist
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  headline-lg-mobile:
    fontFamily: Geist
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: 64px
---

## Brand & Style

The design system is rooted in the "El Optimismo Financiero" philosophy, balancing professional reliability with energetic forward momentum. The brand personality is **Corporate / Modern** with a high-contrast edge. It seeks to evoke a sense of absolute security (stability) while maintaining an approachable, optimistic tone (energy).

The visual language draws inspiration from modern fintech interfaces: it is clean and structured but uses bold color blocks to drive user focus. This design system prioritizes clarity and simplicity to ensure that financial data remains the hero, while the vibrant secondary accents provide a human, high-energy touch.

## Colors

The color palette is a high-contrast triad designed for maximum legibility and brand recognition.

- **Primary (Azul Profundo):** Represents stability and security. It should be used for headers, primary backgrounds, and navigation bars to ground the interface.
- **Secondary (Amarillo Sol):** Represents optimism and energy. Use this for call-to-action buttons, progress indicators, and active states to guide the user's eye.
- **Neutral (Blanco Puro):** Used for main content areas and page backgrounds to ensure a spacious and simple feel.

When using Amarillo Sol on white backgrounds, ensure high-contrast text or icons are used to maintain accessibility.

## Typography

This design system uses **Geist** exclusively to maintain a technical, precise, and contemporary feel. The font's geometric clarity supports the high-contrast requirements of a financial tool.

- **Headlines:** Use Bold and Semi-Bold weights to establish a clear information hierarchy. Tighter letter spacing on larger headlines creates a modern, editorial look.
- **Body:** Regular weight provides excellent readability for financial data and transactional lists.
- **Labels:** Use Medium or Semi-Bold weights in all-caps or high-tracking styles for metadata and table headers to differentiate them from interactive content.

## Layout & Spacing

The layout follows a **Fluid Grid** system that prioritizes logical grouping of financial components. 

- **Desktop:** Utilize a 12-column grid with 24px gutters. Content is typically centered in a max-width container of 1280px.
- **Mobile:** Transition to a single-column layout with 20px side margins. Component padding should be generous (md/16px) to ensure touch targets are accessible.
- **Rhythm:** All spacing units are multiples of 4px. Use `lg` (24px) for vertical separation between distinct cards or sections to maintain a clean, breathable interface.

## Elevation & Depth

To align with the "soft cards" aesthetic, the design system utilizes **Ambient Shadows** and **Tonal Layers** rather than harsh borders.

- **Low Elevation:** Primary cards use a soft, wide-spread shadow (0px 4px 24px, 6% opacity Azul Profundo) on white backgrounds to create subtle lift.
- **Tonal Layering:** Use `surface-muted` (#F1F4F9) for page-level backgrounds, allowing the white cards to pop. 
- **Active Depth:** Interactive elements should use a more pronounced shadow or a subtle inner-glow (Yellow) when focused, providing a tactile sense of interaction without clutter.

## Shapes

The shape language is defined by **Rounded** corners, creating a friendly and modern financial environment.

- **Cards & Containers:** Use a 16px (1rem) radius (`rounded-lg`) to soften the UI and match the "soft cards" reference.
- **Buttons & Inputs:** Use an 8px (0.5rem) radius for a disciplined, professional look.
- **Icons & Avatars:** Utilize circular or highly rounded containers (radius: 9999px) to contrast against the rectangular grid of the cards.

## Components

### Buttons
- **Primary:** Solid Amarillo Sol with Azul Profundo text. High-visibility for primary actions like "Cobrar" or "Enviar."
- **Secondary:** Transparent with an Azul Profundo 1.5px border or text-only. Used for "Ver Historial."
- **Size:** Standard buttons should be 48px height for mobile accessibility.

### Cards (The "Soft Card")
- White background, 16px border radius, and ambient blue-tinted shadow.
- Padding should be 20px (internal) to allow content to breathe.
- Group related data (e.g., balance and currency) within a single card.

### Input Fields
- White background with a 1px border in `surface-muted`. 
- Focus state: Border changes to Azul Profundo with a subtle Amarillo Sol glow/underline.

### Chips & Badges
- Small, high-radius containers (12px) used for transaction status (e.g., "Pending", "Completed"). 
- Use low-opacity tints of the status color for the background and full-opacity for text.

### Progress Bars
- Background: Azul Profundo (low opacity).
- Fill: Amarillo Sol. This combination reinforces the brand's "growth" and "optimism" narrative.