# Motion — Web-to-Compose Porting Ledger (101 rules)

Verdict vocabulary: `PORT` = port as-is / `PORT_ADAPTED` = port the principle, translate the API / `DROP` = no Compose counterpart / `WRONG_FOR_COMPOSE` = porting it verbatim is wrong — port only the corrected kernel.

| # | Web rule (source) | Verdict | Compose equivalent | Rationale |
|---|---|---|---|---|
| 1 | Justified motion — every animation answers "why" (review-animations Std 1) | PORT | Judgment rule as-is | Framework-agnostic |
| 2 | Frequency fit — 100+/day and keyboard = forbidden, tens = reduced, occasional = standard, rare = delight (Std 2) | PORT | High frequency = `snap()` or drop AnimatedVisibility | keyboard → maps to shared-device primary tap, PIN keypad, IME |
| 3 | Responsive easing — enter/exit use ease-out, ease-in is blocked (Std 3) | PORT_ADAPTED | `tween(LinearOutSlowInEasing)` or `CubicBezierEasing(0.23f,1f,0.32f,1f)`; no `FastOutLinearInEasing`/`EaseIn` on entrances | Compose built-in curves are stronger than CSS — less "too weak" pressure |
| 4 | UI under 300ms (Std 4) | PORT_ADAPTED | `tween(durationMillis <= 300)`; flag longer tweens/keyframes | Threshold ports directly |
| 5 | Origin and physicality — popovers scale from their trigger, no scale(0), 0.9~0.97 + opacity (Std 5) | PORT_ADAPTED | `scaleIn(initialScale = 0.92f, transformOrigin = anchor) + fadeIn()`; Dialog uses Center | **Trap**: argument-less `scaleIn()` defaults to 0f — that alone violates scale(0) |
| 6 | Interruptibility — rapid taps and gestures retarget from the current state, no keyframes (Std 6) | PORT_ADAPTED | `animate*AsState`/`Animatable`/`updateTransition` + `spring()`/`tween()`; no `keyframes{}` and no snapTo-then-animateTo | Compose target-based APIs are interruptible by default — the violation takes a different shape |
| 7 | GPU-only — transform/opacity only, animating width/height/margin is a performance defect (Std 7) | WRONG_FOR_COMPOSE | Visual-only: `graphicsLayer{}`/`offset{}` lambdas. Real layout: `animateContentSize`, `animateItem`, `LookaheadScope` | No CSS layout/composite split — the real rule is phase discipline (no composition reads) |
| 8 | Honor prefers-reduced-motion + gate hover (Std 8) | PORT_ADAPTED | Verify at `ANIMATOR_DURATION_SCALE = 0`; state stays legible even when snapped; hover only via `collectIsHoveredAsState` | Compose honors MotionDurationScale automatically; touch has no fake hover |
| 9 | Asymmetric enter/exit — deliberate acts slow, responses snap (Std 9) | PORT | Hold `animateTo(1f, tween(2000, LinearEasing))` / release `animateTo(0f, tween(200, LinearOutSlowInEasing))` | Pure timing judgment |
| 10 | Coherence — motion matches product character, delete when unsure (Std 10) | PORT | The project = crisp dashboard: NoBouncy by default, short tweens | Pure judgment |
| 11 | Flag `transition: all` (escalation) | DROP | None — Compose animates explicitly, value by value | Nearest smell: catch-all `animateContentSize`, an Animatable doubling for unrelated properties |
| 12 | Flag scale(0) and pure-fade entrances | PORT_ADAPTED | Argument-less `scaleIn()`/`scaleOut()` auto-violates; a lone `fadeIn()` on a spatially anchored element is also flagged | The trigger is sharper here (defaults) |
| 13 | Flag ease-in on UI | PORT_ADAPTED | `FastOutLinearInEasing` (accelerate) is for off-screen exits only; same for `EaseIn*` | Names the Compose counterpart of ease-in |
| 14 | Flag animation on keyboard and high-frequency actions | PORT | Remove `AnimatedVisibility`/`AnimatedContent` on those paths, or use `snap()` | Maps to IME, repeated back presses, shared-device primary tap |
| 15 | Flag UI over 300ms | PORT_ADAPTED | grep `tween(N>300)` + `StiffnessVeryLow` that settles at a perceived 400ms+ | Spring settle time counts too |
| 16 | Flag transform-origin center on anchored popovers | PORT_ADAPTED | Dropdown anchored below = `scaleIn(transformOrigin = TransformOrigin(0.5f, 0f))`; Dialog uses Center | No Radix CSS variables — compute from anchor alignment |
| 17 | Flag keyframes on rapid-tap UI | PORT_ADAPTED | `keyframes{}` → `spring()`/`tween()` via `animate*AsState`/`updateTransition` | Includes restart-style LaunchedEffect animations |
| 18 | Flag Framer x/y/scale under load (main-thread rAF) | PORT_ADAPTED | Defer reads into a lambda modifier: `graphicsLayer{ translationX = x.value }` | Composition reads map to per-frame recomposition |
| 19 | Flag driving child transforms from parent CSS variables | PORT_ADAPTED | Hoist the Animatable but read it in the leaf's draw lambda; never pass per-frame values as parameters | Wide composition-scope invalidation is the analogue |
| 20 | Flag missing prefers-reduced-motion | PORT_ADAPTED | Auto-snap at scale 0 is free; what remains = UI where motion alone carries meaning; infinite needs an explicit stop | MotionDurationScale is honored automatically |
| 21 | Flag ungated :hover motion | DROP | None | Fake hover on touch taps is a web-only failure mode |
| 22 | Flag en-masse entrances (no stagger) | PORT_ADAPTED | `tween(delayMillis = index * 30..80)`; never gate input. But proposing a *new* stagger must pass the 4-question gate and frequency tier (don't invite motion onto high-frequency lists); check total stagger span (last delay + duration) against `--motion-ceiling` too | Compose is non-input-blocking by default — keep it that way |
| 23 | Fix 1: delete first | PORT | Remove the AnimatedVisibility/spec or use `snap()` | First move |
| 24 | Fix 2: reduce (duration, displacement, property count) | PORT | durationMillis ↓, delta ↓, concurrent values ↓ | As-is |
| 25 | Fix 3: correct the easing (ease-in → ease-out) | PORT_ADAPTED | `LinearOutSlowInEasing`/`FastOutSlowInEasing`/`CubicBezierEasing(0.23f,1f,0.32f,1f)` | Curve translation |
| 26 | Fix 4: correct origin and physicality | PORT_ADAPTED | `scaleIn(initialScale=0.95f, transformOrigin=anchor) + fadeIn()` | Same move |
| 27 | Fix 5: keyframes → transitions/springs | WRONG_FOR_COMPOSE | keyframes{} → spring()/tween(); gestures = `Animatable.animateTo(target, spring, initialVelocity)` | Every Compose API is interruptible — the "API migration" framing is itself wrong |
| 28 | Fix 6: move to GPU (layout → transform, will-change) | PORT_ADAPTED | Demote to the draw phase: `graphicsLayer{}`/`offset{}`/`drawBehind{}`; layer promotion = `Modifier.graphicsLayer` | The WAAPI clause drops out |
| 29 | Fix 7: asymmetric timing | PORT | Same tween pair as Std 9 | As-is |
| 30 | Fix 8: polish (blur masking, stagger, @starting-style, springs) | PORT_ADAPTED | `Modifier.blur(2.dp)` (API 31+); delayMillis stagger; `MutableTransitionState(false).apply{targetState=true}`; `DampingRatioLowBouncy` | blur is a no-op below API 31 |
| 31 | Fix 9: accessibility and coherence | PORT_ADAPTED | Verify at scale 0; align with the project's shared motion tokens | The hover clause drops out |
| 32 | CSS is off-thread and fast, JS drops frames (Guidelines) | WRONG_FOR_COMPOSE | tween = scheduled motion, spring = gesture motion; performance comes from lambda reads | No thread dichotomy in Compose — don't port "declarative is faster" |
| 33 | Slow motion, real devices, re-review the next day (Guidelines) | PORT_ADAPTED | `adb shell settings put global animator_duration_scale 10`; scrcpy recording and frame stepping; gestures on a real device | Matches emulator-verification practice |
| 34 | Single Before/After/Why table + impact grouping + Block/Approve + file:line (Output) | PORT | Compose code instead of CSS in the Before/After cells | Block criteria translated: high-frequency motion, bare scaleIn, accelerating entrances, composition reads with an easy lambda fix |
| 35 | Easing decision order: enter/exit→ease-out, move→in-out, hover/color→ease, constant→linear (STANDARDS) | PORT_ADAPTED | enter/exit→`LinearOutSlowIn`; move→`FastOutSlowIn`; color→tween(FastOutSlowIn)/default spring; constant→`LinearEasing`; default→`LinearOutSlowIn` | 1:1 curve mapping |
| 36 | Three custom curves + easing.dev (STANDARDS) | PORT_ADAPTED | `CubicBezierEasing(0.23f,1f,0.32f,1f)` / `(0.77f,0f,0.175f,1f)` / `(0.32f,0.72f,0f,1f)` as shared tokens | Introduce only when Material curves feel flat |
| 37 | Duration budgets: press 100-160 / tooltip 125-200 / dropdown 150-250 / modal 200-500 (STANDARDS) | PORT_ADAPTED | Same numbers as tween budgets — house cap: `--motion-ceiling` 300ms takes precedence (aligned with the project motion token `--motion-modal`) | Same perceptual basis (180ms feels better than 400ms) |
| 38 | Press feedback: scale(0.97), 160ms ease-out (STANDARDS) | PORT_ADAPTED | `collectIsPressedAsState()` + `animateFloatAsState` + `graphicsLayer{}`; scale 0.95~0.98 | Ports precisely via InteractionSource |
| 39 | When to spring: momentum drags, alive elements, interruptible gestures (STANDARDS) | PORT_ADAPTED | `spring(dampingRatio, stiffness)`; `Animatable.animateTo(..., initialVelocity)` | Compose springs also carry velocity automatically on retarget |
| 40 | Spring configs: duration+bounce / physics triplet, bounce 0.1-0.3 (STANDARDS) | PORT_ADAPTED | bounce ≈ 1−dampingRatio; duration→stiffness (Appendix A); `{1,100,10}` = `spring(0.5f, 100f)` exactly | duration+bounce is a perceptual unit — conversion is approximate, on-device feel-check required |
| 41 | Decorative pointer tracking springs; functional graphs get no motion (STANDARDS) | PORT_ADAPTED | Animatable retargeted to the pointer (`animateTo`, not `snapTo`); functional data display = no motion | Includes the decorative-only gate |
| 42 | @starting-style mount animation (STANDARDS) | PORT_ADAPTED | `AnimatedVisibility(visibleState = remember{MutableTransitionState(false)}.apply{targetState=true})` | The first-class idiom for first-composition entrances |
| 43 | translateY(100%) — move relative to own height (STANDARDS) | PORT_ADAPTED | `slideInVertically{ it }` / `slideOutVertically{ it }`; no hardcoded .dp for full-height reveals | The measured-size lambda is the exact analogue |
| 44 | scale() also scales children — for press feedback (STANDARDS) | PORT_ADAPTED | `graphicsLayer{ scaleX/scaleY }` scales the drawn subtree uniformly — it is not a size change | Same behavior |
| 45 | rotateX/Y + preserve-3d (STANDARDS) | PORT_ADAPTED | `graphicsLayer{ rotationX/rotationY; cameraDistance = 8*density }` | graphicsLayer flattens — multi-element 3D needs manual math + feel-check |
| 46 | clip-path inset animation as a tool (STANDARDS) | PORT_ADAPTED | `drawWithContent{ clipRect(right = size.width*fraction){ drawContent() } }` | Draw-phase clipping is the equivalent and is cheap |
| 47 | Tab color-transition clip trick (emil) | PORT_ADAPTED | Two-layer draw + animated clipRect; the idiomatic alternative (indicator offset + animateColorAsState) is usually enough | Reserved for pixel-perfect inverted-text tabs only |
| 48 | Hold-to-confirm: inset 2s linear / release 200ms ease-out + scale 0.97 (emil) | PORT_ADAPTED | `Animatable(0f)`: press `animateTo(1f, tween(2000, LinearEasing))` / release `animateTo(0f, tween(200, LinearOutSlowInEasing))`; drawBehind clipRect | Fits destructive admin actions |
| 49 | Scroll-in reveal (emil) | PORT_ADAPTED | Per-key first-exposure flag in LazyColumn + one-shot fraction → clipRect | The frequency gate still applies (not on high-traffic lists) |
| 50 | Comparison-slider clip (emil) | PORT_ADAPTED | Two images in a Box; top one `drawWithContent{ clipRect(right = dragX) }`; `detectHorizontalDragGestures` | Ports directly |
| 51 | Momentum dismissal: velocity > ~0.11px/ms (STANDARDS) | PORT_ADAPTED | `VelocityTracker`/`onDragStopped(velocity)`; `abs(v) > 125.dp/s` (`--motion-flick-velocity`, aligned with the project motion token; web convention ~110dp/s) OR a position threshold | Don't hand-compute ms math — use the first-class velocity plumbing |
| 52 | Edge rubber-banding: (overshoot·dim·0.55)/(dim+0.55·\|overshoot\|) (STANDARDS) | PORT_ADAPTED | Apply the pure formula as-is to over-drag deltas; use `Modifier.overscroll` for scrollables | The formula is framework-agnostic |
| 53 | Pointer capture (STANDARDS) | DROP | None | pointerInput streams events to the coroutine that saw the down — capture is the default |
| 54 | Multi-touch protection (STANDARDS) | PORT_ADAPTED | detectDragGestures tracks the initial pointer; custom awaitPointerEventScope must latch the first PointerId | Risk remains only in custom code |
| 55 | Crossfade blur masking, <20px (STANDARDS) | PORT_ADAPTED | `Modifier.blur(0→2.dp→0)` during AnimatedContent/Crossfade; under 20.dp; API 31+ | No-op on older devices — feel-check on target devices |
| 56 | Stagger 30-80ms, decorative only — never blocks input (STANDARDS) | PORT_ADAPTED | `tween(300, delayMillis = index*50, LinearOutSlowInEasing)`; clickable active from the first frame. If the total span (last delay + duration) exceeds `--motion-ceiling`, reconsider item count and delay (#22) | What to look for: clickable gated on completion |
| 57 | Harmonizing list enter/exit is trial and error (STANDARDS) | PORT | `Modifier.animateItem` + `AnimatedVisibility(shrinkVertically+fadeOut)`, mandatory feel-check | Tuning, not calculation |
| 58 | Perceived performance: fast spinners, 180ms, instant tooltips, ease-out feel (emil) | PORT | Applies directly to CircularProgressIndicator speed, menu duration, easing choice | Pure perceptual principle |
| 59 | Follow-up tooltips open instantly (emil) | PORT_ADAPTED | Shared "recently opened" state → next TooltipBox uses `snap()` + zero delay | Pointer context only — rare for touch long-press |
| 60 | Sonner principles: defaults, hidden edge cases, naming (emil) | PORT | Good default AnimationSpec on shared components; stop timers on ON_PAUSE; the component handles edge cases | Library-craftsmanship judgment |
| 61 | React on pointer-down (waiting for touch-up feels dead) (apple §1) | PORT_ADAPTED | Drive press visuals from `collectIsPressedAsState()`/Indication — not onClick; watch for press delay inside scroll containers | Ripple already does this — custom code owes the same |
| 62 | Full latency audit (apple §1) | PORT_ADAPTED | No `withFrameNanos`/`delay()` between input and first visual response; never disable input mid-transition | The 300ms web tap delay does not apply |
| 63 | Continuous 1:1 feedback while dragging (apple §1) | PORT | Offset follows the drag delta every frame; animate only after release | As-is |
| 64 | Preserve grab offset + velocity history (apple §2) | PORT_ADAPTED | Accumulate deltas while dragging (no re-centering); `VelocityTracker`/`onDragStopped(velocity)` | No manual history needed |
| 65 | Never lock input — always interruptible (apple §3) | PORT | What to look for: enabled=false during transitions, ignored input, sheets waiting for the close to finish | Animatable supports mid-flight retargeting |
| 66 | Animate from the displayed value (not the target value) (apple §3) | PORT_ADAPTED | One long-lived Animatable/animate*AsState per property; retarget only by changing targetValue | Violations: recreating the Animatable, remember keyed on target, a preceding snapTo |
| 67 | Avoid CSS transitions/keyframes for gesture motion (apple §3) | WRONG_FOR_COMPOSE | Gestures = `animateTo(target, spring, initialVelocity = releaseVelocity)` | Every API is interruptible; the surviving kernel = tweens throw away release velocity |
| 68 | Blend velocity on reversal (apple §3) | PORT_ADAPTED | Retarget the same Animatable (velocity carries automatically); initialVelocity for the drag→animation handoff | Ports as "don't break the mechanism" |
| 69 | 2D motion uses independent springs per axis (apple §3) | PORT_ADAPTED | `Animatable(Offset.Zero, Offset.VectorConverter)` or two Floats; never animate a scalar distance | The vector converter handles it per axis |
| 70 | Springs first, think in damping ratio and response (apple §4) | PORT_ADAPTED | `spring(dampingRatio = ζ, stiffness = (2π/response)²)`; mass fixed at 1 | Direct mapping |
| 71 | Default ζ=1.0, ~0.8 only after momentum (apple §4) | PORT_ADAPTED | `Spring.DampingRatioNoBouncy` by default; 0.8f only on the onDragStopped path | Ports as house style |
| 72 | Apple shipped values: move 1.0/0.4, rotation 0.8/0.4, drawer 0.8/0.3 (apple §4) | PORT_ADAPTED | move `spring(1f, ~247f)`, rotation `spring(0.8f, ~247f)`, drawer `spring(0.8f, ~400-440f)` | Settle feel differs per engine — feel-check |
| 73 | Velocity handoff (apple §5) | PORT_ADAPTED | `animateTo(target, spring, initialVelocity = tracker.calculateVelocity().y)`; built into AnchoredDraggable | The relative-velocity normalization clause drops out (absolute units) |
| 74 | Momentum projection project(v, 0.998) (apple §6) | PORT_ADAPTED | `splineBasedDecay(density).calculateTargetValue(current, velocity)` → nearest anchor → spring | Don't hand-roll the formula — AnchoredDraggable is the whole pattern |
| 75 | Spatial consistency: symmetric paths, anchored origins, mirrored easing (apple §7) | PORT_ADAPTED | slideIn/Out pairs from the same edge; `scaleIn/Out(transformOrigin=anchor)`; reverse uses the same curve or its inverse bezier | All three port |
| 76 | Gesture direction hints — intermediate frames point at the outcome (apple §8) | PORT | Choose origin and curve so a partial drag previews the committed state | Design judgment |
| 77 | Tap details: highlight on down, commit on up, ~10px hysteresis, cancel on drag (apple §10) | PORT_ADAPTED | Use `clickable`/`detectTapGestures` (slop and cancel built in); never fire the action in `awaitFirstDown` | Becomes a review rule for custom pointerInput |
| 78 | Drag: 1:1 after the movement threshold (apple §10) | PORT_ADAPTED | detectDragGestures/awaitTouchSlopOrCancellation (ViewConfiguration slop); direction-lock variants | Built in — don't defeat it with raw handling |
| 79 | Recognize competing gestures in parallel, cancel the loser (apple §10) | PORT_ADAPTED | `awaitEachGesture` with competing branches + `nestedScroll`; consume only on win | Wrapping gestures in one-shot callbacks is the anti-pattern |
| 80 | Minimize double-tap discrimination delay (apple §10) | PORT_ADAPTED | Use onDoubleTap only where truly needed — its mere presence delays onTap | Same trade-off |
| 81 | Frame-level smoothness (apple §11) | PORT_ADAPTED | `graphicsLayer` = the will-change analogue; `withFrameNanos` for a custom clock; approximate stretch on fast moves | No built-in motion blur |
| 82 | Translucent chrome backdrop-filter (apple §12) | DROP | Express layering with tonal elevation, scrims, shadows | No first-class backdrop blur (third-party like Haze) |
| 83 | Scrim dim, edge gradients, materialize entrances (apple §12) | PORT_ADAPTED | ModalBottomSheet/Dialog scrim; `Brush.verticalGradient` fades; entrance = scaleIn(0.95f)+fadeIn (+31+ blur) | Only the portable parts |
| 84 | Vibrancy text over translucency (apple §12) | DROP | None | Presupposes backdrop translucency — drops with it |
| 85 | Multi-modal feedback: causal, synchronized, useful (apple §13) | PORT_ADAPTED | `LocalHapticFeedback.current.performHapticFeedback(HapticFeedbackType.*)` — same frame as the visual; only at success/error-grade moments | Over-feedback trains users to ignore it |
| 86 | Three reduced-motion signals (apple §14) | PORT_ADAPTED | Signal 1 = animator scale (auto-snap at 0; read settings for a gentler branch); signals 2 and 3 have no direct setting | Partial port |
| 87 | Avoid nausea: full-viewport moving backgrounds, 0.2Hz loops, abrupt brightness changes (apple §14) | PORT | Flag infinite periods ~5000ms on large elements; ease theme transitions; dip alpha on large moves | Pure perceptual rule |
| 88 | Typography: per-size tracking, leading, Dynamic Type (apple §15) | PORT_ADAPTED | Reflected in the project's typography token file (display letterSpacing (-0.02).em, .sp units) | The project keeps typography in a single token file — not motion, reference only |
| 89 | 8 principles + 4 needs (Purpose, Agency, Craft, Delight…) (apple §16) | PORT | Judgment as-is; Delight = capped at rare moments | Matches the project's no-redundant-UX rule |
| 90 | Tactical rules: 4 kinds of feedback, wayfinding, grouping (apple §16) | PORT | Applies to Compose screens as-is | Pure UX judgment |
| 91 | Process: interactive prototypes, real users, slow motion (apple §17) | PORT_ADAPTED | @Preview + emulator/real device; animator_duration_scale 10 | Matches emulator-verification practice |
| 92 | Gate Q1 frequency (find-anim Gate 1) | PORT | 100+/day and keyboard = disqualified; tens = near-imperceptible only; rare = delight budget | Verdict vocabulary as-is |
| 93 | Gate Q2 closed list of purposes (Gate 2) | PORT | feedback / spatial consistency / status / preventing abrupt change / explanation (onboarding) / delight (rare) — no "because it looks cool" | Closed vocabulary as-is |
| 94 | Gate Q3 speed budget (Gate 3) | PORT_ADAPTED | The proposed spec must fit within `tween(<=300)` or an equivalent spring budget | Applied as an eligibility gate |
| 95 | Gate Q4 interference with function (Gate 4) | PORT | No decorative motion on read-and-operate surfaces (dense data tables, logs, schedules) | Directly applicable |
| 96 | Hard rules: read-only, 5-7 item cap, mandatory rejected section, "finding nothing is valid" (find-anim) | PORT | Compose values in the proposal cells (spec, easing, dampingRatio) | Pure process |
| 97 | Hunt: teleporting state swaps (find-anim) | PORT_ADAPTED | `AnimatedVisibility(fadeIn+scaleIn(0.95f))`; `AnimatedContent`/`Crossfade`; MutableTransitionState | Maps to content-swap primitives |
| 98 | Hunt: accordions that snap open (find-anim) | PORT_ADAPTED | `animateContentSize(spring(stiffness = StiffnessMediumLow))` or expandVertically+fadeIn | The web's height taboo dissolves here — size animation is idiomatic in Compose |
| 99 | Hunt: list add/remove with no bridge (find-anim) | PORT_ADAPTED | `items(key=...)` + `Modifier.animateItem()`; default spring | Retargeting requirement met automatically |
| 100 | Hunt: no spatial story, asymmetric exit (find-anim) | PORT_ADAPTED | `scaleIn(transformOrigin=anchor)+fadeIn` on Popup; slide pairs from the same edge; `{ it }` (no hardcoded px) | The opportunity framing of the origin and spatial-consistency rules |
| 101 | Hunt: delight budget — rare high-emotion moments only (find-anim) | PORT | The only place `DampingRatioMediumBouncy`, >300ms, and generous stagger are allowed = success-hero moments | Judgment as-is |

## Appendix A — Numeric conversion table

| Concept | Web value | Compose value |
|---|---|---|
| Spring bounce → damping ratio | bounce | dampingRatio ≈ 1 − bounce |
| Spring response → stiffness | response (seconds) | stiffness = (2π/response)² (mass fixed at 1) |
| Physics triplet → damping ratio | {mass, stiffness, damping} | ζ = damping / (2·√(stiffness·mass)) — exact conversion. e.g. {1,100,10} → spring(0.5f, 100f) |
| duration+bounce spring | {duration:0.5, bounce:0.2} | ≈ spring(0.8f, ~160f) — perceptual unit, so approximate; on-device feel-check required |
| Flick threshold | 0.11 px/ms | 125.dp/s (`--motion-flick-velocity`, aligned with the project motion token; web equivalent ≈110dp/s) |
| Momentum projection | project(v,0.998) | `splineBasedDecay(density).calculateTargetValue(...)`; snappier = `exponentialDecay(frictionMultiplier > 1f)` |
| Rubber band | (o·d·0.55)/(d+0.55·\|o\|) | Same formula; `Modifier.overscroll` for scrollables |
| Tap hysteresis | ~10px | System touch slop (~8dp, ViewConfiguration) — never hardcode |
| Nausea band | ~0.2 Hz | Avoid infinite periods ~5000ms on large elements |
| Slow-motion debugging | 2-5x | `adb shell settings put global animator_duration_scale 10` |

## Appendix B — Full numeric mappings (numeric_mappings, 34 entries)

Complete transcription of the porting inspection's numeric mappings. Appendix A is the normative summary of the 10 core conversion formulas among these — on conflict, Appendix A and the project motion spec tokens take precedence.

| Concept | Web value | Compose value |
|---|---|---|
| Entrance/exit easing (ease-out) | ease-out | LinearOutSlowInEasing (decelerate); FastOutSlowInEasing as general Material standard |
| Forbidden UI easing (ease-in) | ease-in | FastOutLinearInEasing / EaseIn — never on entrances or interactive response; exits toward off-screen only |
| On-screen move/morph easing | ease-in-out | FastOutSlowInEasing or CubicBezierEasing(0.77f,0f,0.175f,1f) for a stronger curve |
| Hover/color-change easing | ease | tween(easing = FastOutSlowInEasing) or animateColorAsState default spring |
| Constant-motion easing | linear | LinearEasing only for constant motion in a fixed direction (marquee, progress indicators); a RepeatMode.Reverse ambient loop becomes a triangle wave, so use a sine-like CubicBezierEasing(0.37f, 0f, 0.63f, 1f) (M-AP-B, see `--ease-linear`) |
| Strong ease-out token | cubic-bezier(0.23, 1, 0.32, 1) | CubicBezierEasing(0.23f, 1f, 0.32f, 1f) (Compose's EaseOutQuint 0.22,1,0.36,1 is a near match) |
| Strong ease-in-out token | cubic-bezier(0.77, 0, 0.175, 1) | CubicBezierEasing(0.77f, 0f, 0.175f, 1f) |
| iOS drawer curve | cubic-bezier(0.32, 0.72, 0, 1) | CubicBezierEasing(0.32f, 0.72f, 0f, 1f) for sheet/drawer tweens |
| Button press feedback duration | 100-160ms | tween(durationMillis = 100..160); canonical tween(140, easing = LinearOutSlowInEasing) — `--motion-press-out` (aligned with the project motion token) |
| Press scale | scale(0.97), range 0.95-0.98 | graphicsLayer scaleX/scaleY = 0.95f (0.95f..0.98f) — `--motion-press-scale` (aligned with the project motion token) |
| Tooltip/small popover duration | 125-200ms | tween(125..200) |
| Dropdown/select duration | 150-250ms | tween(150..250) |
| Modal/drawer duration | 200-500ms | tween(200..500) or spring settling in that window |
| UI duration ceiling | 300ms | tween(durationMillis <= 300) for all interactive UI |
| Entrance scale floor | scale(0.9-0.97), never scale(0) | scaleIn(initialScale = 0.9f..0.97f); NEVER bare scaleIn() — its default initialScale is 0f |
| Motion/Framer Apple-style spring | { type:'spring', duration:0.5, bounce:0.2 } | spring(dampingRatio = 1 - bounce = 0.8f, stiffness ≈ (2π/0.5)² ≈ 160f — between StiffnessLow 200/StiffnessVeryLow 50); perceptual-duration conversion is inexact → feel-check required |
| Physics-triplet spring | { mass:1, stiffness:100, damping:10 } | exact: ζ = 10/(2·√(100·1)) = 0.5 → spring(Spring.DampingRatioMediumBouncy /*0.5f*/, stiffness = 100f); MediumBouncy is delight-tier (rare) only (see the Subtle-bounce band row) |
| Subtle bounce band | bounce 0.1-0.3; avoid in most UI | dampingRatio 0.9f-0.7f (NoBouncy 1f = default; LowBouncy 0.75f = upper playful bound; MediumBouncy 0.5f = delight-tier only) |
| Apple critically damped default | damping 1.0 | Spring.DampingRatioNoBouncy (1f) |
| Apple momentum bounce | damping ~0.8 | dampingRatio = 0.8f (≈ Spring.DampingRatioLowBouncy 0.75f) |
| Apple response 0.4s | response 0.4 | stiffness = (2π/0.4)² ≈ 247f (between StiffnessLow 200 and StiffnessMediumLow 400) |
| Apple response 0.3s (drawer/sheet) | response 0.3 | stiffness ≈ 439f ≈ Spring.StiffnessMediumLow (400f); drawer = spring(0.8f, 400f) |
| Apple shipped spring set | move 1.0/0.4 · rotation 0.8/0.4 · drawer 0.8/0.3 | move spring(1f, ~247f) · rotation spring(0.8f, ~247f) · drawer spring(0.8f, ~400-440f); settle-time differs slightly across engines — feel-check |
| Flick dismissal velocity threshold | \|distance\|/elapsedMs > ~0.11 (px/ms) | 125.dp/s from VelocityTracker/onDragStopped — the `--motion-flick-velocity` token value (classic SwipeableDefaults.VelocityThreshold) (aligned with the project motion token) |
| Momentum projection decay | project(v) = (v/1000)·0.998/(1−0.998); 0.99 snappier | splineBasedDecay(density).calculateTargetValue(current, velocity) for platform scroll feel; exponentialDecay(frictionMultiplier > 1f) for snappier — don't hand-roll |
| Rubber-band resistance | (overshoot·dim·0.55)/(dim + 0.55·\|overshoot\|) | same pure-math formula applied to over-drag deltas; Modifier.overscroll for scrollables |
| Stagger interval | 30-80ms between items (e.g. 50ms steps) | tween(delayMillis = index * 30..80); typical index * 50 |
| Crossfade-masking blur | blur(2px), keep < 20px | Modifier.blur(2.dp), cap well under 20.dp; RenderEffect API 31+ (no-op below) |
| Hold-to-confirm timing | press 2s linear; release 200ms ease-out | animateTo(1f, tween(2000, LinearEasing)); animateTo(0f, tween(200, LinearOutSlowInEasing)) |
| Tap/drag hysteresis | ~10px | system touch slop (ViewConfiguration, ~8dp) via detectDragGestures/awaitTouchSlopOrCancellation — don't hardcode |
| Reduced-motion fallback | @media (prefers-reduced-motion) { fade 0.2s ease } | none — respect the OS snap (R21): Compose auto-snaps at scale 0 via MotionDurationScale; playing a substitute animation violates the user setting. Guarantee state legibility with non-motion signals (color, elevation, text) |
| Nausea-inducing loop frequency | avoid ~0.2 Hz (1 cycle / 5s) | avoid rememberInfiniteTransition periods near 5000ms on large elements |
| Large display text tracking | letter-spacing: -0.02em on display sizes | TextStyle(letterSpacing = (-0.02).em) in the project's display typography tokens; body ≈ 0 |
| Slow-motion debugging factor | 2-5x duration / DevTools slowed playback | adb shell settings put global animator_duration_scale 10 (Developer options 5x/10x) |
