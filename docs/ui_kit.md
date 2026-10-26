# UI-kitet (Persona 4-stil)

Allt spel-UI utanför telefonen bygger på kitet i `scripts/ui/`. Telefonen behåller sin egen stil (`PhoneTheme`), eftersom den är en sak i världen.

## Grunder: `UiKit` (`ui_kit.gd`)
- **Färger:** `INK` (svart), `INK_2` (ytor), `YELLOW`, `PAPER` (ljus text och plattor), `RED` (hårda skuggor och varningar), `MUTED` och `METERS` (Home, Work och Romance).
- **Typsnitt:** `display_font()` är fett, smalt och lutande (Bahnschrift med lutning och fetma). `body_font(bold)` är brödtexten. Egna filer i `Assets/fonts/ui_display.ttf`, `ui_body.ttf` och `ui_body_bold.ttf` ersätter dem utan kodändring.
- **Storlekar:** `HERO 88`, `DISPLAY 60`, `TITLE 40`, `MENU 30`, `HEADING 24`, `BODY 18`, `SMALL 15` och `TINY 12`.
- **Form:** allt lutar med `SLANT` (0.25) och har en hård skugga (`SHADOW`).
  - Ritfunktioner: `draw_slant`, `draw_meter`, `draw_pips` och `draw_display`.
  - Byggstenar: `plate()`, `card()`, `label()`, `display()`, `header()`, `key_hints()`, `confirm()` och `settings_list()`.
- **Rörelse:** tiderna är `FAST`, `MID`, `SLOW` och `STAGGER`.
  - `t()` och `travel()` följer inställningen Motion (Full eller Reduced).
  - `enter()` låter något glida in.
- **Inställningar:** Fullscreen och Motion sparas i `user://settings.cfg`.

## Komponenter
- **`KitButton`** finns i tre varianter:
  - `"menu"` är ett stort listval: när det väljs sveper ett gult fält in, texten blir svart och knuffas åt höger och en röd skugga syns.
  - `"tab"` används för flikar och växlar och är gul när den är vald.
  - `"action"` är den gula huvudknappen.
  - `title` är knappens text och `note` en liten text till höger. `appear()` låter knappen glida in och `punch()` ger den en stöt. Musen flyttar fokus, så att tangenter och mus beter sig lika.
- **`KitBackdrop`** är svart (eller genomskinligt svart över spelet) med glidande ränder och ett gult snedband som `sweep_in()` sveper in.
- **`UiTransition`** har två övergångar:
  - `wipe()`: gula och svarta band sveper över skärmen med en rubrik (används för New Game och för att gå tillbaka till titelskärmen).
  - `banner()`: tidszonens skylt.
  - Båda fortsätter även när spelet är pausat.

## Var kitet används
- `scenes/main_menu.tscn` (`main_menu.gd`) är titelskärmen och spelets startscen.
- `scripts/ui/pause_menu.gd` öppnas med Esc eller MENU. Den har:
  - en översikt
  - Status
  - Items (Items, Purchases och Wardrobe)
  - Memories
  - Settings
  - Title Screen och Quit, som frågar först
- `hud.gd` innehåller dagsplattorna, mätarna, textrutan och dagens slut.
- `house.gd` innehåller rummets meny, våningsknapparna och tidszonens skylt.
- `tools/ui_preview.tscn` sparar skärmbilder av allt detta för granskning.
