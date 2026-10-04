# Accessibility Test Checklist

Manual pass, required before every release. Test with the screen reader **on** and, for at least
one full pass, with the device **screen off** (a blind user's actual condition) to catch anything
that silently depends on sight.

## Screen reader (TalkBack / VoiceOver)

- [ ] Every interactive control has a non-generic accessibility label (no bare "Button" /
      unlabeled icon buttons) — spot-check Home, Scanner, Product Result, Assistant, Settings.
- [ ] Focus order on each screen is logical top-to-bottom, matching visual reading order.
- [ ] The mic button's label changes between idle and listening states
      (`BigMicButton`/`BigMicButtonSmall` — verify the Semantics label actually updates, not just
      the icon).
- [ ] Live-updating content (scanner guidance panel, offline banner) is marked as a live region
      so the screen reader announces changes without the user needing to re-focus it.
- [ ] Dialogs (add allergy, add restriction) trap focus and are dismissible without a sighted
      gesture.
- [ ] No screen requires a double-tap-and-hold, multi-finger, or precise-drag gesture as the
      *only* way to complete an action — camera capture always has a large single-tap target in
      addition to the (optional) voice command.

## Touch targets & visual

- [ ] Every actionable control measures at least 48x48dp (this app's theme baseline is 56dp —
      `AppTheme.minTouchTarget`); spot check with the Android "Accessibility Scanner" or iOS
      Accessibility Inspector.
- [ ] Text and icon color pairs meet WCAG AA contrast (4.5:1 for body text) in both light and
      dark mode — re-check after any `AppTheme` color change.
- [ ] The app remains usable (no clipped/overlapping text) at the largest system font-scale
      setting, and at the largest system display-scale setting.
- [ ] Critical/warning safety flags are distinguishable by more than color alone (icon + text
      label + haptic — verify `SafetyFlagCard`).

## Account setup (do this on a freshly installed app, screen off)

The app must never ask a blind user to type. Sign-up and sign-in are one spoken word; the
device's account is generated, registered and stored for them (`core/auth/device_account.dart`).

- [ ] A fresh install speaks the welcome and explains that no email or password is needed,
      then opens the microphone on its own.
- [ ] Saying "start" (or "தொடங்கு") completes account creation and lands on Home, spoken
      confirmation included — with no keyboard shown at any point.
- [ ] Killing and relaunching the app goes straight to Home. The welcome screen must not
      reappear, and nothing must be typed again.
- [ ] "Log out" then relaunch returns to the welcome screen, and "sign in" restores the *same*
      account — the previous scan history is still there.
- [ ] With the microphone permission refused, the failure is spoken and felt (not just shown),
      and the single full-width "Set up by voice" button still completes setup on one tap.
- [ ] Airplane mode during setup: the failure is spoken, and "try again" retries once
      connectivity is back.

## Voice-first flow (core requirement — do this with the screen off)

- [ ] App launch speaks the welcome message in the user's detected/preferred language without
      requiring any tap.
- [ ] The global vocabulary works on *every* screen, not just Home: "go back", "go home",
      "help", "where am I", "repeat that", "stop talking" (`GlobalVoiceCommands`). Check each
      one from the Assistant and from Settings, which have their own vocabularies.
- [ ] Global commands do not hijack ordinary questions — ask the Assistant "is this good for my
      back?" and confirm it answers instead of navigating away.
- [ ] Returning to a screen re-arms its microphone: scan a product, go back to Home, and speak
      without touching anything.
- [ ] Double-tapping anywhere reopens the microphone, and press-and-hold repeats the last
      utterance. (With TalkBack/VoiceOver running these gestures belong to the screen reader —
      confirm the app is still fully operable without them.)
- [ ] "Help" lists the commands for the screen the user is actually on, not a generic list.
- [ ] "Check this product" / "இந்த பொருளை check பண்ணு" from Home reaches the camera scanner by
      voice alone.
- [ ] Scanner guidance ("move closer", "hold steady", "too dark") is spoken, not just shown as
      on-screen text.
- [ ] The scanner announces when the label is correctly framed and then takes the picture
      itself — a blind user cannot judge framing, so "say capture when it looks right" is not a
      usable instruction. Saying "wait" turns auto-capture off; "automatic" turns it back on.
- [ ] Auto-capture does not fire repeatedly: after a failed scan there is a pause long enough to
      speak a command.
- [ ] A completed scan's result (product name + any critical safety flags) is spoken
      automatically — the user should never have to find and tap a "read result" button.
- [ ] The AI Assistant can be driven entirely by voice: ask a question by speaking, hear the
      answer spoken back, without touching the keyboard.
- [ ] Every screen's primary action is reachable via voice command or a single large tap — no
      screen requires hunting for a small icon as the *only* path to its main function.

## Language switching

- [ ] Speaking a Tamil-script or Tanglish question to the Assistant produces a Tamil spoken
      answer; an English question produces an English spoken answer — without changing any
      setting.
- [ ] Manually switching Settings → Language to Tamil changes both the visual UI language and
      the default TTS/STT language.
- [ ] If the device has no installed Tamil TTS voice, the app falls back to the cloud voice
      (when enabled) instead of silently failing — verify by toggling
      "Use higher-quality cloud voice" off and confirming the app instead says nothing worse
      than a graceful skip (no crash, no English substituted silently for a Tamil request).

## Haptics

- [ ] A critical safety flag (declared allergen match) produces a distinctly different vibration
      pattern than a routine button tap — verify on a device with amplitude-control vibration
      *and* on one without (the `HapticService` fallback path).
- [ ] Haptics can be disabled in Settings and no vibration occurs anywhere once disabled.

## Permissions

- [ ] Denying camera permission shows a spoken + visual explanation, not a silent black screen.
- [ ] Denying microphone permission shows a spoken + visual explanation and the app remains
      usable via touch alone.
- [ ] Re-granting a previously denied permission from system Settings and returning to the app
      recovers the feature without requiring an app restart.

## Content correctness (safety, not just accessibility — verify together)

- [ ] Every spoken/written fact about a scanned product states its provenance
      ("label explicitly says" / "detected from the label" / "AI interpretation" / "could not be
      verified") — see `docs/SAFETY_RULES.md`.
- [ ] No screen or AI Assistant response ever says a product is "safe to eat" or classifies it as
      simply "good"/"bad".
