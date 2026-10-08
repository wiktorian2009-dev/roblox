# Image prompts: snowy GUI art (to replace the Blender-rendered pieces)

Hand these to any image AI (Midjourney, DALL·E, Ideogram, Leonardo, …). Then upload each PNG as a Decal, resolve its image id, and paste it into `ReplicatedStorage.SnowArt` (`A.Images`). Keep the file sizes and 9-slice centres below, so nothing else has to change.

**Shared style line** (append to every prompt):
> chunky cartoon mobile-game UI asset, Roblox simulator style, soft snow piled on the top edge, thick dark-navy outline (#142855), glossy highlight on the upper half, slightly darker bottom lip, flat bright colours, clean vector look, centred, transparent background, no text, no shadow outside the shape

## Buttons: 512 × 192 PNG, 9-slice centre Rect(70, 70, 442, 150)
Each is a wide rounded pill button. Keep the left/right 70 px and the top 70 / bottom 42 px free of detail that must not stretch.

| File | Colour (top → bottom) | Prompt |
|---|---|---|
| btn_green | #5CD27E → #2E9E52 | "wide rounded pill game button, mint-to-forest green gradient, snow cap on top" + style |
| btn_blue | #5FA8F5 → #2F6FD0 | "wide rounded pill game button, sky-to-royal blue gradient, snow cap on top" + style |
| btn_orange | #FFB04A → #E57A1E | "… warm orange gradient …" |
| btn_red | #FF6B78 → #D63A4A | "… cherry red gradient …" |
| btn_grey | #B6C2D6 → #7E8BA3 | "… cool grey (disabled) gradient …" |
| btn_gold | #FFD95A → #E0A920 | "… golden yellow gradient …" |
| btn_purple | #B98CFF → #7B52E0 | "… lavender-to-violet gradient …" |

## Tabs: 384 × 160 PNG, 9-slice centre Rect(60, 50, 324, 120), no snow cap
- tab_on: "rounded tab button, bright ice blue #8FD0FF → #3F86E0, selected look" + style (without snow).
- tab_off: "rounded tab button, muted grey-blue #C9D6E8 → #8F9DB5, unselected look" + style (without snow).

## Windows: 1024 × 1024 PNG, 9-slice centre Rect(160, 200, 864, 864)
- **panel_dark** (offer card, workbench, inspect panel): "square game window frame, light-blue outer rim #8FC6F2, deep blue inner area #4C8FE0 → #1F3F82, thick navy outline, a long fluffy snow drift along the whole top edge with a few small icicles hanging at the corners, the inner area plain and empty for content" + style.
- **panel** (light variant): the same, with the inner area #EAF6FF → #BFE0FA.

## Close button: 256 × 256 PNG (drawn with Fit, not sliced)
- close: "round red game close button with a bold white X, small snow cap on top" + style.

## Icons: 256 × 256 PNG (Fit), chunky with a navy outline
| File | Prompt |
|---|---|
| icon_coin | "gold coin with a white snowflake embossed" |
| icon_star | "chunky golden five-point star" |
| icon_reroll | "two green curved arrows forming a circle (refresh / reroll)" |
| icon_wrench | "steel wrench, diagonal" |
| icon_garage | "small garage building with a blue roof and white roller door" |
| icon_house | "cosy cabin with red roof, snow on the roof, brown door" |
| icon_pin | "red map pin with a white hole" |
| icon_brush | "paint brush with a pink paint tip" |
| icon_leave | "brown door with a green arrow pointing out" |
| icon_flame | "orange-yellow flame (boost)" |
| icon_shield | "blue shield with a white stripe (brace)" |
| icon_help | "round yellow badge with a navy question mark" |
| icon_wheel | "grey car wheel with a red hub" |

Append the shared style line to each.

## Tutorial pieces (2026-10-06)
- **tut_arrow** (256 × 256, Fit, points DOWN): "chunky golden arrow pointing straight down, rounded shaft, wide triangle head, thick navy outline, glossy streak on the shaft, a little snow on the top end" + style.
- **tut_spot** (256 × 256, 9-slice centre Rect(96, 96, 160, 160)): not art. It is a black square with a transparent rounded hole, feathered over about 30 px (spot_art.py). Keep it pure black; the tutorial tints it.

**Where they are used:**
- The offer card: window, BUY / RESERVE / REROLL with coin / star / reroll icons, and close.
- The workbench: window, wrench icon, EQUIP / EQUIPPED / UNEQUIP, and close.
- The replace-reserve dialog buttons.
- The garage inspect panel.
- The arena's JOIN MATCH, LEAVE ARENA (door icon), PAINT (brush icon) and intro OK.

The upgrade screen was left alone, as asked.

## Starter Pack card icon (2026-10-06)
- **icon_starterpack** (256 × 256, Fit): "chunky orange gift box with a blue ribbon and bow and a white snowflake on the front, a small red plow blade leaning on its right side and a grey wheel with a red hub peeking out on the left, sitting on a fluffy white snow pile" + style. It must stay readable at about 60 px.
