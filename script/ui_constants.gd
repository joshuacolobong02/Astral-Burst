class_name UIConstants
extends RefCounted

## Shared UI constants for mobile-first, cross-platform design.
## Ensures consistent styling across HUD, Start Menu, Game Over.

# Touch targets - min 48dp (Android) / 44pt (iOS)
const TOUCH_TARGET_MIN := 52
const BUTTON_MIN_HEIGHT := 64

# Typography - readable on small screens (min 14-16px body)
const FONT_SIZE_SCORE := 18
const FONT_SIZE_LABEL := 16
const FONT_SIZE_SMALL := 14
const FONT_SIZE_TITLE := 28

# Spacing - 4pt grid
const SPACING_XS := 4
const SPACING_SM := 8
const SPACING_MD := 12
const SPACING_LG := 16
const SPACING_XL := 24
const EDGE_MARGIN := 12

# Colors - consistent palette
const BG_DARK := Color(0.06, 0.06, 0.1, 0.92)
const BG_OVERLAY := Color(0.04, 0.04, 0.08, 0.75)
const ACCENT := Color(0.35, 0.65, 1.0, 1.0)
const ACCENT_DIM := Color(0.5, 0.75, 1.0, 0.9)
const TEXT_PRIMARY := Color(1.0, 1.0, 1.0, 1.0)
const TEXT_SECONDARY := Color(0.85, 0.9, 1.0, 1.0)
const BORDER_SUBTLE := Color(1.0, 1.0, 1.0, 0.15)
const CORNER_RADIUS := 8
const CORNER_RADIUS_LG := 16

static func get_safe_margin() -> float:
	if OS.get_name() in ["iOS", "Android"]:
		return 16.0
	return 12.0
