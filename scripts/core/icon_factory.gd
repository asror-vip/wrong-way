extends Node

# IconFactory: Procedural and Vector SVG icon generator and cache for Wrong Way.

# Provides crisp, resolution-independent vector icons without relying on OS emojis.

var _cache: Dictionary = {}

const SVG_ICONS = {
	"star_filled": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26" fill="#fbbf24" stroke="#d97706" stroke-width="1.5" stroke-linejoin="round"/>
	</svg>""",

	"star_empty": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26" fill="#36323d" stroke="#544e5e" stroke-width="1.5" stroke-linejoin="round"/>
	</svg>""",

	"timer": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<circle cx="12" cy="13" r="8" fill="none" stroke="#60a5fa" stroke-width="2.2"/>
		<polyline points="12,9 12,13 15,15" fill="none" stroke="#60a5fa" stroke-width="2.2" stroke-linecap="round"/>
		<line x1="10" y1="2" x2="14" y2="2" stroke="#60a5fa" stroke-width="2.2" stroke-linecap="round"/>
		<line x1="12" y1="2" x2="12" y2="5" stroke="#60a5fa" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"skull": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M12 2a9 9 0 0 0-9 9c0 3.1 1.6 5.8 4 7.4V21a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-2.6c2.4-1.6 4-4.3 4-7.4a9 9 0 0 0-9-9z" fill="#f87171"/>
		<circle cx="8.5" cy="11.5" r="2.2" fill="#1c1924"/>
		<circle cx="15.5" cy="11.5" r="2.2" fill="#1c1924"/>
		<path d="M10 18v3M12 18v3M14 18v3" stroke="#1c1924" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"lock": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="4" y="10" width="16" height="12" rx="2.5" fill="#9ca3af"/>
		<path d="M7 10V7a5 5 0 0 1 10 0v3" fill="none" stroke="#9ca3af" stroke-width="2.5" stroke-linecap="round"/>
		<circle cx="12" cy="15.5" r="1.5" fill="#1f2937"/>
	</svg>""",

	"lock_open": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="4" y="10" width="16" height="12" rx="2.5" fill="#22c55e"/>
		<path d="M7 10V6a5 5 0 0 1 9.5-2" fill="none" stroke="#22c55e" stroke-width="2.5" stroke-linecap="round"/>
		<circle cx="12" cy="15.5" r="1.5" fill="#14532d"/>
	</svg>""",

	"video_ad": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="2" y="4" width="15" height="16" rx="2.5" fill="#fbbf24"/>
		<polygon points="17,8.5 22,5.5 22,18.5 17,15.5" fill="#f59e0b"/>
		<polygon points="7,9 12,12 7,15" fill="#1c1924"/>
	</svg>""",

	"pause": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="5" y="4" width="4.5" height="16" rx="1.5" fill="#f3f4f6"/>
		<rect x="14.5" y="4" width="4.5" height="16" rx="1.5" fill="#f3f4f6"/>
	</svg>""",

	"play": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="6,3 20,12 6,21" fill="#22c55e"/>
	</svg>""",

	"restart": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M21 12a9 9 0 1 1-2.6-6.4L21 8" fill="none" stroke="#f3f4f6" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
		<polyline points="21,3 21,8 16,8" fill="none" stroke="#f3f4f6" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"map": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="3,6 9,3 15,6 21,3 21,18 15,21 9,18 3,21" fill="none" stroke="#38bdf8" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<line x1="9" y1="3" x2="9" y2="18" stroke="#38bdf8" stroke-width="2.2"/>
		<line x1="15" y1="6" x2="15" y2="21" stroke="#38bdf8" stroke-width="2.2"/>
	</svg>""",

	"levels_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="4" y="13" width="3.5" height="8" rx="1.5" fill="#f3f4f6"/>
		<rect x="10.25" y="8" width="3.5" height="13" rx="1.5" fill="#f3f4f6"/>
		<rect x="16.5" y="3" width="3.5" height="18" rx="1.5" fill="#f3f4f6"/>
	</svg>""",

	"home": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M3 10.5L12 3l9 7.5V20a1.5 1.5 0 0 1-1.5 1.5H4.5A1.5 1.5 0 0 1 3 20v-9.5z" fill="none" stroke="#f3f4f6" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<polyline points="9,21 9,13 15,13 15,21" fill="none" stroke="#f3f4f6" stroke-width="2.2"/>
	</svg>""",

	"gear": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<circle cx="12" cy="12" r="3.2" fill="none" stroke="#cbd5e1" stroke-width="2.2"/>
		<path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" fill="none" stroke="#cbd5e1" stroke-width="2.2"/>
	</svg>""",

	"arrow_left": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<line x1="19" y1="12" x2="5" y2="12" stroke="#f3f4f6" stroke-width="2.5" stroke-linecap="round"/>
		<polyline points="12,19 5,12 12,5" fill="none" stroke="#f3f4f6" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"trophy": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M6 3h12v7a6 6 0 0 1-12 0V3z" fill="#facc15" stroke="#ca8a04" stroke-width="1.8"/>
		<path d="M6 5H3a2 2 0 0 0-2 2v1a4 4 0 0 0 4 4h1" fill="none" stroke="#ca8a04" stroke-width="1.8"/>
		<path d="M18 5h3a2 2 0 0 1 2 2v1a4 4 0 0 1-4 4h-1" fill="none" stroke="#ca8a04" stroke-width="1.8"/>
		<line x1="12" y1="16" x2="12" y2="20" stroke="#ca8a04" stroke-width="2.2"/>
		<rect x="8" y="20" width="8" height="3" rx="1" fill="#ca8a04"/>
	</svg>""",

	"users": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" fill="none" stroke="#a78bfa" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="9" cy="7" r="4" fill="none" stroke="#a78bfa" stroke-width="2.2"/>
		<path d="M23 21v-2a4 4 0 0 0-3-3.87" fill="none" stroke="#a78bfa" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M16 3.13a4 4 0 0 1 0 7.75" fill="none" stroke="#a78bfa" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"sound_on": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="11,4 6,8 2,8 2,16 6,16 11,20" fill="#22c55e"/>
		<path d="M15.5 8.5a5 5 0 0 1 0 7" fill="none" stroke="#22c55e" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M19 5a9 9 0 0 1 0 14" fill="none" stroke="#22c55e" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"sound_off": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="11,4 6,8 2,8 2,16 6,16 11,20" fill="#9ca3af"/>
		<line x1="22" y1="9" x2="16" y2="15" stroke="#ef4444" stroke-width="2.2" stroke-linecap="round"/>
		<line x1="16" y1="9" x2="22" y2="15" stroke="#ef4444" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"music_on": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M9 18V5l12-2v13" fill="none" stroke="#38bdf8" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<circle cx="6" cy="18" r="3" fill="#38bdf8"/>
		<circle cx="18" cy="16" r="3" fill="#38bdf8"/>
	</svg>""",

	"music_off": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M9 18V5l12-2v13" fill="none" stroke="#9ca3af" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<circle cx="6" cy="18" r="3" fill="#9ca3af"/>
		<circle cx="18" cy="16" r="3" fill="#9ca3af"/>
		<line x1="22" y1="9" x2="16" y2="15" stroke="#ef4444" stroke-width="2.2" stroke-linecap="round"/>
		<line x1="16" y1="9" x2="22" y2="15" stroke="#ef4444" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"shake": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="7" y="3" width="10" height="18" rx="2" fill="none" stroke="#f59e0b" stroke-width="2.2"/>
		<line x1="11" y1="18" x2="13" y2="18" stroke="#f59e0b" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M3 8a3 3 0 0 1 0 8" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
		<path d="M21 8a3 3 0 0 0 0 8" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
	</svg>""",

	"globe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<circle cx="12" cy="12" r="9" fill="none" stroke="#38bdf8" stroke-width="2.2"/>
		<line x1="3" y1="12" x2="21" y2="12" stroke="#38bdf8" stroke-width="2.2"/>
		<path d="M12 3a13 13 0 0 0 0 18" fill="none" stroke="#38bdf8" stroke-width="2.2"/>
		<path d="M12 3a13 13 0 0 1 0 18" fill="none" stroke="#38bdf8" stroke-width="2.2"/>
	</svg>""",

	"slider_grabber": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18" width="18" height="18">
		<circle cx="9" cy="9" r="7.5" fill="#f8fafc" stroke="#38bdf8" stroke-width="1.8"/>
	</svg>""",

	"slider_grabber_hover": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18" width="18" height="18">
		<circle cx="9" cy="9" r="8.2" fill="#ffffff" stroke="#67e8f9" stroke-width="2.2"/>
	</svg>""",

	"close": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<line x1="18" y1="6" x2="6" y2="18" stroke="#ef4444" stroke-width="2.5" stroke-linecap="round"/>
		<line x1="6" y1="6" x2="18" y2="18" stroke="#ef4444" stroke-width="2.5" stroke-linecap="round"/>
	</svg>""",

	"wrench": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z" fill="#f59e0b"/>
	</svg>""",

	"slot": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="3" y="4" width="18" height="16" rx="3" fill="#1e1b2e" stroke="#8b5cf6" stroke-width="2"/>
		<rect x="6" y="7" width="12" height="4" rx="1" fill="#a78bfa"/>
		<circle cx="7.5" cy="15.5" r="1.5" fill="#38bdf8"/>
		<circle cx="12" cy="15.5" r="1.5" fill="#34d399"/>
		<circle cx="16.5" cy="15.5" r="1.5" fill="#fbbf24"/>
	</svg>""",

	"slot_saved": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="3" y="3" width="18" height="18" rx="4" fill="#142e23" stroke="#22c55e" stroke-width="2"/>
		<polyline points="7,12.5 10.5,16 17,8.5" fill="none" stroke="#4ade80" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"slot_empty": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="3" y="3" width="18" height="18" rx="4" fill="#171520" stroke="#64748b" stroke-width="1.8" stroke-dasharray="3 2"/>
		<circle cx="12" cy="12" r="2.2" fill="#475569"/>
	</svg>""",

	"crown": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M2 19h20v2H2z" fill="#f8fafc"/>
		<path d="M2 7l4 6 6-9 6 9 4-6v10H2z" fill="#f8fafc"/>
		<circle cx="2" cy="7" r="1.5" fill="#f8fafc"/>
		<circle cx="12" cy="4" r="1.5" fill="#f8fafc"/>
		<circle cx="22" cy="7" r="1.5" fill="#f8fafc"/>
	</svg>""",

	"crown_gold": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M2 19h20v2H2z" fill="#f59e0b"/>
		<path d="M2 7l4 6 6-9 6 9 4-6v10H2z" fill="#fbbf24"/>
		<circle cx="2" cy="7" r="1.5" fill="#fde047"/>
		<circle cx="12" cy="4" r="1.5" fill="#fde047"/>
		<circle cx="22" cy="7" r="1.5" fill="#fde047"/>
	</svg>""",

	"chevron_right": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polyline points="9 6 15 12 9 18" fill="none" stroke="#0f121a" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"arrow_up": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="12 4 21 18 3 18" fill="#f8fafc"/>
	</svg>""",

	"arrow_left_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="18 4 6 12 18 20" fill="#f8fafc"/>
	</svg>""",

	"arrow_right_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="6 4 18 12 6 20" fill="#f8fafc"/>
	</svg>""",

	"diamond": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="12 3 21 12 12 21 3 12" fill="#94a3b8"/>
	</svg>""",

	"timer_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<circle cx="12" cy="13" r="8" fill="none" stroke="#f8fafc" stroke-width="2.0"/>
		<polyline points="12,9 12,13 15,15" fill="none" stroke="#f8fafc" stroke-width="2.0" stroke-linecap="round"/>
		<line x1="10" y1="2" x2="14" y2="2" stroke="#f8fafc" stroke-width="2.0" stroke-linecap="round"/>
		<line x1="12" y1="2" x2="12" y2="5" stroke="#f8fafc" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"skull_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M12 2a9 9 0 0 0-9 9c0 3.1 1.6 5.8 4 7.4V21a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-2.6c2.4-1.6 4-4.3 4-7.4a9 9 0 0 0-9-9z" fill="#f8fafc"/>
		<circle cx="8.5" cy="11.5" r="2.2" fill="#0c0e14"/>
		<circle cx="15.5" cy="11.5" r="2.2" fill="#0c0e14"/>
		<path d="M10 18v3M12 18v3M14 18v3" stroke="#0c0e14" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"level_select": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="3" y="13" width="4" height="8" rx="1" fill="#f8fafc"/>
		<rect x="10" y="8" width="4" height="13" rx="1" fill="#f8fafc"/>
		<rect x="17" y="3" width="4" height="18" rx="1" fill="#f8fafc"/>
	</svg>""",

	"quit": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" fill="none" stroke="#f8fafc" stroke-width="2.2" stroke-linecap="round"/>
		<polyline points="16 17 21 12 16 7" fill="none" stroke="#f8fafc" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<line x1="21" y1="12" x2="9" y2="12" stroke="#f8fafc" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"star_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26" fill="#f8fafc"/>
	</svg>""",

	"star_dim": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26" fill="#1e222e" stroke="#333a4c" stroke-width="1.5" stroke-linejoin="round"/>
	</svg>""",

	"cross": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<line x1="18" y1="6" x2="6" y2="18" stroke="#f8fafc" stroke-width="2.5" stroke-linecap="round"/>
		<line x1="6" y1="6" x2="18" y2="18" stroke="#f8fafc" stroke-width="2.5" stroke-linecap="round"/>
	</svg>""",

	"circle_btn_left": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
		<circle cx="32" cy="33.5" r="28" fill="#000000" opacity="0.38"/>
		<circle cx="32" cy="32" r="28" fill="#0c1018" fill-opacity="0.80" stroke="#36435c" stroke-width="1.8"/>
		<circle cx="32" cy="32" r="26.5" fill="none" stroke="#ffffff" stroke-width="0.8" stroke-opacity="0.12"/>
		<polygon points="36,20 22,32 36,44" fill="#f8fafc"/>
	</svg>""",

	"circle_btn_right": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
		<circle cx="32" cy="33.5" r="28" fill="#000000" opacity="0.38"/>
		<circle cx="32" cy="32" r="28" fill="#0c1018" fill-opacity="0.80" stroke="#36435c" stroke-width="1.8"/>
		<circle cx="32" cy="32" r="26.5" fill="none" stroke="#ffffff" stroke-width="0.8" stroke-opacity="0.12"/>
		<polygon points="28,20 42,32 28,44" fill="#f8fafc"/>
	</svg>""",

	"circle_btn_jump": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 68 68" width="68" height="68">
		<circle cx="34" cy="35.5" r="30" fill="#000000" opacity="0.38"/>
		<circle cx="34" cy="34" r="30" fill="#0c1018" fill-opacity="0.80" stroke="#36435c" stroke-width="1.8"/>
		<circle cx="34" cy="34" r="28.5" fill="none" stroke="#ffffff" stroke-width="0.8" stroke-opacity="0.12"/>
		<polygon points="34,20 48,39 20,39" fill="#f8fafc"/>
	</svg>""",

	"circle_btn_dash": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
		<circle cx="32" cy="33.5" r="28" fill="#000000" opacity="0.38"/>
		<circle cx="32" cy="32" r="28" fill="#0c1018" fill-opacity="0.80" stroke="#36435c" stroke-width="1.8"/>
		<circle cx="32" cy="32" r="26.5" fill="none" stroke="#ffffff" stroke-width="0.8" stroke-opacity="0.12"/>
		<path d="M22 22l11 10-11 10m9-20l11 10-11 10" fill="none" stroke="#f8fafc" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"circle_btn_pause": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44" width="44" height="44">
		<circle cx="22" cy="23" r="19" fill="#000000" opacity="0.38"/>
		<circle cx="22" cy="22" r="19" fill="#0c1018" fill-opacity="0.80" stroke="#36435c" stroke-width="1.6"/>
		<circle cx="22" cy="22" r="17.8" fill="none" stroke="#ffffff" stroke-width="0.8" stroke-opacity="0.12"/>
		<rect x="15" y="14" width="4.5" height="16" rx="1.5" fill="#f8fafc"/>
		<rect x="24.5" y="14" width="4.5" height="16" rx="1.5" fill="#f8fafc"/>
	</svg>""",

	"circle_btn_restart": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44" width="44" height="44">
		<circle cx="22" cy="23" r="19" fill="#000000" opacity="0.38"/>
		<circle cx="22" cy="22" r="19" fill="#0c1018" fill-opacity="0.80" stroke="#36435c" stroke-width="1.6"/>
		<circle cx="22" cy="22" r="17.8" fill="none" stroke="#ffffff" stroke-width="0.8" stroke-opacity="0.12"/>
		<path d="M22 13a9 9 0 1 0 8.5 6" fill="none" stroke="#f8fafc" stroke-width="2.2" stroke-linecap="round"/>
		<polyline points="26 13 31 13 31 8" fill="none" stroke="#f8fafc" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"circle_btn_close": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 36 36" width="36" height="36">
		<circle cx="18" cy="19" r="15" fill="#000000" opacity="0.38"/>
		<circle cx="18" cy="18" r="15" fill="#0c1018" fill-opacity="0.85" stroke="#36435c" stroke-width="1.5"/>
		<circle cx="18" cy="18" r="13.8" fill="none" stroke="#ffffff" stroke-width="0.8" stroke-opacity="0.12"/>
		<line x1="12" y1="12" x2="24" y2="24" stroke="#f8fafc" stroke-width="2.2" stroke-linecap="round"/>
		<line x1="24" y1="12" x2="12" y2="24" stroke="#f8fafc" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"circle_btn_gear": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44" width="44" height="44">
		<circle cx="22" cy="23" r="19" fill="#000000" opacity="0.38"/>
		<circle cx="22" cy="22" r="19" fill="#0c1018" fill-opacity="0.80" stroke="#36435c" stroke-width="1.6"/>
		<circle cx="22" cy="22" r="17.8" fill="none" stroke="#ffffff" stroke-width="0.8" stroke-opacity="0.12"/>
		<circle cx="22" cy="22" r="4" fill="none" stroke="#f8fafc" stroke-width="2.2"/>
		<path d="M22 13v2m0 14v2m9-9h-2m-14 0H9m15.2-6.2l-1.4 1.4m-9.6 9.6l-1.4 1.4m0-12.4l1.4 1.4m9.6 9.6l1.4 1.4" stroke="#f8fafc" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"circle_btn_back": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44" width="44" height="44">
		<circle cx="22" cy="23" r="19" fill="#000000" opacity="0.38"/>
		<circle cx="22" cy="22" r="19" fill="#0c1018" fill-opacity="0.80" stroke="#36435c" stroke-width="1.6"/>
		<circle cx="22" cy="22" r="17.8" fill="none" stroke="#ffffff" stroke-width="0.8" stroke-opacity="0.12"/>
		<polygon points="26 14 14 22 26 30" fill="#f8fafc"/>
	</svg>""",

	"circle_btn_home": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44" width="44" height="44">
		<circle cx="22" cy="23" r="19" fill="#000000" opacity="0.38"/>
		<circle cx="22" cy="22" r="19" fill="#0c1018" fill-opacity="0.80" stroke="#36435c" stroke-width="1.6"/>
		<circle cx="22" cy="22" r="17.8" fill="none" stroke="#ffffff" stroke-width="0.8" stroke-opacity="0.12"/>
		<path d="M13 21L22 13.5l9 7.5V30a1 1 0 0 1-1 1h-5v-6h-6v6h-5a1 1 0 0 1-1-1v-9z" fill="none" stroke="#f8fafc" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"circle_btn_quit": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44" width="44" height="44">
		<circle cx="22" cy="23" r="19" fill="#000000" opacity="0.38"/>
		<circle cx="22" cy="22" r="19" fill="#0c1018" fill-opacity="0.80" stroke="#36435c" stroke-width="1.6"/>
		<circle cx="22" cy="22" r="17.8" fill="none" stroke="#ffffff" stroke-width="0.8" stroke-opacity="0.12"/>
		<path d="M18 28H14a2 2 0 0 1-2-2V16a2 2 0 0 1 2-2h4" fill="none" stroke="#f8fafc" stroke-width="2.0" stroke-linecap="round"/>
		<polyline points="24 26 28 22 24 18" fill="none" stroke="#f8fafc" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<line x1="28" y1="22" x2="18" y2="22" stroke="#f8fafc" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"trophy_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M6 9H3a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1h3m12 5h3a1 1 0 0 0 1-1V5a1 1 0 0 0-1-1h-3" fill="none" stroke="#f8fafc" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M6 4h12v7a6 6 0 0 1-12 0V4z" fill="none" stroke="#f8fafc" stroke-width="2.0"/>
		<path d="M12 17v4m-4 0h8" stroke="#f8fafc" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"users_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" fill="none" stroke="#f8fafc" stroke-width="2.0" stroke-linecap="round"/>
		<circle cx="9" cy="7" r="4" fill="none" stroke="#f8fafc" stroke-width="2.0"/>
		<path d="M23 21v-2a4 4 0 0 0-3-3.87" fill="none" stroke="#f8fafc" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M16 3.13a4 4 0 0 1 0 7.75" fill="none" stroke="#f8fafc" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"lock_zone_big": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
		<circle cx="32" cy="34" r="28" fill="#080c14" fill-opacity="0.88" stroke="#3e4f70" stroke-width="2"/>
		<rect x="20" y="28" width="24" height="20" rx="4" fill="#182030" stroke="#f8fafc" stroke-width="2.2"/>
		<path d="M24 28V22a8 8 0 0 1 16 0v6" fill="none" stroke="#f8fafc" stroke-width="2.5" stroke-linecap="round"/>
		<circle cx="32" cy="37" r="2.5" fill="#f8fafc"/>
		<path d="M32 39.5V43" stroke="#f8fafc" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"star_gold": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26" fill="#facc15" stroke="#ffffff" stroke-width="1.2" stroke-linejoin="round"/>
	</svg>""",

	"avatar_player": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
		<circle cx="16" cy="16" r="15" fill="#0f172a" stroke="#38bdf8" stroke-width="2"/>
		<circle cx="16" cy="12" r="5" fill="#38bdf8"/>
		<path d="M7 26c0-4.5 4-8 9-8s9 3.5 9 8" fill="#38bdf8"/>
	</svg>""",

	"avatar_ninja": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
		<circle cx="16" cy="16" r="15" fill="#181124" stroke="#c084fc" stroke-width="2"/>
		<circle cx="16" cy="12" r="5" fill="#c084fc"/>
		<path d="M7 26c0-4.5 4-8 9-8s9 3.5 9 8" fill="#c084fc"/>
	</svg>""",

	"avatar_shadow": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
		<circle cx="16" cy="16" r="15" fill="#111827" stroke="#94a3b8" stroke-width="2"/>
		<circle cx="16" cy="12" r="5" fill="#94a3b8"/>
		<path d="M7 26c0-4.5 4-8 9-8s9 3.5 9 8" fill="#94a3b8"/>
	</svg>""",

	"avatar_robot": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
		<circle cx="16" cy="16" r="15" fill="#06282d" stroke="#2dd4bf" stroke-width="2"/>
		<circle cx="16" cy="12" r="5" fill="#2dd4bf"/>
		<path d="M7 26c0-4.5 4-8 9-8s9 3.5 9 8" fill="#2dd4bf"/>
	</svg>""",

	"avatar_pro": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
		<circle cx="16" cy="16" r="15" fill="#241a06" stroke="#f59e0b" stroke-width="2"/>
		<circle cx="16" cy="12" r="5" fill="#f59e0b"/>
		<path d="M7 26c0-4.5 4-8 9-8s9 3.5 9 8" fill="#f59e0b"/>
	</svg>""",

	"swords": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M14.5 17.5L3 6V3h3l11.5 11.5" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
		<path d="M13 19l2 2 4-4-2-2" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
		<path d="M19 13l2-2-4-4-2 2" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
		<path d="M9.5 17.5L21 6V3h-3L6.5 14.5" stroke="#94a3b8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
	</svg>""",

	"swords_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M14.5 17.5L3 6V3h3l11.5 11.5" stroke="#f1f5f9" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
		<path d="M13 19l2 2 4-4-2-2" stroke="#f1f5f9" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
		<path d="M19 13l2-2-4-4-2 2" stroke="#f1f5f9" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
		<path d="M9.5 17.5L21 6V3h-3L6.5 14.5" stroke="#cbd5e1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
	</svg>""",

	"copy": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="8" y="8" width="13" height="13" rx="2" fill="none" stroke="#60a5fa" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M4 16H3a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v1" fill="none" stroke="#60a5fa" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"refresh": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M21 2v6h-6M3 22v-6h6" stroke="#60a5fa" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
		<path d="M19 15a8 8 0 0 1-13.8 2.2L3 16M5 9a8 8 0 0 1 13.8-2.2L21 8" stroke="#60a5fa" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
	</svg>""",

	"lightning": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" fill="#38bdf8"/>
	</svg>""",

	"lightning_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" fill="#f8fafc"/>
	</svg>""",

	"gamepad": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="2" y="6" width="20" height="12" rx="4" fill="none" stroke="#38bdf8" stroke-width="2"/>
		<line x1="6" y1="12" x2="10" y2="12" stroke="#38bdf8" stroke-width="2" stroke-linecap="round"/>
		<line x1="8" y1="10" x2="8" y2="14" stroke="#38bdf8" stroke-width="2" stroke-linecap="round"/>
		<circle cx="15.5" cy="12" r="1" fill="#38bdf8"/>
		<circle cx="17.5" cy="10" r="1" fill="#38bdf8"/>
	</svg>""",

	"check_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polyline points="20 6 9 17 4 12" fill="none" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"close_white": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<line x1="18" y1="6" x2="6" y2="18" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round"/>
		<line x1="6" y1="6" x2="18" y2="18" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round"/>
	</svg>""",

	"cloud_layer": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 960 40" width="960" height="40">
		<defs>
			<linearGradient id="cloudGrad" x1="0%" y1="0%" x2="0%" y2="100%">
				<stop offset="0%" stop-color="#253552"/>
				<stop offset="35%" stop-color="#172235"/>
				<stop offset="70%" stop-color="#0e1522"/>
				<stop offset="100%" stop-color="#06090f"/>
			</linearGradient>
			<linearGradient id="cloudGradBack" x1="0%" y1="0%" x2="0%" y2="100%">
				<stop offset="0%" stop-color="#182336" stop-opacity="0.92"/>
				<stop offset="45%" stop-color="#101724" stop-opacity="0.96"/>
				<stop offset="100%" stop-color="#06090f" stop-opacity="1.0"/>
			</linearGradient>
		</defs>
		
		<!-- Back Deep Clouds (Height ~26-30px, sits from y=10 to y=40) -->
		<path d="M 0,22 
			Q 45,11 95,14 
			Q 150,8 210,13 
			Q 275,7 340,11 
			Q 410,6 480,10 
			Q 550,6 620,11 
			Q 685,7 750,12 
			Q 815,8 880,13 
			Q 925,11 960,19 
			L 960,40 L 0,40 Z" 
			fill="url(#cloudGradBack)" stroke="#223047" stroke-width="1.2"/>

		<!-- Front Fluffy Clouds (Height ~20-25px, sits from y=15 to y=40) -->
		<path d="M 0,24 
			Q 50,14 110,17 
			Q 170,12 235,16 
			Q 300,10 370,15 
			Q 440,9 510,14 
			Q 580,10 650,16 
			Q 720,11 790,16 
			Q 855,12 920,18 
			Q 945,16 960,22 
			L 960,40 L 0,40 Z" 
			fill="url(#cloudGrad)" stroke="#415a82" stroke-width="1.5"/>
			
		<!-- Subtle 3D volumetric puff curves -->
		<path d="M 120,17 Q 175,11 230,16" fill="none" stroke="#2b3d5b" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M 250,15 Q 310,10 365,14" fill="none" stroke="#2b3d5b" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M 385,13 Q 450,8 505,12" fill="none" stroke="#2b3d5b" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M 525,12 Q 590,9 645,15" fill="none" stroke="#2b3d5b" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M 665,15 Q 730,10 785,16" fill="none" stroke="#2b3d5b" stroke-width="1.8" stroke-linecap="round"/>
		
		<!-- Soft Silver Rim Highlights -->
		<path d="M 125,16 Q 175,10 225,15" fill="none" stroke="#688ab8" stroke-width="1.0" stroke-opacity="0.75" stroke-linecap="round"/>
		<path d="M 255,14 Q 310,9 360,13" fill="none" stroke="#688ab8" stroke-width="1.0" stroke-opacity="0.75" stroke-linecap="round"/>
		<path d="M 390,12 Q 450,7 500,11" fill="none" stroke="#688ab8" stroke-width="1.0" stroke-opacity="0.75" stroke-linecap="round"/>
		<path d="M 530,11 Q 590,8 640,14" fill="none" stroke="#688ab8" stroke-width="1.0" stroke-opacity="0.75" stroke-linecap="round"/>
		<path d="M 670,14 Q 730,9 780,15" fill="none" stroke="#688ab8" stroke-width="1.0" stroke-opacity="0.75" stroke-linecap="round"/>
	</svg>""",
	"play_dark": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="6,3 20,12 6,21" fill="#0f121a"/>
	</svg>""",

	"save": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z" fill="none" stroke="#22c55e" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<polyline points="17 21 17 13 7 13 7 21" stroke="#22c55e" stroke-width="2.2"/>
		<polyline points="7 3 7 8 15 8" stroke="#22c55e" stroke-width="2.2"/>
	</svg>""",

	"load": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" fill="none" stroke="#38bdf8" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<polyline points="7 10 12 15 17 10" fill="none" stroke="#38bdf8" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<line x1="12" y1="15" x2="12" y2="3" stroke="#38bdf8" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"check": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polyline points="20 6 9 17 4 12" fill="none" stroke="#22c55e" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"trash": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polyline points="3 6 5 6 21 6" stroke="#ef4444" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" fill="none" stroke="#ef4444" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"eraser": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M19 14l-5 5H6l-3-3 10-10 6 6z" fill="none" stroke="#fb7185" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<line x1="18" y1="21" x2="22" y2="21" stroke="#fb7185" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"stop": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="5" y="5" width="14" height="14" rx="2" fill="#ef4444"/>
	</svg>""",

	"circular_saw": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<circle cx="12" cy="12" r="8" fill="#64748b"/>
		<circle cx="12" cy="12" r="4" fill="#dc2626"/>
		<circle cx="12" cy="12" r="1.5" fill="#f8fafc"/>
		<polygon points="12,1 14,4 10,4" fill="#94a3b8"/>
		<polygon points="12,23 14,20 10,20" fill="#94a3b8"/>
		<polygon points="1,12 4,14 4,10" fill="#94a3b8"/>
		<polygon points="23,12 20,14 20,10" fill="#94a3b8"/>
		<polygon points="4.2,4.2 6.5,4.5 4.5,6.5" fill="#94a3b8"/>
		<polygon points="19.8,19.8 17.5,19.5 19.5,17.5" fill="#94a3b8"/>
		<polygon points="4.2,19.8 6.5,17.5 4.5,17.5" fill="#94a3b8"/>
		<polygon points="19.8,4.2 17.5,6.5 19.5,6.5" fill="#94a3b8"/>
	</svg>""",

	"spike_ball": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<circle cx="12" cy="12" r="6" fill="#1e1b29"/>
		<circle cx="10" cy="10" r="2" fill="#475569"/>
		<polygon points="12,2 14,6 10,6" fill="#e11d48"/>
		<polygon points="12,22 14,18 10,18" fill="#e11d48"/>
		<polygon points="2,12 6,14 6,10" fill="#e11d48"/>
		<polygon points="22,12 18,14 18,10" fill="#e11d48"/>
		<polygon points="5,5 8,6 6,8" fill="#e11d48"/>
		<polygon points="19,19 16,18 18,16" fill="#e11d48"/>
		<polygon points="5,19 8,18 6,16" fill="#e11d48"/>
		<polygon points="19,5 16,6 18,8" fill="#e11d48"/>
	</svg>""",

	"pop_up_spikes": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="2" y="18" width="20" height="4" rx="1" fill="#334155"/>
		<polygon points="6,6 9,18 3,18" fill="#ef4444"/>
		<polygon points="12,3 15,18 9,18" fill="#ef4444"/>
		<polygon points="18,6 21,18 15,18" fill="#ef4444"/>
	</svg>""",

	"platform": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="2" y="6" width="20" height="13" rx="2" fill="#1c1a22" stroke="#475569" stroke-width="1.8"/>
		<line x1="3" y1="8.5" x2="21" y2="8.5" stroke="#94a3b8" stroke-width="1.8"/>
		<line x1="8" y1="12" x2="8" y2="18" stroke="#334155" stroke-width="1.5"/>
		<line x1="16" y1="12" x2="16" y2="18" stroke="#334155" stroke-width="1.5"/>
	</svg>""",

	"trap_floor": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="2" y="6" width="20" height="13" rx="2" fill="#2e262a" stroke="#e11d48" stroke-width="1.8"/>
		<line x1="3" y1="8.5" x2="21" y2="8.5" stroke="#f43f5e" stroke-width="1.8"/>
		<line x1="6" y1="17" x2="18" y2="9" stroke="#ef4444" stroke-width="1.5" stroke-dasharray="2,2"/>
	</svg>""",

	"spikes": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="2" y="18" width="20" height="4" rx="1" fill="#24202c"/>
		<polygon points="4,18 8,4 12,18" fill="#e11d48"/>
		<polygon points="12,18 16,4 20,18" fill="#e11d48"/>
		<polyline points="4,18 8,4 12,18 16,4 20,18" fill="none" stroke="#fb7185" stroke-width="1.2"/>
	</svg>""",

	"saw": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<circle cx="12" cy="12" r="7" fill="#475569"/>
		<circle cx="12" cy="12" r="3.5" fill="#dc2626"/>
		<circle cx="12" cy="12" r="1.5" fill="#f8fafc"/>
		<polygon points="12,2 14,5 10,5" fill="#94a3b8"/>
		<polygon points="12,22 14,19 10,19" fill="#94a3b8"/>
		<polygon points="2,12 5,14 5,10" fill="#94a3b8"/>
		<polygon points="22,12 19,14 19,10" fill="#94a3b8"/>
		<polygon points="5,5 7.5,5.5 5.5,7.5" fill="#94a3b8"/>
		<polygon points="19,19 16.5,18.5 18.5,16.5" fill="#94a3b8"/>
		<polygon points="5,19 7.5,18.5 5.5,16.5" fill="#94a3b8"/>
		<polygon points="19,5 16.5,5.5 18.5,7.5" fill="#94a3b8"/>
	</svg>""",

	"crusher": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="3" y="3" width="18" height="13" rx="1.5" fill="#262330" stroke="#475569" stroke-width="1.5"/>
		<line x1="6" y1="6" x2="18" y2="6" stroke="#f59e0b" stroke-width="1.8"/>
		<polygon points="4,16 6.5,21 9,16" fill="#9b2424"/>
		<polygon points="9,16 11.5,21 14,16" fill="#9b2424"/>
		<polygon points="14,16 16.5,21 19,16" fill="#9b2424"/>
	</svg>""",

	"spring": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="3" y="19" width="18" height="3" rx="1" fill="#1e1b24"/>
		<polyline points="6,19 12,15 18,19" fill="none" stroke="#94a3b8" stroke-width="2"/>
		<polyline points="6,15 12,11 18,15" fill="none" stroke="#64748b" stroke-width="2"/>
		<rect x="4" y="7" width="16" height="4" rx="1.5" fill="#f59e0b"/>
		<rect x="6" y="8" width="12" height="2" rx="0.5" fill="#fde047"/>
	</svg>""",

	"falling": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<polygon points="5,3 19,3 12,22" fill="#e11d48"/>
		<polygon points="7,4 17,4 12,18" fill="#fb7185"/>
		<polyline points="5,3 19,3 12,22" fill="none" stroke="#881337" stroke-width="1.5"/>
	</svg>""",

	"laser": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<circle cx="12" cy="4" r="3.5" fill="#3f3f46" stroke="#1e1b29" stroke-width="1.5"/>
		<circle cx="12" cy="4" r="1.8" fill="#ef4444"/>
		<line x1="12" y1="7.5" x2="12" y2="22" stroke="#ef4444" stroke-width="3" stroke-linecap="round"/>
		<line x1="12" y1="7.5" x2="12" y2="22" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round"/>
	</svg>""",

	"fake_door": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M5 22V9a7 7 0 0 1 14 0v13z" fill="#2e1065" stroke="#a855f7" stroke-width="1.8"/>
		<path d="M8 22V10a4 4 0 0 1 8 0v12z" fill="#180d2b"/>
		<circle cx="10" cy="13" r="1.5" fill="#ef4444"/>
		<circle cx="14" cy="13" r="1.5" fill="#ef4444"/>
	</svg>""",

	"door": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<path d="M5 22V9a7 7 0 0 1 14 0v13z" fill="#181520" stroke="#f59e0b" stroke-width="1.8"/>
		<path d="M8 22V10a4 4 0 0 1 8 0v12z" fill="#0c0f1a"/>
		<circle cx="14" cy="14" r="1.8" fill="#fbbf24"/>
	</svg>""",

	"player": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
		<rect x="4" y="4" width="16" height="16" rx="3" fill="#181520" stroke="#38bdf8" stroke-width="1.5"/>
		<circle cx="9" cy="10" r="2.2" fill="#ffffff"/>
		<circle cx="15" cy="10" r="2.2" fill="#ffffff"/>
		<circle cx="9.8" cy="10" r="1.2" fill="#000000"/>
		<circle cx="15.8" cy="10" r="1.2" fill="#000000"/>
	</svg>"""
}

func get_icon(icon_name: String, scale: float = 1.0) -> Texture2D:
	var key := "%s_%.1f" % [icon_name, scale]
	if _cache.has(key):
		return _cache[key]

	if not SVG_ICONS.has(icon_name):
		push_warning("IconFactory: Icon not found: " + icon_name)
		return null

	var svg_str: String = SVG_ICONS[icon_name]
	var img := Image.new()
	var err := img.load_svg_from_string(svg_str, scale)
	if err == OK:
		var tex := ImageTexture.create_from_image(img)
		_cache[key] = tex
		return tex
	return null

func create_texture_rect(icon_name: String, custom_sz: Vector2 = Vector2(24, 24), scale: float = 1.0) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = get_icon(icon_name, scale)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = custom_sz
	rect.size = custom_sz
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect
