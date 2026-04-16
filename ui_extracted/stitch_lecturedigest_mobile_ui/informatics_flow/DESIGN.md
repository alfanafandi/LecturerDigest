# Design System Strategy: The Intelligent Flux

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Academic Flow."** 

Unlike rigid, blocky educational tools, this system mimics the fluid nature of intelligence and synthesis. For Indonesian Informatics students, the interface must feel as fast as a compiler but as approachable as a study group. We are moving away from "Material-as-a-Template" and toward **Editorial Utility**. 

We achieve this through **Asymmetric Energy**: using wide margins, generous whitespace, and intentional overlapping of elements to break the "grid-prison" feel. The goal is to make the AI summarization process feel like a premium, bespoke service—a digital concierge for the student’s academic journey.

---

## 2. Colors: The Tonal Ecosystem
We are moving beyond flat color fills. This system uses color to define "zones of focus."

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to define sections. 
*   **The Technique:** Boundaries must be defined solely through background color shifts. A `surface-container-low` (`#F3F4F5`) section sitting on a `surface` (`#F8F9FA`) background creates an organic edge. If you feel the need for a line, use more whitespace instead.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—stacked sheets of frosted glass.
*   **The Foundation:** `surface` (`#F8F9FA`).
*   **The Work Area:** `surface-container-lowest` (`#FFFFFF`) for the primary content card where the student reads the summary.
*   **The Contextual Layer:** `surface-container-high` (`#E7E8E9`) for sidebars or secondary navigation.

### The "Glass & Gradient" Rule
To inject "soul" into the Informatics aesthetic, use **Glassmorphism** for floating action buttons and navigation bars.
*   **Token Usage:** Use `surface` at 80% opacity with a `24px` backdrop-blur. 
*   **Signature Textures:** Apply a subtle linear gradient (Top-Left to Bottom-Right) from `primary` (`#006B5C`) to `primary-container` (`#00BFA5`) for main CTAs. This creates a "gem-like" depth that feels high-end and energetic.

---

## 3. Typography: Editorial Authority
We use a high-contrast scale to differentiate between "Reading" and "Operating."

*   **Display & Headlines (Plus Jakarta Sans):** These are our "Editorial" voices. Use `display-md` for empty states or major section headers to create a bold, modern Indonesian tech vibe. The wide apertures of Plus Jakarta Sans feel friendly yet professional.
*   **Body & Labels (Inter):** These are our "Functional" voices. Inter’s high x-height ensures that complex informatics terminology remains legible even at `body-sm`.
*   **Hierarchy Note:** Always pair a `headline-sm` in `on-surface` with a `label-md` in `primary` to create a clear "Category > Title" relationship that feels like a premium magazine.

---

## 4. Elevation & Depth: Tonal Layering
Traditional shadows are too heavy for a "clean" AI app. We use light.

*   **The Layering Principle:** Instead of a shadow, place a `surface-container-lowest` card on a `surface-container-low` background. The slight shift from `#FFFFFF` to `#F3F4F5` creates a "soft lift."
*   **Ambient Shadows:** For floating elements (e.g., the "Summarize" FAB), use a custom shadow: `0px 12px 32px rgba(0, 107, 92, 0.08)`. Notice the tint—we use a fraction of the `primary` color, not black, to simulate natural light.
*   **The "Ghost Border" Fallback:** If accessibility requires a container boundary, use `outline-variant` (`#BBCAC4`) at **15% opacity**. It should be felt, not seen.

---

## 5. Components: Style Guide

### Buttons (The "Jewel" Variants)
*   **Primary:** Gradient of `primary` to `primary-container`. `xl` (1.5rem) corner radius. No border.
*   **Secondary:** `secondary-container` background with `on-secondary-container` text.
*   **Tertiary:** Transparent background, `primary` text, with a `0.5rem` underline on hover.

### Cards & Lists (The "Breathable" Stack)
*   **Rule:** Forbid divider lines between list items. 
*   **The Style:** Use `16px` of vertical whitespace. Summaries should be housed in `surface-container-lowest` cards with an `lg` (1rem) corner radius. 

### Input Fields (The "Soft Focus")
*   **State:** Default state uses `surface-container-high` background with no border. On focus, transition to a `primary` "Ghost Border" (20% opacity) and a subtle internal glow.

### Signature Component: The "Digest Pulse"
A custom AI-loading state. Instead of a spinner, use a soft, breathing gradient pulse that expands from the center of the card using `primary-fixed-dim` (`#44DDC1`) to signify the AI is "thinking."

---

## 6. Do’s and Don'ts

### Do:
*   **Use Asymmetry:** Place the "Lecture Title" off-center or overlapping a header image to create a custom, high-end feel.
*   **Embrace White Space:** If a screen feels "busy," increase the padding by 8px before you try to add a border or background color.
*   **Contextual Dark Mode:** Ensure the "Soft Dark Mode" uses `surface-dim` (`#D9DADB`) for text rather than pure white to prevent eye strain during late-night study sessions.

### Don't:
*   **Don't use 100% Black:** Never use `#000000` for text; use `on-surface` (`#191C1D`) to maintain the premium, soft aesthetic.
*   **Don't use standard Material Shadows:** They are too "default." Always use the Ambient Shadow formula (tinted with primary).
*   **Don't crowd the Summaries:** The summary is the hero. Give it `24px` horizontal padding to ensure it feels like a readable document, not a data entry form.