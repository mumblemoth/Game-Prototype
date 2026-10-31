# Phone UI – layout spec

The phone is the game's menu. It is drawn in code. Every visual value lives in one of three places, so it can be reskinned once the final art style is set:

| What | Where |
|---|---|
| Colors, type scale, fonts, radii, sizes | `scripts/ui/phone_theme.gd` (`PhoneTheme`) |
| Icon set | `scripts/ui/phone_icons.gd` (`PhoneIcons`) |
| Wallpaper presets and slots | `scripts/phone_data.gd` (`PhoneData.WALLPAPER_*`) |
| Pages and layout | `scripts/phone.gd` |
| Rounded image corners | `shaders/rounded_mask.gdshader` (via `PhoneTheme.round_corners`) |

To check the look without playing, run `tools/phone_preview.tscn`. It saves a PNG of every page:

```bash
Gadot/Godot_v4.7.2-stable_win64.exe --path . res://tools/phone_preview.tscn -- C:/temp/phone
```

## Art swap points (no code changes needed)

| Drop a file here | It replaces |
|---|---|
| `Assets/fonts/phone_ui_regular.ttf`, `_semibold.ttf`, `_bold.ttf` | System font (Nunito → Quicksand → Segoe UI → Arial) |
| `Assets/ui/phone/icons/<icon id>.png` | The code-drawn icon or app tile with that id (square, 1:1, ideally 168 px for 3×) |
| `Assets/ui/phone/wallpapers/<preset id>.png` | The gradient of that preset (portrait, about 600×1240) |

## Tokens

**Colors**: warm minimalism, matching the house interiors (cream, warm brown, sage and teal as complements to Mom's red hair).

| Token | Hex | Use |
|---|---|---|
| `INK` | `#2B2420` | Text, dark cards, call screen background |
| `PAPER` | `#FBF7F1` | App page background, sheets |
| `CARD` | `#FFFFFF` | Grouped list cards |
| `MUTED` | `#8A7F76` | Secondary text, chevrons, locked glyphs |
| `LINE` | `#E8E0D6` | Hairlines, card borders, empty bars |
| `ACCENT` | `#2F8F8A` | Links, back button, my bubbles, selection, primary buttons |
| `THEM_BUBBLE` | `#EFE8DF` | Their bubbles, image placeholders |
| `DANGER` | `#D0533F` | End call, Quit, low battery |
| `BADGE` | `#E0503C` | Unread badges |
| `BEZEL` / `BEZEL_EDGE` | `#1D1916` / `#6D635B` | Phone body and rim, side buttons |

**Type scale** (one family, weights 400 / 600 / 700):

| Token | px | Use |
|---|---|---|
| `CAPTION` | 11 | Icon labels, notification app name, widget weekday |
| `FOOTNOTE` | 12 | Section headers (600, caps), badges, hints |
| `SUBHEAD` | 13 | Row subtitles, quest text, tabs, toasts |
| `BODY` | 14 | Body text, bubbles, status bar (600) |
| `CALLOUT` | 15 | Row titles (600), back button, buttons |
| `HEADLINE` | 17 | Small titles |
| `TITLE` | 28 | Large page titles (700), widget period |
| `CLOCK` | 54 | Lock screen period (drawn at 46, 700) |

**Radii**: body 46, screen 36 (concentric: 46 − 10 px bezel), dock 30, sheet 28, buttons 22 (pill), bubbles 18, notifications 18, app tile 15 (at 56 px), cards 14, memory tiles 10, segmented control 10/8.

## Device frame

```
Body 320 × 640, radius 46, 2 px rim, soft drop shadow (18 px, y+6)
├─ Side buttons: left 112/24, 152/44, 204/44; right 168/70 (y / height, 3 px proud)
└─ Screen 300 × 620 at (10, 10), radius 36. Everything on it is clipped to the rounded corners.
   ├─ Status bar 0–44
   ├─ Page area 44–598 (scrolls on app pages)
   └─ Home indicator 120 × 5 centered at y ≈ 609 (click area 150 × 22). Goes home, or unlocks.
```

Opens at screen position (930, 40) with a 0.3 s back-ease slide. Closes downward. Page changes fade in over 0.14 s.

**Status bar** (white on wallpaper and call pages, `INK` elsewhere):
- Left: period name ("Afternoon"), BODY 600, baseline (26, 29). This stands in for the clock.
- Center: dynamic island 96 × 28 at y 10, with a camera dot.
- Right: signal 16 px at x 210, wifi 17 px at x 230, battery 24 px at x 251.
- The battery drains through the day: morning 100 %, afternoon 72 %, evening 41 %, night 18 %. Below 25 % the fill turns red.

## Screens

### Lock screen (wallpaper slot `lock`)
Shown the **first time the phone opens in each new period**; after that it opens straight to home.
- Lock glyph 18 px centered at y 50.
- "Monday, Day 3" CALLOUT 600 at baseline 96. The period name at 46 px, 700, baseline 154. Both have a 1 px shadow.
- Notification cards from y 196: 276 × 72, 8 px apart, at most 3. Each card is 80 % white with radius 18 and shows: a 20 px app tile, the app name in caps, "now", a title in 600 and one ellipsized line of text. One card per unread thread plus one for new memories. **Clicking a card unlocks straight into that thread, or into Memories.**
- "Click to unlock" FOOTNOTE at y ≈ 568.
- Click anywhere to unlock (it slides up 60 px and fades over 0.2 s). With no notifications it **auto-unlocks after 1.4 s**.

### Home screen (wallpaper slot `home`)
- Top scrim 15 % of height and bottom scrim 28 % (black 0 → 30 %) keep text readable on photos.
- Date widget at (20, 58), 260 × 96, radius 22, dark frost (12 % brown at 30 %). Left side: weekday caps, period TITLE 700, "Day N". Right side: journal glyph, active quest count, "active quests".
- App grid: 4 columns × 65 px from x 20, first row at y 172, row pitch 90. Tile 56 with a CAPTION 600 label 3 px below and a text shadow. Apps: **Journal, Profile, Wallet, Settings**.
- Dock at (12, 514), 276 × 84, radius 30, light frost (white 26 %, rim 32 %). Holds **Phone, Messages, Memories** with no labels, evenly spaced.
- Badges are 20 px pills at the tile's top right (+43, −7): unread threads on Messages, unseen memories on Memories.

### App pages (common frame)
- Back row: a chevron plus the destination's title in ACCENT CALLOUT, 32 px tall, 8 px from the left.
- Large title: TITLE 700, 16 px side margin.
- Content: 16 px side margin, 10 px vertical rhythm, thin 4 px scrollbar.
- Grouped list: a white card (radius 14, 1 px `LINE` border) with hairlines between rows. Hairlines are inset 62 for avatar rows, 56 for settings rows and 16 otherwise. Hover and press tint rows with 4 % / 8 % ink, and the first and last rows follow the card's corners.
- Section header: FOOTNOTE 600 caps, `MUTED`, inset 32.
- Segmented control: 7 % ink track. The selected segment is white with `INK` text; the others are transparent with `MUTED` text. Height 30.
- Primary button: 46 tall pill in `ACCENT` with a glyph before the text. Secondary: white with a 50 % `ACCENT` rim.
- Action sheet: dims the screen and floats a sheet 8 px from the edges at the bottom (radius 28). It has a title, option buttons (44 tall) and Cancel.
- Toast: `INK` 88 % pill, 84 px above the bottom, shown for 1.2 s.

| Page | Contents |
|---|---|
| Contacts (Phone) | Avatar rows (38 px circle with initials): name plus "♥ Rank N · N% to next" or "mobile" |
| Call | Dark `INK` screen, 104 px avatar, name TITLE, "calling…", transcript card (white 8 %), 64 px red end-call button with the `end_call` glyph |
| Messages | Avatar rows with a preview of the last message ("You: …" for her own), a teal unread dot and a chevron |
| Thread | Back to Messages, a centered 44 px avatar with the name, then bubbles (max text width 210; hers teal on the right, theirs `THEM_BUBBLE` on the left). Below that, the **Reply** section with outlined choices. Auto-scrolls to the end |
| Memories | "N of M collected", All/Scenes/Pictures tabs, 3-column grid of 86 × 112 tiles. Scenes without art get a period-colored card with a play button. Unseen memories get a teal dot. Locked tiles show a lock glyph |
| Memory | 300 px rounded preview, info card (Type, From, When, Where), **Relive** or **View Full Screen**, and **Set as Wallpaper** (sheet: Lock Screen / Home Screen / Both) |
| Profile | Dark Attractiveness card with a 1–5 meter, a **Skills** card (bar and XP per stat) and a **What Attractiveness unlocks** card (teal check or empty ring) |
| Wallet | Dark **Balance** card (red amount when negative, next salary below). **Coming up** card: payday, monthly bills (incl. subscriptions), weekly allowance, groceries status (red when takeout is near), each subscription. **Ways to earn · N of M found**: found ones show what they've earned; undiscovered ones show "???" with a vague hint. **Recent activity**: last 12 ledger entries, newest first, income in sage |
| Calendar | Month N with back/forward arrows (from month 1 to two months ahead). A 7 × 4 grid card (a month is four Monday-to-Sunday weeks): today is a filled teal circle, the selected day a teal ring, past days muted, and days with events get one dot per event kind (story terracotta, money slate blue, people teal, places ochre). Tapping a day shows its events under "Today · Weekday · Day N"; then **Coming up**: the next 8 events within 7 days with "Today"/"Tomorrow"/"Tue · Day 9" and the period ("All day" for money). Events come from `Calendar` (StoryScenes, Economy, Schedules, Locations); surprise bills and chance-based schedule rules are never shown |
| Journal | Active/Completed tabs. Quest cards have a 4 px left bar (ochre for active, sage plus a check for completed). Empty state shows the journal glyph and "Nothing here yet." |
| Settings | Card with **Wallpaper** (current home wallpaper's name) and **Close Phone**, a separate card with **Quit Game** in red, then "Saving comes later." |
| Wallpaper | Two mini-phones (104 × 215) for Lock and Home side by side; the selected slot has a teal rim. Then "Choose for …" with a 3-column grid of 86 × 132 tiles: presets first, then every memory picture. Pictures not collected yet are locked. The chosen one has a teal rim and a check |

## Icon set

All icons sit on a **24 × 24 grid**. Strokes are **2 units** wide with round caps and joins; small solid shapes are used only where a stroke would read worse at status-bar size. The color is set per call. App tiles are 56 px rounded squares in the app color with a soft top-to-bottom gradient (+16 % → −6 %) and a 35 % white top highlight. The glyph is white at 56 % of the tile.

| id | Glyph | Used for |
|---|---|---|
| `phone` | Handset outline | Phone app tile |
| `messages` | Speech bubble with tail | Messages app tile, notifications |
| `memories` | Photo with a second photo behind | Memories app tile, notifications |
| `calendar` | Page with two rings, a header line and a dot | Calendar app tile |
| `journal` | Book with spine and two lines | Journal app tile, home widget, empty journal |
| `profile` | Head and shoulders | Profile app tile |
| `wallet` | Wallet with a bill peeking out and a clasp | Wallet app tile |
| `settings` | 8-tooth gear | Settings app tile |
| `image` | Photo (mountain and sun) | Wallpaper row, "View Full Screen" |
| `signal` | 4 rising bars (solid) | Status bar |
| `wifi` | 2 arcs and a dot | Status bar |
| `battery` | Battery outline with fill level (red below 25 %) | Status bar |
| `back` | Left chevron | Back button |
| `chevron` | Right chevron | List row disclosure |
| `play` | Triangle (solid) | Relive button, scene thumbnails |
| `lock` | Padlock | Lock screen, locked tiles, "Close Phone" |
| `heart` | Heart outline | Spare, for relationships |
| `check` | Check mark | Selected wallpaper, completed quest, unlocked perk |
| `end_call` | Handset turned 135° | End call button |
| `map` | Map folded in three panels | Map button on the HUD (bottom right, under the Phone button) |

App tile colors: phone sage `#6FA67A`, messages teal `#3E9C95`, memories terracotta `#E07A5F`, calendar brick `#C8554B`, journal ochre `#D4A04C`, profile rose `#C9677F`, wallet slate blue `#4F7CAC`, settings warm gray `#8C8379`.

## Wallpaper slots

| Slot | Shown on | Default |
|---|---|---|
| `lock` | Lock screen | `memory:mom_casual` ("Sunday Morning") |
| `home` | Home screen | `preset:dusk` |

- A value is a plain string: `preset:<id>` or `memory:<memory id>`. It is stored in `GameState.phone_wallpapers` and changed with `GameState.set_wallpaper(slot, value)`, which emits `phone_changed`.
- Presets are vertical gradients with two soft light circles: **Dusk** (peach → lavender), **Sage** (pale sage → sage), **Terracotta** (apricot → terracotta) and **Night** (dusk blue → near-black).
- Any memory with an `image` (or `thumb`) can be a wallpaper once it is collected. Images are cover-cropped. The optional `wallpaper_focus` (0–1, default 0.5) in `PhoneData.MEMORIES` sets which height of the image stays visible; `mom_casual` uses 0.3 to keep her face in frame.
- If a slot points to something that can't be shown, it falls back to the first preset.
