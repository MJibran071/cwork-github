# CWork Design System

## Overview
This document defines the centralized design system for the CWork platform, ensuring consistency across mobile and web interfaces. The system is built with Flutter and modern web technologies, focusing on responsiveness, accessibility, and scalability.

## Color Palette

### Primary Colors
- **Primary Blue**: `#2563EB` (Used for main actions, buttons, and links)
- **Primary Blue Dark**: `#1D4ED8` (Hover states and active elements)
- **Primary Blue Light**: `#3B82F6` (Secondary actions and highlights)

### Secondary Colors
- **Success Green**: `#10B981` (Success states, confirmations)
- **Warning Yellow**: `#F59E0B` (Warnings, pending states)
- **Error Red**: `#EF4444` (Errors, destructive actions)
- **Info Blue**: `#60A5FA` (Informational messages)

### Neutral Colors
- **Gray 900**: `#111827` (Text, headings)
- **Gray 700**: `#374151` (Secondary text)
- **Gray 500**: `#6B7280` (Placeholder text, disabled states)
- **Gray 300**: `#D1D5DB` (Borders, dividers)
- **Gray 100**: `#F3F4F6` (Backgrounds, cards)
- **White**: `#FFFFFF` (Backgrounds, light mode surfaces)

### Semantic Colors
- **Text Primary**: `Gray 900`
- **Text Secondary**: `Gray 700`
- **Text Disabled**: `Gray 500`
- **Border**: `Gray 300`
- **Background**: `Gray 100` or `White` based on theme

## Typography Scale

### Font Family
- **Primary Font**: Inter (Google Fonts)
- **Fallback**: Roboto, system-ui, sans-serif

### Font Weights
- **Light**: 300
- **Regular**: 400
- **Medium**: 500
- **SemiBold**: 600
- **Bold**: 700

### Typography Scale (Mobile First)

| Style | Font Size | Line Height | Font Weight | Use Case |
|-------|-----------|-------------|-------------|----------|
| H1 | 32px | 40px | Bold (700) | Page titles, major headings |
| H2 | 28px | 36px | SemiBold (600) | Section headings |
| H3 | 24px | 32px | SemiBold (600) | Sub-section headings |
| H4 | 20px | 28px | Medium (500) | Card titles, form labels |
| H5 | 18px | 26px | Medium (500) | Subtitles, small headings |
| Body Large | 18px | 28px | Regular (400) | Large body text |
| Body | 16px | 24px | Regular (400) | Standard body text |
| Body Small | 14px | 20px | Regular (400) | Captions, helper text |
| Caption | 12px | 16px | Regular (400) | Microcopy, labels |

### Responsive Typography
For larger screens (tablet/desktop), scale fonts proportionally:
- Mobile: Base size
- Tablet: +10% 
- Desktop: +20%

## Spacing System

### Base Unit
- **4px Grid System**: All spacing multiples of 4px

### Spacing Scale
| Size | Value | Use Case |
|------|-------|----------|
| XXS | 4px | Minimal spacing, tight layouts |
| XS | 8px | Small padding, tight margins |
| S | 12px | Standard padding, comfortable spacing |
| M | 16px | Medium padding, section spacing |
| L | 24px | Large padding, between major sections |
| XL | 32px | Extra large spacing, page margins |
| XXL | 48px | Maximum spacing, hero sections |

### Layout Grid
- **Mobile**: 4px grid, 16px margins
- **Tablet**: 4px grid, 24px margins  
- **Desktop**: 4px grid, 32px margins

## Breakpoints

### Device Categories
- **Mobile**: < 600px (phones)
- **Tablet**: 600px - 1024px (small tablets, large phones)
- **Desktop**: > 1024px (tablets, laptops, desktops)

### Fluid Breakpoints
Use media queries with min-width for fluid transitions:
```css
/* Mobile first approach */
@media (min-width: 600px) { /* Tablet styles */ }
@media (min-width: 1024px) { /* Desktop styles */ }
```

## Component Library

### Buttons
**Primary Button**
- Background: Primary Blue
- Text: White, SemiBold
- Padding: 12px 24px
- Border radius: 8px
- Hover: Primary Blue Dark
- Disabled: Gray 300 background, Gray 500 text

**Secondary Button**
- Background: Transparent
- Border: 2px Primary Blue
- Text: Primary Blue, SemiBold
- Hover: Primary Blue Light background

**Text Button**
- Background: Transparent
- Text: Primary Blue, Regular
- Hover: Primary Blue Light background

### Cards
- Background: White
- Border radius: 12px
- Shadow: 0 4px 6px rgba(0, 0, 0, 0.1)
- Padding: 16px
- Margin: 8px 0

### Forms
**Text Input**
- Height: 48px
- Border: 1px Gray 300
- Border radius: 8px
- Padding: 12px 16px
- Focus: 2px Primary Blue border

**Dropdown**
- Same as text input with dropdown arrow

**Checkbox/Radio**
- Size: 20px × 20px
- Border radius: 4px
- Focus: Primary Blue outline

### Navigation
**App Bar**
- Height: 56px (mobile), 64px (tablet/desktop)
- Background: White
- Shadow: 0 2px 4px rgba(0, 0, 0, 0.1)

**Bottom Navigation**
- Height: 56px
- Background: White
- Active indicator: Primary Blue

## Accessibility Guidelines

### Color Contrast
- Minimum AA compliance (4.5:1 for normal text)
- AAA compliance where possible (7:1 for normal text)
- Use tools like Lighthouse and accessibility scanners

### Focus Indicators
- Visible focus ring for all interactive elements
- Color: Primary Blue with 2px outline
- Offset: 2px from element

### Screen Reader Support
- Semantic HTML structure
- Proper ARIA labels
- Descriptive alt text for images
- Logical tab order

### Keyboard Navigation
- All interactive elements accessible via keyboard
- Skip navigation links
- Proper focus management

### Touch Targets
- Minimum 44px × 44px for touch targets
- Adequate spacing between interactive elements

## Responsive Patterns

### Adaptive Layouts
- **Mobile**: Single column, stacked elements
- **Tablet**: Two columns where appropriate, side navigation
- **Desktop**: Multi-column layouts, expanded navigation

### Fluid Typography
- Use clamp() or media queries for responsive font sizes
- Maintain comfortable line lengths (45-75 characters)

### Flexible Grids
- Percentage-based widths
- Max-width containers for large screens
- Flexible image and media handling

## Implementation Notes

### Flutter Specific
- Use ThemeData to define colors and typography
- Implement responsive breakpoints using MediaQuery
- Create reusable widget components
- Use const constructors for performance

### Web Specific
- CSS custom properties for theming
- CSS Grid and Flexbox for layouts
- REM units for scalable typography

## Version History
- v1.0.0: Initial design system definition
- Updated: 2025-09-13

## Resources
- [Figma Design File](https://figma.com/file/example) (To be created)
- [Flutter Documentation](https://flutter.dev/docs)
- [Web Content Accessibility Guidelines (WCAG)](https://www.w3.org/WAI/standards-guidelines/wcag/)