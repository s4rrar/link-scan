---
name: motion-react-context
description: Full reference context for building React animations with Motion (v12.37.0). Covers motion components, animation props, transitions, variants, keyframes, gestures, scroll animations, layout animations, AnimatePresence, SVG, MotionValues, hooks, and more. Use when implementing or debugging any React animation, gesture, scroll-triggered effect, layout animation, or exit animation. Use when building with motion components, configuring transitions, or working with useAnimate/useScroll/useInView. Do NOT use for CSS-only animations, pure backend work, or non-React projects.
---

# Motion for React — AI Agent Context

> Source: https://motion.dev/docs/react  
> Version captured: June 2026 (Motion v12.37.0)  
> Purpose: Full reference context for opencode AI agents building React animations with Motion.

---

## Table of Contents

1. [Installation](#installation)
2. [The `<motion />` Component](#the-motion--component)
3. [Animatable Values](#animatable-values)
4. [Animation Props Reference](#animation-props-reference)
5. [Transitions](#transitions)
6. [Variants](#variants)
7. [Keyframes](#keyframes)
8. [Gestures](#gestures)
9. [Scroll Animations](#scroll-animations)
10. [Layout Animations](#layout-animations)
11. [Exit Animations — AnimatePresence](#exit-animations--animatepresence)
12. [SVG Animations](#svg-animations)
13. [Motion Values](#motion-values)
14. [Hooks](#hooks)
15. [Components Reference](#components-reference)
16. [Patterns & Examples](#patterns--examples)
17. [Performance Tips](#performance-tips)
18. [Common Pitfalls](#common-pitfalls)

---

## Installation

```bash
npm install motion
```

```tsx
// Standard React
import { motion, AnimatePresence } from "motion/react"

// React Server Components (Next.js App Router etc.)
import * as motion from "motion/react-client"
```

---

## The `<motion />` Component

Every HTML and SVG element has a `motion` counterpart. Prefix any tag with `motion.` to unlock animation props:

```tsx
<motion.div />
<motion.ul />
<motion.circle cx={0} />
<motion.a href="#" />
```

Motion components are **drop-in replacements** — they accept all standard HTML/SVG props plus animation props. They bypass React's render cycle; animations run natively at up to 120fps.

### Custom Components

Wrap any component with `motion.create()`. The component **must** forward its ref.

```tsx
// React 18
const Component = React.forwardRef((props, ref) => <div ref={ref} />)

// React 19 (ref via props)
const Component = (props) => <div ref={props.ref} />

const MotionComponent = motion.create(Component)
// Now accepts all motion props: animate, whileHover, layout, etc.
```

```tsx
// Custom DOM elements
const MotionCustom = motion.create('custom-element')

// Forward motion props to the wrapped component
motion.create(Component, { forwardMotionProps: true })
```

> ⚠️ Never call `motion.create()` inside a render function — it creates a new component on every render.

### Server-Side Rendering

Motion components are fully SSR-compatible. The initial state is reflected in server output:

```tsx
// Server will output `translateX(100px)`
<motion.div initial={false} animate={{ x: 100 }} />
```

---

## Animatable Values

### CSS Properties

Any CSS value: `opacity`, `filter`, `backgroundColor`, `borderRadius`, etc.

```tsx
<motion.section
  initial={{ filter: "blur(10px)" }}
  animate={{ filter: "none" }}
/>
```

Motion can even animate values browsers can't natively animate, like `background-image` and `mask-image`:

```tsx
<motion.nav
  initial={{ maskImage: "linear-gradient(to right, rgba(0,0,0,1) 90%, rgba(0,0,0,0) 100%)" }}
  animate={{ maskImage: "linear-gradient(to right, rgba(0,0,0,1) 90%, rgba(0,0,0,1) 100%)" }}
/>
```

### Transform Shorthands

Motion animates every transform axis independently:

| Shorthand | Description |
|-----------|-------------|
| `x`, `y`, `z` | Translate |
| `scale`, `scaleX`, `scaleY` | Scale |
| `rotate`, `rotateX`, `rotateY`, `rotateZ` | Rotate |
| `skewX`, `skewY` | Skew |
| `transformPerspective` | Perspective |
| `originX`, `originY`, `originZ` | Transform origin |

```tsx
<motion.div animate={{ x: 100, rotate: 45, scale: 1.2 }} />

// Also usable in style prop (static)
<motion.section style={{ x: -20, rotate: 90 }} />
```

For SVG: use `attrX` / `attrY` instead of `x` / `y` for SVG attribute-space transforms.

### Supported Value Types

- Numbers: `0`, `100`
- Strings with units: `"0vh"`, `"10px"`, `"calc(100vw - 50%)"`
- Colors: hex, `rgba`, `hsla`, `oklch`, `oklab`, `color-mix`, etc.
- Complex strings: `box-shadow`, `text-shadow`
- `display: "none"/"block"` and `visibility: "hidden"/"visible"`

### Value Type Conversion

- Colors can freely convert between hex, RGBA, HSLA
- `x`, `y`, `width`, `height`, `top`, `left`, `right`, `bottom` can animate between different unit types
- `width`/`height` can animate to/from `"auto"`

```tsx
<motion.div
  initial={{ x: "100%" }}
  animate={{ x: "calc(100vw - 50%)" }}
/>

<motion.div
  initial={{ height: 0 }}
  animate={{ height: "auto" }}
/>
```

> ⚠️ When animating `height: auto` while also animating `display`, replace `display: none` with `visibility: hidden`.

### CSS Variables

```tsx
// Animate a CSS variable to drive many children
<motion.ul
  initial={{ '--rotate': '0deg' }}
  animate={{ '--rotate': '360deg' }}
  transition={{ duration: 2, repeat: Infinity }}
>
  <li style={{ transform: 'rotate(var(--rotate))' }} />
  <li style={{ transform: 'rotate(var(--rotate))' }} />
</motion.ul>

// Use a CSS variable as an animation target
<motion.li animate={{ backgroundColor: "var(--action-bg)" }} />
```

---

## Animation Props Reference

### `initial`

The initial visual state. Can be an animation target, variant label(s), or `false`.

```tsx
<motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} />
<motion.div initial="hidden" animate="visible" />
<motion.div initial={["hidden", "inactive"]} animate="visible" />
<motion.div initial={false} animate={{ opacity: 1 }} /> // skip enter animation
```

### `animate`

Target to animate to on enter and on every update.

```tsx
<motion.div animate={{ scale: 2, rotate: 90 }} />
<motion.div animate="visible" />
<motion.div animate={["visible", "active"]} />
```

### `exit`

Target to animate to when removed from the React tree (requires `AnimatePresence` as parent).

```tsx
<AnimatePresence>
  {show && (
    <motion.div
      key="modal"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    />
  )}
</AnimatePresence>
```

### `transition`

Defines the animation type, timing, and easing. See [Transitions](#transitions) for full options.

```tsx
<motion.div
  animate={{ x: 100 }}
  transition={{ ease: "easeOut", duration: 0.5 }}
/>
```

### `variants`

Named animation states for orchestration. See [Variants](#variants).

### `style`

Standard React `style` prop with added support for motion values and independent transforms.

```tsx
const x = useMotionValue(30)
<motion.div style={{ x, rotate: 90, originX: 0.5 }} />
```

### `whileHover`, `whileTap`, `whileFocus`, `whileDrag`, `whileInView`

Animation targets while a gesture is active. See [Gestures](#gestures).

### `layout`, `layoutId`

Enable layout animations. See [Layout Animations](#layout-animations).

### Callbacks

```tsx
<motion.div
  onUpdate={latest => console.log(latest)}
  onAnimationStart={definition => console.log(definition)}
  onAnimationComplete={definition => console.log(definition)}
  onLayoutAnimationStart={() => {}}
  onLayoutAnimationComplete={() => {}}
/>
```

---

## Transitions

A `transition` object controls how values animate between states.

```tsx
const transition = {
  duration: 0.8,
  delay: 0.5,
  ease: [0, 0.71, 0.2, 1.01],
}

<motion.div animate={{ x: 100 }} transition={transition} />
```

### Setting Defaults

**Per-component:**
```tsx
<motion.div
  animate={{ x: 100 }}
  transition={{ type: "spring", stiffness: 100 }}
/>
```

**Global via `MotionConfig`:**
```tsx
<MotionConfig transition={{ duration: 0.4, ease: "easeInOut" }}>
  <App />
</MotionConfig>
```

**Per-value:**
```tsx
<motion.li
  animate={{
    x: 0,
    opacity: 1,
    transition: {
      default: { type: "spring" },
      opacity: { ease: "linear" }
    }
  }}
/>
```

**Per-gesture:**
```tsx
<motion.div
  animate={{ opacity: 1 }}
  whileHover={{ opacity: 0.7, transition: { duration: 0.2 } }}
  transition={{ duration: 0.5 }}
/>
```

### Tween Options

| Option | Default | Description |
|--------|---------|-------------|
| `type` | Dynamic | `"tween"`, `"spring"`, or `"inertia"` |
| `duration` | `0.3` | Duration in seconds (or `0.8` for keyframes) |
| `ease` | varies | Easing name, cubic bezier array, or function |
| `times` | evenly spaced | Keyframe timing positions (0–1) |

**Easing names:** `"linear"`, `"easeIn"`, `"easeOut"`, `"easeInOut"`, `"circIn"`, `"circOut"`, `"circInOut"`, `"backIn"`, `"backOut"`, `"backInOut"`, `"anticipate"`

```tsx
// Cubic bezier
<motion.div animate={{ x: 100 }} transition={{ ease: [0.17, 0.67, 0.83, 0.67] }} />

// Per-keyframe easing
<motion.div
  animate={{ x: [0, 100, 0] }}
  transition={{ ease: ["easeIn", "easeOut"] }}
/>
```

### Spring Options

| Option | Default | Description |
|--------|---------|-------------|
| `type` | | Set to `"spring"` |
| `bounce` | `0.25` | Bounciness 0–1 |
| `visualDuration` | | Visual time to reach target (easier to tune) |
| `damping` | `10` | Opposing force; 0 = infinite oscillation |
| `stiffness` | `1` | Spring stiffness; higher = more sudden |
| `mass` | `1` | Mass; higher = more lethargic |
| `velocity` | current | Initial velocity |
| `restSpeed` | `0.1` | End if speed drops below this |
| `restDelta` | `0.01` | End if distance is below this |

```tsx
// Duration-based spring (easiest to understand)
<motion.div
  animate={{ rotate: 90 }}
  transition={{ type: "spring", visualDuration: 0.5, bounce: 0.25 }}
/>

// Physics-based spring
<motion.div
  animate={{ x: 100 }}
  transition={{ type: "spring", stiffness: 300, damping: 20, mass: 1 }}
/>
```

### Inertia Options

Used for drag momentum. Key options: `power`, `timeConstant`, `modifyTarget`, `min`, `max`, `bounceStiffness`, `bounceDamping`.

```tsx
<motion.div
  drag
  dragTransition={{
    power: 0,
    modifyTarget: target => Math.round(target / 50) * 50  // snap to grid
  }}
/>
```

### Orchestration

| Option | Default | Description |
|--------|---------|-------------|
| `delay` | `0` | Delay in seconds (negative = start partway through) |
| `repeat` | `0` | Repetitions; `Infinity` for loop |
| `repeatType` | `"loop"` | `"loop"`, `"reverse"`, or `"mirror"` |
| `repeatDelay` | `0` | Pause between repetitions |
| `when` | `false` | `"beforeChildren"` or `"afterChildren"` (variants) |
| `delayChildren` | `0` | Delay for children animations (variants) |

```tsx
// Infinite loop with reverse
<motion.div
  animate={{ rotate: 180 }}
  transition={{ repeat: Infinity, repeatType: "reverse", duration: 2 }}
/>

// Stagger children
import { stagger } from "motion/react"

const container = {
  show: {
    opacity: 1,
    transition: {
      delayChildren: stagger(0.1),            // 0.1s between each
      // or: delayChildren: stagger(0.1, { from: "last" })
    }
  }
}
```

### Transition Inheritance

By default higher-specificity transitions replace lower-specificity ones. Set `inherit: true` to merge them:

```tsx
<MotionConfig transition={{ duration: 1, ease: "linear" }}>
  <motion.div
    animate={{ x: 100 }}
    transition={{ inherit: true, ease: "easeInOut" }} // inherits duration: 1
  />
</MotionConfig>
```

---

## Variants

Variants define named animation states that propagate through component trees.

### Basic Usage

```tsx
const variants = {
  visible: { opacity: 1, x: 0 },
  hidden: { opacity: 0, x: -100 },
}

<motion.div
  variants={variants}
  initial="hidden"
  animate="visible"
  exit="hidden"
  whileInView="visible"
/>
```

Multiple variants:
```tsx
<motion.div animate={["visible", "danger"]} />
```

### Propagation

Variant labels flow down through the `motion` component tree automatically:

```tsx
const list = {
  visible: { opacity: 1 },
  hidden: { opacity: 0 },
}

const item = {
  visible: { opacity: 1, x: 0 },
  hidden: { opacity: 0, x: -100 },
}

<motion.ul initial="hidden" whileInView="visible" variants={list}>
  <motion.li variants={item} />
  <motion.li variants={item} />
  <motion.li variants={item} />
</motion.ul>
```

### Orchestration in Variants

```tsx
const list = {
  visible: {
    opacity: 1,
    transition: {
      when: "beforeChildren",       // parent finishes first
      delayChildren: stagger(0.3),  // stagger children by 0.3s
    },
  },
  hidden: {
    opacity: 0,
    transition: { when: "afterChildren" },
  },
}
```

### Dynamic Variants

Each variant can be a function receiving `custom` prop data:

```tsx
const variants = {
  hidden: { opacity: 0 },
  visible: (index) => ({
    opacity: 1,
    transition: { delay: index * 0.3 }
  })
}

items.map((item, index) => (
  <motion.div custom={index} variants={variants} />
))
```

---

## Keyframes

Pass an array to animate through a series of values:

```tsx
<motion.div animate={{ x: [0, 100, 0] }} />

// Use null as "current value" wildcard
<motion.div animate={{ x: [null, 100, 0] }} />

// Hold a value mid-animation
<motion.div animate={{ x: [0, 100, null, 0] }} />
// same as [0, 100, 100, 0] but cleaner
```

### Keyframe Timing

```tsx
<motion.div
  animate={{
    x: [0, 100, 200],
    transition: { duration: 3, times: [0, 0.2, 1] }
  }}
/>
```

---

## Gestures

### Hover

```tsx
<motion.button
  whileHover={{ scale: 1.1 }}
  onHoverStart={(event) => console.log('hover start')}
  onHoverEnd={(event) => console.log('hover end')}
/>
```

### Tap / Press

```tsx
<motion.button
  whileTap={{ scale: 0.95 }}
  onTapStart={(event) => {}}
  onTap={(event) => {}}
  onTapCancel={(event) => {}} // released outside element
/>
```

### Focus

```tsx
<motion.button whileFocus={{ outline: "dashed #000" }} />
```

### Drag

```tsx
// Basic drag (both axes)
<motion.div drag />

// Single axis
<motion.div drag="x" />

// With constraints
<motion.div
  drag="x"
  dragConstraints={{ left: 0, right: 300 }}
  dragElastic={0.2}         // 0 = no elastic, 1 = full
  dragMomentum={true}       // inertia on release
  dragSnapToOrigin          // snap back when released
  whileDrag={{ scale: 0.9 }}
/>

// Constraints via ref
const constraintsRef = useRef(null)
<motion.div ref={constraintsRef}>
  <motion.div drag dragConstraints={constraintsRef} />
</motion.div>
```

### Drag Controls

Initiate drag from a separate element:

```tsx
const dragControls = useDragControls()

function startDrag(event) {
  dragControls.start(event, { snapToCursor: true })
}

<div onPointerDown={startDrag} />
<motion.div drag="x" dragControls={dragControls} dragListener={false} />
```

### Pan

```tsx
<motion.div
  onPan={(event, info) => {
    console.log(info.point, info.delta, info.offset, info.velocity)
  }}
  onPanStart={(event, info) => {}}
  onPanEnd={(event, info) => {}}
/>
```

### Motion Along a Path

Use `arc()` to curve the trajectory between two points:

```tsx
import { arc, motion } from "motion/react"

<motion.div
  animate={{ x: 200, y: -120 }}
  transition={{ duration: 0.6, path: arc() }}
/>

// Also works with layout animations
<motion.div layout transition={{ layout: { path: arc() } }} />
```

Or use CSS `offset-path` for fixed paths:

```tsx
<motion.div
  style={{ offsetPath: "path('M0,0 C40,-80 160,-80 200,0')" }}
  animate={{ offsetDistance: "100%" }}
  transition={{ duration: 2 }}
/>
```

### Gesture Propagation Control

```tsx
<motion.div whileTap={{ scale: 2 }}>
  {/* Pressing button won't trigger parent's scale */}
  <motion.button
    whileTap={{ opacity: 0.8 }}
    propagate={{ tap: false }}
  />
</motion.div>
```

---

## Scroll Animations

### Scroll-Triggered (`whileInView`)

```tsx
// Fade in when entering viewport
<motion.div
  initial={{ opacity: 0 }}
  whileInView={{ opacity: 1 }}
/>

// Only animate once
<motion.section
  initial="hidden"
  whileInView="visible"
  viewport={{ once: true }}
/>

// Custom scroll container
const scrollRef = useRef(null)
<div ref={scrollRef} style={{ overflow: "scroll" }}>
  <motion.div
    initial={{ opacity: 0 }}
    whileInView={{ opacity: 1 }}
    viewport={{ root: scrollRef }}
  />
</div>
```

**`viewport` options:**

| Option | Description |
|--------|-------------|
| `once` | Only trigger once |
| `root` | `ref` to a custom scroll container |
| `margin` | Detection margin, e.g. `"0px -20px 0px 100px"` |
| `amount` | `"some"`, `"all"`, or `0`–`1` |

### Scroll-Triggered State (`useInView`)

```tsx
import { useInView } from "motion/react"

function Component() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true })

  return <div ref={ref}>{isInView ? "Visible!" : "Hidden"}</div>
}
```

### Scroll-Linked (`useScroll`)

`useScroll` returns four motion values:

```tsx
const { scrollX, scrollY, scrollXProgress, scrollYProgress } = useScroll()
```

**Reading progress bar:**

```tsx
const { scrollYProgress } = useScroll()
<motion.div style={{ scaleX: scrollYProgress, originX: 0 }} />
```

**Track a specific element through viewport:**

```tsx
const ref = useRef(null)
const { scrollYProgress } = useScroll({
  target: ref,
  offset: ["start end", "end start"]
  // offset format: ["<target-edge> <container-edge>", ...]
  // e.g. "start end" = top of target meets bottom of container
})
```

**Transform scroll to other values:**

```tsx
const { scrollYProgress } = useScroll()

const opacity = useTransform(scrollYProgress, [0, 1], [0, 1])
const scale = useTransform(scrollYProgress, [0, 0.5, 1], [0.8, 1, 0.8])
const blur = useTransform(scrollYProgress, [0, 1], ["blur(0px)", "blur(10px)"])

<motion.div style={{ opacity, scale, filter: blur }} />
```

**Smooth scroll values:**

```tsx
const { scrollYProgress } = useScroll()
const scaleX = useSpring(scrollYProgress, {
  stiffness: 100,
  damping: 30,
  restDelta: 0.001
})
```

**Detect scroll direction:**

```tsx
const { scrollY } = useScroll()
const [direction, setDirection] = useState("down")

useMotionValueEvent(scrollY, "change", (current) => {
  const diff = current - scrollY.getPrevious()
  setDirection(diff > 0 ? "down" : "up")
})
```

**Horizontal scroll section:**

```tsx
const containerRef = useRef(null)
const { scrollYProgress } = useScroll({
  target: containerRef,
  offset: ["start start", "end end"]
})
const x = useTransform(scrollYProgress, [0, 1], ["0%", "-75%"])

<div ref={containerRef} style={{ height: "300vh" }}>
  <div style={{ position: "sticky", top: 0, height: "100vh", overflow: "hidden" }}>
    <motion.div style={{ x, display: "flex", gap: 20 }}>
      {items.map(item => (
        <div key={item.id} style={{ flexShrink: 0, width: 400 }}>
          {item.content}
        </div>
      ))}
    </motion.div>
  </div>
</div>
```

**Image reveal on scroll:**

```tsx
const ref = useRef(null)
const { scrollYProgress } = useScroll({
  target: ref,
  offset: ["start end", "center center"]
})

const clipPath = useTransform(
  scrollYProgress,
  [0, 1],
  ["inset(0% 50% 0% 50%)", "inset(0% 0% 0% 0%)"]
)

<motion.div ref={ref} style={{ clipPath }}>
  <img src="/photo.jpg" alt="" />
</motion.div>
```

**Parallax:**

```tsx
const { scrollY } = useScroll()
const backgroundY = useTransform(scrollY, [0, 1000], [0, -200], { clamp: false })
const foregroundY = useTransform(scrollY, [0, 1000], [0, -500], { clamp: false })
```

---

## Layout Animations

### Basic Layout

Add `layout` to any `motion` component to automatically animate size and position changes:

```tsx
<motion.div layout />

// Only animate position
<motion.img layout="position" />

// Only animate size
<motion.div layout="size" />
```

```tsx
// Example: animated toggle
<motion.div
  layout
  style={{ justifyContent: isOn ? "flex-start" : "flex-end" }}
/>
```

### Customise Layout Transitions

```tsx
<motion.div
  layout
  transition={{
    ease: "linear",
    layout: { duration: 0.3 }  // dedicated layout transition
  }}
/>
```

### Shared Layout (`layoutId`)

Connect two different elements to animate between them:

```tsx
// Tab underline example
{tabs.map(tab => (
  <button key={tab.id} onClick={() => setActive(tab.id)}>
    {tab.label}
    {activeTab === tab.id && (
      <motion.div layoutId="underline" />
    )}
  </button>
))}
```

```tsx
// Card expand example
<AnimatePresence>
  {isOpen && (
    <motion.dialog layoutId="modal" transition={{ duration: 0.3 }} />
  )}
</AnimatePresence>
<motion.button layoutId="modal" onClick={() => setIsOpen(true)}>
  Open
</motion.button>
```

### Performance Hint

```tsx
// Only re-measure when this value changes
<motion.nav layout layoutDependency={isOpen} />
```

### Scrollable Containers

```tsx
<motion.div layoutScroll style={{ overflow: "scroll" }}>
  <motion.div layout />
</motion.div>
```

### Fixed Containers

```tsx
<motion.div layoutRoot style={{ position: "fixed" }}>
  <motion.div layout />
</motion.div>
```

### Group Layout Animations (`LayoutGroup`)

Sync layout animations across components that don't share state:

```tsx
import { LayoutGroup } from "motion/react"

<LayoutGroup>
  <Accordion />
  <Accordion />
</LayoutGroup>
```

### Fix Child Distortion

Since layout animations use `transform: scale()`, children can look distorted. Fix by giving them `layout` too:

```tsx
<motion.section layout>
  <motion.img layout />  {/* counter-scaled */}
</motion.section>

// For border-radius/box-shadow, set via style:
<motion.div layout style={{ borderRadius: 20 }} />
```

### Layout Anchor

Control the relative projection point (default: top-left):

```tsx
<motion.ul layout>
  <motion.li
    layout
    layoutAnchor={{ x: 0.5, y: 0.5 }}  // center
    transition={{ delay: 1 }}
  />
</motion.ul>
// 0 = top/left, 0.5 = center, 1 = bottom/right
```

---

## Exit Animations — AnimatePresence

`AnimatePresence` keeps removed elements in the DOM until their `exit` animation completes.

### Basic Usage

```tsx
import { AnimatePresence, motion } from "motion/react"

<AnimatePresence>
  {isVisible && (
    <motion.div
      key="modal"
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.8 }}
    />
  )}
</AnimatePresence>
```

> ⚠️ All direct children must have a unique, stable `key` prop.  
> ⚠️ `AnimatePresence` itself must not be conditionally rendered.

### Modes

```tsx
// Default: enter and exit simultaneously
<AnimatePresence mode="sync">...</AnimatePresence>

// New element waits for exiting element to finish
<AnimatePresence mode="wait">...</AnimatePresence>

// Exiting element is "popped" out of page flow immediately
<AnimatePresence mode="popLayout">
  {items.map(item => (
    <motion.li layout exit={{ opacity: 0 }} key={item.id} />
  ))}
</AnimatePresence>
```

### Slideshow Pattern

Change `key` to trigger enter/exit on every slide change:

```tsx
<AnimatePresence>
  <motion.img
    key={image.src}
    src={image.src}
    initial={{ x: 300, opacity: 0 }}
    animate={{ x: 0, opacity: 1 }}
    exit={{ x: -300, opacity: 0 }}
  />
</AnimatePresence>
```

### Custom Exit Data

When a component is removed, props can't be updated. Pass data via `AnimatePresence`:

```tsx
const variants = {
  hidden: (direction) => ({
    opacity: 0,
    x: direction === 1 ? -300 : 300
  }),
  visible: { opacity: 1, x: 0 }
}

<AnimatePresence custom={direction}>
  <motion.img
    key={image.src}
    variants={variants}
    initial="hidden"
    animate="visible"
    exit="hidden"
  />
</AnimatePresence>
```

Access in children with `usePresenceData()`.

### Presence Hooks

```tsx
import { useIsPresent, usePresence } from "motion/react"

// Read presence state
function Component() {
  const isPresent = useIsPresent()
  return <div>{isPresent ? "Here" : "Exiting"}</div>
}

// Manual control over removal timing
function Component() {
  const [isPresent, safeToRemove] = usePresence()

  useEffect(() => {
    if (!isPresent) {
      setTimeout(safeToRemove, 1000)  // keep in DOM for 1s after removal
    }
  }, [isPresent])

  return <div />
}
```

### Propagating Exit Animations

```tsx
<AnimatePresence>
  {show && (
    <motion.section exit={{ opacity: 0 }}>
      {/* propagate=true: children's exit fires when parent exits */}
      <AnimatePresence propagate>
        <motion.div exit={{ x: -100 }} />
      </AnimatePresence>
    </motion.section>
  )}
</AnimatePresence>
```

### `onExitComplete`

```tsx
<AnimatePresence onExitComplete={() => console.log("all done")}>
  ...
</AnimatePresence>
```

---

## SVG Animations

Motion supports all SVG elements and has special SVG values:

```tsx
// Path drawing
<motion.path
  initial={{ pathLength: 0, pathOffset: 0 }}
  animate={{ pathLength: 1 }}
  transition={{ duration: 2 }}
/>

// Path opacity
<motion.path
  animate={{ pathLength: 1, pathSpacing: 0.5 }}
/>

// Circle
<motion.circle animate={{ r: 50, cx: 100, cy: 100 }} />

// viewBox
<motion.svg animate={{ viewBox: "0 0 200 200" }} />
```

For SVG attribute space transforms use `attrX`/`attrY`:

```tsx
<motion.circle attrX={50} attrY={50} />
```

---

## Motion Values

Motion values are observable values that can drive animations without React re-renders.

### `useMotionValue`

```tsx
import { useMotionValue, motion, animate } from "motion/react"

const x = useMotionValue(0)

// Pass to style
<motion.div style={{ x }} />

// Update without re-render
useEffect(() => {
  x.set(100)
}, [])

// Subscribe to changes
useEffect(() => {
  const unsubscribe = x.on("change", (latest) => console.log(latest))
  return unsubscribe
}, [])

// Animate a motion value imperatively
animate(x, 100, { duration: 1 })
```

### `useTransform`

Map one motion value to another:

```tsx
const x = useMotionValue(0)

// Map x (0–200) to opacity (0–1)
const opacity = useTransform(x, [0, 200], [0, 1])

// With easing
const opacity = useTransform(x, [0, 200], [0, 1], { ease: easeInOut })

// Function form
const doubled = useTransform(() => x.get() * 2)
```

### `useSpring`

Smooth a value with spring physics:

```tsx
const x = useMotionValue(0)
const springX = useSpring(x, { stiffness: 300, damping: 30 })

// Smooth scroll progress
const { scrollYProgress } = useScroll()
const smoothProgress = useSpring(scrollYProgress, { stiffness: 100, damping: 30 })
```

### `useMotionTemplate`

Combine motion values into a string:

```tsx
const x = useMotionValue(0)
const y = useMotionValue(0)
const transform = useMotionTemplate`translateX(${x}px) translateY(${y}px)`

<motion.div style={{ transform }} />
```

### `useScroll`

```tsx
const {
  scrollX,           // pixels
  scrollY,           // pixels
  scrollXProgress,   // 0–1
  scrollYProgress,   // 0–1
} = useScroll({
  target: ref,                          // optional element to track
  offset: ["start end", "end start"],   // scroll range
  container: scrollContainerRef,        // custom scroll container
  axis: "y",                            // "x" | "y"
})
```

### `useVelocity`

```tsx
const x = useMotionValue(0)
const velocity = useVelocity(x)
const acceleration = useVelocity(velocity)
```

### `useTime`

Milliseconds since component mounted — useful for time-based animations:

```tsx
const time = useTime()
const rotate = useTransform(time, [0, 4000], [0, 360], { clamp: false })
<motion.div style={{ rotate }} />
```

### `useMotionValueEvent`

```tsx
useMotionValueEvent(scrollY, "change", (latest) => {
  console.log(latest)
})
```

### Animate content with MotionValue

Render a motion value's number directly into the DOM (no re-render):

```tsx
function Counter() {
  const count = useMotionValue(0)

  useEffect(() => {
    const controls = animate(count, 100, { duration: 5 })
    return () => controls.stop()
  }, [])

  return <motion.pre>{count}</motion.pre>
}
```

---

## Hooks

### `useAnimate`

Scoped imperative animation controls:

```tsx
import { useAnimate } from "motion/react"

function Component({ children }) {
  const [scope, animate] = useAnimate()

  async function handleClick() {
    // Selectors are scoped to `scope`
    await animate("li", { opacity: 0, x: -100 })
    await animate(scope.current, { opacity: 0 })
  }

  return <ul ref={scope}>{children}</ul>
}
```

**With animation sequences:**

```tsx
useEffect(() => {
  const controls = animate([
    [scope.current, { x: "100%" }],
    ["li", { opacity: 1 }, { delay: stagger(0.1) }],
    [".badge", { scale: 1 }, { at: "<" }], // at: "<" starts with previous
  ])

  controls.speed = 0.8

  return () => controls.stop()
}, [])
```

**With `useInView`:**

```tsx
const [scope, animate] = useAnimate()
const isInView = useInView(scope)

useEffect(() => {
  if (isInView) {
    animate("li", { opacity: 1, y: 0 }, { delay: stagger(0.1) })
  }
}, [isInView])
```

**With `usePresence` (custom exit animations):**

```tsx
function Component() {
  const [isPresent, safeToRemove] = usePresence()
  const [scope, animate] = useAnimate()

  useEffect(() => {
    if (isPresent) {
      animate(scope.current, { opacity: 1 })
      animate("li", { opacity: 1, x: 0 }, { delay: stagger(0.05) })
    } else {
      (async () => {
        await animate("li", { opacity: 0, x: -100 }, { delay: stagger(0.05) })
        await animate(scope.current, { opacity: 0 })
        safeToRemove()
      })()
    }
  }, [isPresent])

  return <ul ref={scope}>{children}</ul>
}
```

### `useAnimationFrame`

Run a callback every animation frame:

```tsx
import { useAnimationFrame } from "motion/react"

useAnimationFrame((time, delta) => {
  // time: ms since mount
  // delta: ms since last frame
  rotate.set(time * 0.1)
})
```

### `useInView`

```tsx
import { useInView } from "motion/react"

const ref = useRef(null)
const isInView = useInView(ref, {
  once: true,
  root: scrollContainerRef,
  margin: "-100px",
  amount: 0.5,
})
```

### `useReducedMotion`

Respect user's reduced motion preference:

```tsx
import { useReducedMotion } from "motion/react"

function Component() {
  const shouldReduce = useReducedMotion()

  return (
    <motion.div
      animate={{ x: shouldReduce ? 0 : 100 }}
    />
  )
}
```

### `useDragControls`

See [Gestures → Drag Controls](#drag-controls).

---

## Components Reference

### `<MotionConfig>`

Set global defaults for all child `motion` components:

```tsx
import { MotionConfig } from "motion/react"

<MotionConfig
  transition={{ duration: 0.3, ease: "easeInOut" }}
  reducedMotion="user"  // "user" | "always" | "never"
>
  <App />
</MotionConfig>
```

### `<LayoutGroup>`

Sync layout animations across separate components. See [Layout Animations](#group-layout-animations).

```tsx
import { LayoutGroup } from "motion/react"

<LayoutGroup id="optional-namespace">
  <ComponentA />
  <ComponentB />
</LayoutGroup>
```

### `<LazyMotion>`

Reduce bundle size by lazy-loading animation features:

```tsx
import { LazyMotion, domAnimation, m } from "motion/react"

<LazyMotion features={domAnimation}>
  <m.div animate={{ opacity: 1 }} />
</LazyMotion>

// Async load for code splitting
const loadFeatures = () => import("motion/react").then(res => res.domAnimations)
<LazyMotion features={loadFeatures}>...</LazyMotion>
```

### `<Reorder>`

Drag-to-reorder lists:

```tsx
import { Reorder } from "motion/react"

const [items, setItems] = useState([1, 2, 3])

<Reorder.Group axis="y" values={items} onReorder={setItems}>
  {items.map(item => (
    <Reorder.Item key={item} value={item}>
      {item}
    </Reorder.Item>
  ))}
</Reorder.Group>
```

### `<AnimateView>` (Motion+)

Animate components as they enter and leave the viewport using WAAPI:

```tsx
import { AnimateView } from "motion/react"

<AnimateView
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
/>
```

### `<AnimateActivity>` 

Animate children within React Activity boundaries:

```tsx
import { AnimateActivity } from "motion/react"

<Activity mode={isActive ? "visible" : "hidden"}>
  <AnimateActivity>
    <motion.div layout exit={{ opacity: 0 }} />
  </AnimateActivity>
</Activity>
```

---

## Patterns & Examples

### Fade In on Enter

```tsx
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.4, ease: "easeOut" }}
/>
```

### Staggered List

```tsx
const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { delayChildren: stagger(0.1) }
  }
}

const item = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0 }
}

<motion.ul variants={container} initial="hidden" animate="show">
  {items.map(i => (
    <motion.li key={i} variants={item} />
  ))}
</motion.ul>
```

### Modal with AnimatePresence

```tsx
<AnimatePresence>
  {isOpen && (
    <motion.div
      key="overlay"
      className="overlay"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      onClick={() => setIsOpen(false)}
    >
      <motion.div
        className="modal"
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.8, opacity: 0 }}
        transition={{ type: "spring", bounce: 0.3 }}
        onClick={e => e.stopPropagation()}
      >
        {children}
      </motion.div>
    </motion.div>
  )}
</AnimatePresence>
```

### Hover Card with Lift Effect

```tsx
<motion.div
  whileHover={{ y: -4, boxShadow: "0 20px 40px rgba(0,0,0,0.2)" }}
  whileTap={{ y: -2 }}
  transition={{ type: "spring", stiffness: 400, damping: 20 }}
  style={{ borderRadius: 12 }}
/>
```

### Notification Stack

```tsx
<AnimatePresence>
  {notifications.map((notification, index) => (
    <motion.div
      key={notification.id}
      layout
      initial={{ opacity: 0, y: 50, scale: 0.3 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, scale: 0.5, transition: { duration: 0.2 } }}
    >
      {notification.message}
    </motion.div>
  ))}
</AnimatePresence>
```

### Reading Progress Bar

```tsx
function ReadingProgress() {
  const { scrollYProgress } = useScroll()
  const scaleX = useSpring(scrollYProgress, { stiffness: 200, damping: 40 })

  return (
    <motion.div
      style={{
        scaleX,
        originX: 0,
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        height: 4,
        background: "var(--accent)",
        zIndex: 1000,
      }}
    />
  )
}
```

### iOS App Store Card Expand

```tsx
// Card (collapsed)
<motion.div
  layoutId={`card-${id}`}
  onClick={() => setSelected(id)}
  style={{ borderRadius: 20 }}
/>

// Expanded card (in portal/modal)
<AnimatePresence>
  {selected && (
    <motion.div
      layoutId={`card-${selected}`}
      style={{ borderRadius: 10, position: "fixed", inset: 20 }}
    />
  )}
</AnimatePresence>
```

### Counter Animation

```tsx
function AnimatedCounter({ to }) {
  const count = useMotionValue(0)
  const rounded = useTransform(count, Math.round)

  useEffect(() => {
    const controls = animate(count, to, { duration: 2, ease: "easeOut" })
    return controls.stop
  }, [to])

  return <motion.span>{rounded}</motion.span>
}
```

### Mouse-Tracking Parallax

```tsx
function MouseParallax() {
  const mouseX = useMotionValue(0)
  const mouseY = useMotionValue(0)

  const handleMouseMove = (e) => {
    mouseX.set(e.clientX - window.innerWidth / 2)
    mouseY.set(e.clientY - window.innerHeight / 2)
  }

  const x = useTransform(mouseX, [-500, 500], [-20, 20])
  const y = useTransform(mouseY, [-500, 500], [-20, 20])

  return (
    <div onMouseMove={handleMouseMove}>
      <motion.div style={{ x, y }} />
    </div>
  )
}
```

### Scroll-Hide Header

```tsx
function Header() {
  const { scrollY } = useScroll()
  const [hidden, setHidden] = useState(false)

  useMotionValueEvent(scrollY, "change", (current) => {
    const diff = current - scrollY.getPrevious()
    setHidden(diff > 0 && current > 100)
  })

  return (
    <motion.header
      variants={{
        visible: { y: 0 },
        hidden: { y: "-100%" },
      }}
      animate={hidden ? "hidden" : "visible"}
      transition={{ duration: 0.35, ease: "easeInOut" }}
      style={{ position: "fixed", top: 0, width: "100%" }}
    />
  )
}
```

---

## Performance Tips

1. **Prefer animating `transform` and `opacity`** — these run on the compositor thread and don't trigger layout or paint.

2. **Avoid animating `width`/`height` directly** — use `layout` instead, which internally uses `transform: scale()`.

3. **Use motion values in `style` instead of React state** — avoids re-renders.

   ```tsx
   // ❌ Causes re-render
   const [x, setX] = useState(0)
   <div style={{ transform: `translateX(${x}px)` }} />

   // ✅ No re-render
   const x = useMotionValue(0)
   <motion.div style={{ x }} />
   ```

4. **Use `LazyMotion`** to tree-shake unused features for smaller bundles.

5. **CSS variables**: Animating CSS variables always triggers paint — use `MotionValue`s for high-frequency updates instead.

6. **Use `layoutDependency`** to avoid unnecessary measurements:

   ```tsx
   <motion.nav layout layoutDependency={isOpen} />
   ```

7. **`scrollbar-gutter: stable`** prevents unwanted layout animations when scrollbar appears/disappears:

   ```css
   body { overflow-y: auto; scrollbar-gutter: stable; }
   ```

---

## Common Pitfalls

### 1. Exit animations not working

- Every `AnimatePresence` direct child needs a unique, stable `key`
- `AnimatePresence` itself must not be conditionally rendered
- The `exit` prop must be on a direct/descendant `motion` component

```tsx
// ❌ Wrong — AnimatePresence conditionally rendered
{show && <AnimatePresence><Component /></AnimatePresence>}

// ✅ Correct
<AnimatePresence>
  {show && <Component key="comp" />}
</AnimatePresence>
```

### 2. `motion.create()` inside render

```tsx
// ❌ New component every render
function Component() {
  const MotionComp = motion.create(MyComp)  // BAD
  return <MotionComp />
}

// ✅ Outside component
const MotionComp = motion.create(MyComp)
function Component() { return <MotionComp /> }
```

### 3. Layout animation stretch

Give children the `layout` prop to prevent scale distortion:

```tsx
<motion.div layout>
  <motion.p layout />  {/* counter-scaled */}
</motion.div>
```

### 4. Border radius distortion

Always set via `style`, not CSS class, for Motion to correct it:

```tsx
// ❌ Motion can't correct this
<motion.div layout className="rounded-xl" />

// ✅ Motion corrects this
<motion.div layout style={{ borderRadius: 12 }} />
```

### 5. SVG layout animations

SVGs don't support layout animations. Animate their attributes directly:

```tsx
// ❌ Not supported
<motion.circle layout />

// ✅ Animate attributes
<motion.circle animate={{ r: 50, cx: 100, cy: 100 }} />
```

### 6. `display: inline` blocks transforms

Layout animations (and transform animations) don't work on `display: inline` elements.

### 7. Using `index` as key with AnimatePresence

```tsx
// ❌ Wrong — index changes when items reorder
{items.map((item, index) => <motion.li key={index} />)}

// ✅ Correct
{items.map(item => <motion.li key={item.id} />)}
```

### 8. AnimatePresence `mode="popLayout"` requires `position` on parent

```tsx
// ✅ Ensures correct absolute positioning during animation
<motion.ul layout style={{ position: "relative" }}>
  <AnimatePresence mode="popLayout">
    {items.map(item => <motion.li layout key={item.id} />)}
  </AnimatePresence>
</motion.ul>
```

---

## Quick Import Reference

```tsx
import {
  // Core
  motion,
  animate,
  stagger,
  arc,

  // Components
  AnimatePresence,
  AnimateActivity,
  AnimateView,
  LayoutGroup,
  LazyMotion,
  MotionConfig,
  
  // Reorder
  Reorder,

  // Hooks
  useAnimate,
  useAnimationFrame,
  useDragControls,
  useInView,
  usePageInView,
  useReducedMotion,
  useIsPresent,
  usePresence,
  usePresenceData,

  // Motion Values
  useMotionValue,
  useMotionTemplate,
  useMotionValueEvent,
  useScroll,
  useSpring,
  useTime,
  useTransform,
  useVelocity,

  // Types
  type Variants,
  type Transition,
  type MotionProps,
} from "motion/react"

// For RSC / Next.js Server Components
import * as motion from "motion/react-client"

// Mini bundle (no layout animations, smaller)
import { useAnimate } from "motion/react-mini"
```

---

*Sources: [motion.dev/docs/react](https://motion.dev/docs/react), [motion.dev/docs/react-animation](https://motion.dev/docs/react-animation), [motion.dev/docs/react-motion-component](https://motion.dev/docs/react-motion-component), [motion.dev/docs/react-transitions](https://motion.dev/docs/react-transitions), [motion.dev/docs/react-scroll-animations](https://motion.dev/docs/react-scroll-animations), [motion.dev/docs/react-layout-animations](https://motion.dev/docs/react-layout-animations), [motion.dev/docs/react-animate-presence](https://motion.dev/docs/react-animate-presence), [motion.dev/docs/react-use-animate](https://motion.dev/docs/react-use-animate)*
