extends Node

# LocaleManager: Multi-language localization system for Wrong Way
# Supports: uz (O'zbek), ru (Русский), en (English), tr (Türkçe)

signal language_changed(lang_code: String)

var current_language: String = "uz"

const LANGUAGES = {
	"uz": "O'zbekcha",
	"ru": "Русский",
	"en": "English",
	"tr": "Türkçe"
}

const STRINGS = {
	"uz": {
		# Title Screen
		"game_title": "WRONG WAY",
		"game_subtitle": "Tuzoqlar va sinovlar maydoni",
		"btn_start": "BOSHLASH",
		
		# Main Menu
		"btn_play": "O'YNASH",
		"btn_level_select": "DARAJALAR",
		"btn_multiplayer": "MULTIPLAYER",
		"btn_leaderboard": "REKORDLAR",
		"btn_settings": "SOZLAMALAR",
		"btn_quit": "CHIQISH",
		"best_chip": "Rekord: %s",
		"best_stars": "Yulduzlar: %d / 60",
		"level_header": "DARAJA %d",
		"level_complete": "DARAJA YAKUNLANDI",
		"great_job": "Ajoyib natija!",
		"last_record": "Oxirgi rekord: %s",
		"not_available": "Mavjud emas",
		"multiplayer_title": "MULTIPLAYER REJIMI",
		"multiplayer_desc": "1v1 Duel va Online Race rejimi tez kunda taqdim etiladi!\n\nHozirda Campaign darajalari faol.",
		"leaderboard_title": "REKORDLAR JADVALI",
		"leaderboard_desc": "Hozirgi bosqichda faqat lokal rekordlar saqlanmoqda.\n\nSizning eng yaxshi rekordingiz:\n%s",
		"total_time": "Jami vaqt: %ds",
		"leaderboard_total_stars": "Yulduzlar: %d",
		"leaderboard_total_time": "Umumiy vaqt: %d soniya",
		"level_time_item": "%d-daraja: %s",
		"tab_global": "GLOBAL",
		"tab_friends": "DO'STLAR",
		"player_you": "Siz",
		"leaderboard_guest_title": "Google hisobi talab qilinadi",
		"leaderboard_guest_desc": "Global va Do'stlar reytingini ko'rish hamda natijalaringizni saqlash uchun Google hisobingiz bilan kiring.",
		"leaderboard_google_login_btn": "Google orqali kirish",
		"leaderboard_google_connecting": "Google hisobiga ulanmoqda...",
		"leaderboard_friends_empty": "Hozircha do'stlar yo'q. Do'stlaringiz reytingini ko'rish uchun ular bilan o'ynang yoki qo'shing.",
		
		# Settings Modal
		"settings_title": "SOZLAMALAR",
		"setting_language": "Til (Language):",
		"setting_music": "Fon musiqasi (BGM):",
		"setting_music_volume": "Musiqa balandligi:",
		"setting_sound": "Ovoz effektlari (SFX):",
		"setting_sound_volume": "Effektlar balandligi:",
		"setting_shake": "Ekran silkinishi:",
		"status_on": "YONIQ",
		"status_off": "O'CHIQ",
		"controls_title": "Boshqaruv va Klaviatura:",
		"controls_desc": (
			"Yurish: A / D yoki ◄ / ► (Sensor)\nSakrash: W / Space / ▲\n"
			+ "Dash (Tezlashuv): Shift / J\nQayta boshlash: R\n"
			+ "Pauza / Menyu: Esc / P\nTo'liq ekran: F11"
		),
		"controls_title_desktop": "Klaviatura boshqaruvi:",
		"controls_desc_desktop": (
			"Yurish: A / D yoki ◄ / ►\nSakrash: W / Space / ▲\n"
			+ "Dash (Tezlashuv): Shift / J\nQayta boshlash: R  •  Pauza: Esc / P  •  To'liq ekran: F11"
		),
		"controls_title_mobile": "Sensor boshqaruv:",
		"controls_desc_mobile": (
			"Chap / O'ng — Yurish  •  Sakrash  •  Dash\n"
			+ "Tugmalar joyi va hajmini o'zingizga moslang."
		),
		"btn_close": "Yopish",
		"btn_customize_controls": "Tugmalar joyini sozlash",
		"controls_customizer_title": "TUGMALAR JOYINI SOZLASH",
		"controls_customizer_hint": "Tugmalarni xohlagan joyga surib joylashtiring",
		"customizer_size": "Hajmi:",
		"btn_reset_default": "Asliga qaytarish",
		"offline_title": "Internet aloqasi yo'q",
		"offline_desc": "Reyting va Google hisobi uchun internet kerak. Darajalar va Zona Yaratish oflayn ishlaydi.",
		"btn_retry": "Qayta urinish",
		"exit_press_again": "Chiqish uchun yana bir marta bosing",
		"tut_step_move_mobile": "Yurish uchun ◄ / ► tugmalarini bosing",
		"tut_step_move_pc": "Yurish uchun [A / D] yoki [◄ / ►] bosing",
		"tut_step_jump_mobile": "Tikanlardan sakrab o'ting!",
		"tut_step_jump_pc": "[SPACE] yoki [W] bilan tikanlardan sakrang!",
		"tut_step_dash_mobile": "Jarlikdan o'tish uchun DASH bosing!",
		"tut_step_dash_pc": "[SHIFT] yoki [J] bilan jarlikdan Dash qiling!",
		"tut_step_door": "Keyingi daraja uchun kamida 2 ★ yulduz oling (≤ 2 o'lim)!",
		"tut_trap_floor_toast": "Hech qachon polga ishonmang! 😈",
		
		# Level Select
		"map_title": "DARAJALAR",
		"chapter_1_title": "1-BOB: DARAJALAR",
		"chapter_2_title": "2-BOB: DARAJALAR",
		"chapter_3_title": "3-BOB: DARAJALAR",
		"chapter_4_title": "4-BOB: OLTIN KANYON",
		"chapter_5_title": "5-BOB: OLOVLI ABISS",
		"chapter_4_desc": "Sahro va Kanyon yangilanishi tez kunda taqdim etiladi!",
		"chapter_5_desc": "Lava va Vulqon yangilanishi tez kunda taqdim etiladi!",
		"chapter_nav_btn": "%d-BOB",
		"coming_soon_caps": "TEZ KUNDA",
		"more_levels_soon": "Yangi darajalar tez kunda taqdim etiladi!",
		"chapter_2_locked": "2-BOB QULFLANGAN",
		"chapter_2_unlock_req": "Ochish uchun 1-bobda kamida 50 ta yulduz to'plang",
		"chapter_3_locked": "3-BOB QULFLANGAN",
		"chapter_3_unlock_req": "Ochish uchun 2-bobda kamida 55 ta yulduz to'plang",
		"btn_chapter_1": "1-BOB",
		"btn_chapter_2": "2-BOB",
		"btn_chapter_3": "3-BOB",
		"btn_back": "Orqaga",
		"btn_menu": "Menyu",
		"lvl_label": "LVL %d",
		"lvl_ad_unlock": "Ochish",
		"lvl_locked": "Qulf",
		"total_stars": "%d / 180",
		"lock_title": "DARAJA QULFLANGAN",
		"lock_need_attempt": "Bu darajani reklama orqali ochish uchun avval %d-darajani o'ynab ko'ring!",
		"lock_cooldown": "Ketma-ket 2 ta darajani reklama bilan ochib bo'lmaydi (bitta daraja oralab).\n(Oxirgi ochilgan: %d-lvl. Keyingi ruxsat: %d-darajada)",
		"lock_need_stars": "Bu darajani ochish uchun avvalgi %d-darajada kamida 2 ta yulduz oling!",
		"lock_must_open_earlier": "Avval oldingi darajalarni oching!",
		"ad_loading_title": "REKLAMA YUKLANMOQDA",
		"ad_loading_msg": "Video reklama hali tayyor emas, birozdan keyin qayta bosing!",
		"lvl_unlocked_title": "DARAJA OCHILDI!",
		"lvl_unlocked_msg": "%d-daraja reklama orqali muvaffaqiyatli ochildi!",
		"zone2_title": "2-ZONA: TUMANLI QAL'A",
		"zone2_req": "Ochilish uchun 50 ta yulduz kerak",
		"zone2_status": "%d / 50",
		
		# Game HUD
		"hud_level": "LEVEL %d",
		"hud_time": "%.2fs",
		"hud_deaths": "%d ta o'lim",
		"btn_jump": "SAKRA",
		"btn_dash": "DASH",
		"btn_hud_menu": "Menyu",
		
		# Pause Modal
		"pause_title": "PAUZA",
		"btn_resume": "DAVOM ETISH",
		"btn_restart": "Qayta urinish",
		"btn_map": "Xarita",
		"btn_home": "Bosh menyu",
		
		# Win Overlay
		"win_title": "%d-DARAJA YAKUNLANDI!",
		"win_3_stars": "Mukammal natija! Keyingi daraja ochildi!",
		"win_2_stars": "Yaxshi natija! Keyingi daraja ochildi!",
		"win_1_star": "Keyingi darajani ochish uchun kamida 2 ta yulduz oling!",
		"win_time": "Vaqt: %.2fs",
		"win_deaths": "%d ta o'lim",
		"win_stats": "Vaqt: %ds   •   O'limlar: %d",
		"win_all_60_complete": "BARCHA 60 TA DARAJA YAKUNLANDI! 🎉\n4-BOB VA 5-BOB TEZ KUNDA",
		"btn_next_lvl": "KEYINGI DARAJA",
		"btn_unlock_next_ad": "REKLAMA BILAN OCHISH",
		
		# Level & Trap Editor
		"btn_editor": "ZONA YARATISH",
		"editor_title": "ZONA VA TUZOQ MUHARRIRI",
		"btn_test": "SINOV",
		"btn_stop_test": "TAHRIRGA QAYTISH",
		"btn_save": "SAQLASH",
		"btn_load": "YUKLASH",
		"btn_clear": "TOZALASH",
		"btn_erase": "O'CHIRGICH",
		"saved_notice": "Daraja muvaffaqiyatli saqlandi!",
		"cleared_notice": "Maydon tozalandi!",
		"slot_label": "Slot %d",
		"slot_saved": "Saqlangan",
		"slot_empty": "Bo'sh",
		"loaded_notice": "Slot %d yuklandi!",
		"reloaded_notice": "Slot %d qayta yuklandi!",
		"btn_reload_current": "Qayta yuklash (bekor qilish)",
		"test_won_notice": "Sinov muvaffaqiyatli yakunlandi! Darvoza ishlamoqda.",
		"tool_platform": "Pol",
		"tool_trap_floor": "Tuzoq pol",
		"tool_spikes": "Tikan",
		"tool_saw": "Arra",
		"tool_crusher": "Ezuvchi",
		"tool_spring": "Prujina",
		"tool_fake_door": "Soxta eshik",
		"tool_falling": "Stalaktit",
		"tool_laser": "Lazer",
		"tool_door": "Darvoza",
		"tool_player": "O'yinchi",
		"tool_circular_saw": "Aylanuvchi arra",
		"tool_spike_ball": "Tikanli shar",
		"tool_pop_up_spikes": "Otiluvchi tikan"
	},
	
	"ru": {
		# Title Screen
		"game_title": "WRONG WAY",
		"game_subtitle": "Арена ловушек и испытаний",
		"btn_start": "СТАРТ",
		
		# Main Menu
		"btn_play": "ИГРАТЬ",
		"btn_level_select": "ВЫБОР УРОВНЯ",
		"btn_multiplayer": "МУЛЬТИПЛЕЕР",
		"btn_leaderboard": "РЕКОРДЫ",
		"btn_settings": "НАСТРОЙКИ",
		"btn_quit": "ВЫХОД",
		"best_chip": "Рекорд: %s",
		"best_stars": "Звезды: %d / 60",
		"level_header": "УРОВЕНЬ %d",
		"level_complete": "УРОВЕНЬ ПРОЙДЕН",
		"great_job": "Отличная работа!",
		"last_record": "Лучший рекорд: %s",
		"not_available": "Нет данных",
		"multiplayer_title": "МУЛЬТИПЛЕЕР",
		"multiplayer_desc": "Режимы Дуэль 1v1 и Онлайн Гонка скоро появятся!\n\nСейчас доступны уровни Кампании.",
		"leaderboard_title": "ТАБЛИЦА РЕКОРДОВ",
		"leaderboard_desc": "На данном этапе сохраняются локальные рекорды.\n\nВаш лучший рекорд:\n%s",
		"total_time": "Общее время: %dс",
		"leaderboard_total_stars": "Звёзды: %d",
		"leaderboard_total_time": "Общее время: %d секунд",
		"level_time_item": "%d-уровень: %s",
		"tab_global": "ГЛОБАЛ",
		"tab_friends": "ДРУЗЬЯ",
		"player_you": "Вы",
		"leaderboard_guest_title": "Требуется аккаунт Google",
		"leaderboard_guest_desc": "Войдите через Google, чтобы видеть глобальный рейтинг и таблицу друзей, а также сохранять рекорды.",
		"leaderboard_google_login_btn": "Войти через Google",
		"leaderboard_google_connecting": "Подключение к Google...",
		"leaderboard_friends_empty": "Пока нет друзей в рейтинге. Сыграйте с друзьями, чтобы увидеть их здесь.",
		
		# Settings Modal
		"settings_title": "НАСТРОЙКИ",
		"setting_language": "Язык (Language):",
		"setting_music": "Фоновая музыка (BGM):",
		"setting_music_volume": "Громкость музыки:",
		"setting_sound": "Звуковые эффекты (SFX):",
		"setting_sound_volume": "Громкость звуков:",
		"setting_shake": "Тряска экрана:",
		"status_on": "ВКЛ",
		"status_off": "ВЫКЛ",
		"controls_title": "Управление и Клавиатура:",
		"controls_desc": (
			"Движение: A / D или ◄ / ► (Сенсор)\nПрыжок: W / Пробел / ▲\n"
			+ "Рывок (Dash): Shift / J\nБыстрый рестарт: R\n"
			+ "Пауза / Меню: Esc / P\nПолный экран: F11"
		),
		"controls_title_desktop": "Управление с клавиатуры:",
		"controls_desc_desktop": (
			"Движение: A / D или ◄ / ►\nПрыжок: W / Пробел / ▲\n"
			+ "Рывок (Dash): Shift / J\nРестарт: R  •  Пауза: Esc / P  •  Полный экран: F11"
		),
		"controls_title_mobile": "Сенсорное управление:",
		"controls_desc_mobile": (
			"Влево / Вправо — Движение  •  Прыжок  •  Рывок\n"
			+ "Настройте расположение и размер кнопок под себя."
		),
		"btn_close": "Закрыть",
		"btn_customize_controls": "Настроить кнопки",
		"controls_customizer_title": "НАСТРОЙКА КНОПОК",
		"controls_customizer_hint": "Перетащите кнопки в любое удобное место",
		"customizer_size": "Размер:",
		"btn_reset_default": "По умолчанию",
		"offline_title": "Нет подключения к интернету",
		"offline_desc": "Для рейтинга и входа через Google нужен интернет. Уровни и Редактор зон работают офлайн.",
		"btn_retry": "Повторить",
		"exit_press_again": "Нажмите ещё раз для выхода",
		"tut_step_move_mobile": "Нажимайте ◄ / ► для движения",
		"tut_step_move_pc": "Нажмите [A / D] или [◄ / ►] для движения",
		"tut_step_jump_mobile": "Перепрыгните через шипы!",
		"tut_step_jump_pc": "Нажмите [SPACE] или [W], чтобы перепрыгнуть шипы!",
		"tut_step_dash_mobile": "Нажмите РЫВОК (DASH), чтобы перелететь пропасть!",
		"tut_step_dash_pc": "Нажмите [SHIFT] или [J] для рывка через пропасть!",
		"tut_step_door": "Для следующего уровня нужно минимум 2 ★ звезды (≤ 2 смертей)!",
		"tut_trap_floor_toast": "Никогда не доверяй полу! 😈",
		
		# Level Select
		"map_title": "УРОВНИ",
		"chapter_1_title": "ГЛАВА 1: УРОВНИ",
		"chapter_2_title": "ГЛАВА 2: УРОВНИ",
		"chapter_3_title": "ГЛАВА 3: УРОВНИ",
		"chapter_4_title": "ГЛАВА 4: ЗОЛОТОЙ КАНЬОН",
		"chapter_5_title": "ГЛАВА 5: АДСКАЯ БЕЗДНА",
		"chapter_4_desc": "Обновление с Пустыней и Каньоном скоро выйдет!",
		"chapter_5_desc": "Обновление с Лавой и Вулканом скоро выйдет!",
		"chapter_nav_btn": "ГЛАВА %d",
		"coming_soon_caps": "СКОРО",
		"more_levels_soon": "Новые уровни появятся в следующем обновлении!",
		"chapter_2_locked": "ГЛАВА 2 ЗАБЛОКИРОВАНА",
		"chapter_2_unlock_req": "Соберите не менее 50 звёзд в 1-й главе, чтобы открыть",
		"chapter_3_locked": "ГЛАВА 3 ЗАБЛОКИРОВАНА",
		"chapter_3_unlock_req": "Соберите не менее 55 звёзд во 2-й главе, чтобы открыть",
		"btn_chapter_1": "ГЛАВА 1",
		"btn_chapter_2": "ГЛАВА 2",
		"btn_chapter_3": "ГЛАВА 3",
		"btn_back": "Назад",
		"btn_menu": "Меню",
		"lvl_label": "LVL %d",
		"lvl_ad_unlock": "Открыть",
		"lvl_locked": "Блок",
		"total_stars": "%d / 180",
		"lock_title": "УРОВЕНЬ ЗАБЛОКИРОВАН",
		"lock_need_attempt": "Чтобы открыть этот уровень за рекламу, сначала сыграйте уровень %d!",
		"lock_cooldown": "Нельзя открывать 2 уровня подряд за рекламу (через один уровень).\n(Последний пропуск: %d-й lvl. Следующий доступен: %d-й уровень)",
		"lock_need_stars": "Чтобы открыть этот уровень, получите минимум 2 звезды на уровне %d!",
		"lock_must_open_earlier": "Сначала откройте предыдущие уровни!",
		"ad_loading_title": "ЗАГРУЗКА РЕКЛАМЫ",
		"ad_loading_msg": "Видеореклама ещё загружается, нажмите ещё раз через пару секунд!",
		"lvl_unlocked_title": "УРОВЕНЬ ОТКРЫТ!",
		"lvl_unlocked_msg": "Уровень %d успешно открыт за просмотр рекламы!",
		"zone2_title": "ЗОНА 2: ТУМАННЫЙ ЗАМОК",
		"zone2_req": "Требуется 50 звезд для открытия",
		"zone2_status": "%d / 50",
		
		# Game HUD
		"hud_level": "LEVEL %d",
		"hud_time": "%.2fs",
		"hud_deaths": "%d смертей",
		"btn_jump": "ПРЫЖОК",
		"btn_dash": "РЫВОК",
		"btn_hud_menu": "Меню",
		
		# Pause Modal
		"pause_title": "ПАУЗА",
		"btn_resume": "ПРОДОЛЖИТЬ",
		"btn_restart": "Начать заново",
		"btn_map": "Карта",
		"btn_home": "Главное меню",
		
		# Win Overlay
		"win_title": "%d-Й УРОВЕНЬ ПРОЙДЕН!",
		"win_3_stars": "Идеально! Следующий уровень открыт!",
		"win_2_stars": "Отличный результат! Следующий уровень открыт!",
		"win_1_star": "Получите минимум 2 звезды, чтобы открыть следующий уровень!",
		"win_time": "Время: %.2fs",
		"win_deaths": "%d смертей",
		"win_stats": "Время: %dс   •   Смерти: %d",
		"win_all_60_complete": "ВСЕ 60 УРОВНЕЙ ПРОЙДЕНЫ! 🎉\nГЛАВА 4 И 5 СКОРО ВЫЙДУТ",
		"btn_next_lvl": "СЛЕДУЮЩИЙ УРОВЕНЬ",
		"btn_unlock_next_ad": "ОТКРЫТЬ ЗА РЕКЛАМУ",
		
		# Level & Trap Editor
		"btn_editor": "РЕДАКТОР ЗОНЫ",
		"editor_title": "РЕДАКТОР ЗОН И ЛОВУШЕК",
		"btn_test": "ТЕСТ",
		"btn_stop_test": "В РЕДАКТОР",
		"btn_save": "СОХРАНИТЬ",
		"btn_load": "ЗАГРУЗИТЬ",
		"btn_clear": "ОЧИСТИТЬ",
		"btn_erase": "ЛАСТИК",
		"saved_notice": "Уровень успешно сохранен!",
		"cleared_notice": "Поле очищено!",
		"slot_label": "Слот %d",
		"slot_saved": "Сохранен",
		"slot_empty": "Пусто",
		"loaded_notice": "Слот %d загружен!",
		"reloaded_notice": "Слот %d перезагружен!",
		"btn_reload_current": "Перезагрузить (отменить)",
		"test_won_notice": "Тест пройден! Дверь работает отлично.",
		"tool_platform": "Пол",
		"tool_trap_floor": "Ловушка",
		"tool_spikes": "Шипы",
		"tool_saw": "Пила",
		"tool_crusher": "Пресс",
		"tool_spring": "Пружина",
		"tool_fake_door": "Обманка",
		"tool_falling": "Обвал",
		"tool_laser": "Лазер",
		"tool_door": "Выход",
		"tool_player": "Игрок",
		"tool_circular_saw": "Круглая пила",
		"tool_spike_ball": "Шар с шипами",
		"tool_pop_up_spikes": "Выдвижные шипы"
	},
	
	"en": {
		# Title Screen
		"game_title": "WRONG WAY",
		"game_subtitle": "Arena of traps and trials",
		"btn_start": "START",
		
		# Main Menu
		"btn_play": "PLAY",
		"btn_level_select": "LEVEL SELECT",
		"btn_multiplayer": "MULTIPLAYER",
		"btn_leaderboard": "LEADERBOARD",
		"btn_settings": "SETTINGS",
		"btn_quit": "QUIT",
		"best_chip": "Best: %s",
		"best_stars": "Stars: %d / 60",
		"level_header": "LEVEL %d",
		"level_complete": "LEVEL COMPLETE",
		"great_job": "Great Job!",
		"last_record": "Best record: %s",
		"not_available": "None",
		"multiplayer_title": "MULTIPLAYER MODE",
		"multiplayer_desc": "1v1 Duel and Online Race modes coming soon!\n\nCurrently, Campaign levels are active.",
		"leaderboard_title": "LEADERBOARD",
		"leaderboard_desc": "Currently local records are tracked.\n\nYour overall best time:\n%s",
		"total_time": "Total Time: %ds",
		"leaderboard_total_stars": "Stars: %d",
		"leaderboard_total_time": "Total Time: %d seconds",
		"level_time_item": "Level %d: %s",
		"tab_global": "GLOBAL",
		"tab_friends": "FRIENDS",
		"player_you": "You",
		"leaderboard_guest_title": "Google Account Required",
		"leaderboard_guest_desc": "Sign in with Google to view Global and Friends rankings and sync your records.",
		"leaderboard_google_login_btn": "Sign in with Google",
		"leaderboard_google_connecting": "Connecting to Google...",
		"leaderboard_friends_empty": "No friends in the rankings yet. Play with friends to see them here.",
		
		# Settings Modal
		"settings_title": "SETTINGS",
		"setting_language": "Language:",
		"setting_music": "Background Music (BGM):",
		"setting_music_volume": "Music Volume:",
		"setting_sound": "Sound Effects (SFX):",
		"setting_sound_volume": "SFX Volume:",
		"setting_shake": "Screen Shake:",
		"status_on": "ON",
		"status_off": "OFF",
		"controls_title": "Controls & Keyboard:",
		"controls_desc": (
			"Movement: A / D or ◄ / ► (Touch D-Pad)\nJump: W / Space / ▲\n"
			+ "Dash: Shift / J\nQuick Restart: R\n"
			+ "Pause / Menu: Esc / P\nFullscreen: F11"
		),
		"controls_title_desktop": "Keyboard Controls:",
		"controls_desc_desktop": (
			"Move: A / D or ◄ / ►\nJump: W / Space / ▲\n"
			+ "Dash: Shift / J\nRestart: R  •  Pause: Esc / P  •  Fullscreen: F11"
		),
		"controls_title_mobile": "Touch Controls:",
		"controls_desc_mobile": (
			"Left / Right — Move  •  Jump  •  Dash\n"
			+ "Customize button positions and size to fit your hands."
		),
		"btn_close": "Close",
		"btn_customize_controls": "Customize Controls",
		"controls_customizer_title": "CUSTOMIZE CONTROLS",
		"controls_customizer_hint": "Drag buttons to your preferred positions",
		"customizer_size": "Size:",
		"btn_reset_default": "Reset Default",
		"offline_title": "No Internet Connection",
		"offline_desc": "Internet is required for Rankings and Google Sign-In. Campaign levels & Zone Creator work offline.",
		"btn_retry": "Retry",
		"exit_press_again": "Press back again to exit",
		"tut_step_move_mobile": "Tap ◄ / ► buttons to move",
		"tut_step_move_pc": "Press [A / D] or [◄ / ►] to move",
		"tut_step_jump_mobile": "Jump over the spikes!",
		"tut_step_jump_pc": "Press [SPACE] or [W] to jump over the spikes!",
		"tut_step_dash_mobile": "Tap DASH to boost across the gap!",
		"tut_step_dash_pc": "Press [SHIFT] or [J] to Dash across the gap!",
		"tut_step_door": "Earn at least 2 ★ stars (≤ 2 deaths) to unlock the next level!",
		"tut_trap_floor_toast": "Never trust the floor! 😈",
		
		# Level Select
		"map_title": "LEVELS",
		"chapter_1_title": "CHAPTER 1: LEVELS",
		"chapter_2_title": "CHAPTER 2: LEVELS",
		"chapter_3_title": "CHAPTER 3: LEVELS",
		"chapter_4_title": "CHAPTER 4: GOLDEN CANYON",
		"chapter_5_title": "CHAPTER 5: INFERNO ABYSS",
		"chapter_4_desc": "Desert and Canyon update coming soon!",
		"chapter_5_desc": "Lava and Volcano update coming soon!",
		"chapter_nav_btn": "CHAPTER %d",
		"coming_soon_caps": "COMING SOON",
		"more_levels_soon": "New levels will be available in the next update!",
		"chapter_2_locked": "CHAPTER 2 LOCKED",
		"chapter_2_unlock_req": "Collect at least 50 stars in Chapter 1 to unlock",
		"chapter_3_locked": "CHAPTER 3 LOCKED",
		"chapter_3_unlock_req": "Collect at least 55 stars in Chapter 2 to unlock",
		"btn_chapter_1": "CH. 1",
		"btn_chapter_2": "CH. 2",
		"btn_chapter_3": "CH. 3",
		"btn_back": "Back",
		"btn_menu": "Menu",
		"lvl_label": "LVL %d",
		"lvl_ad_unlock": "Unlock",
		"lvl_locked": "Locked",
		"total_stars": "%d / 180",
		"lock_title": "LEVEL LOCKED",
		"lock_need_attempt": "To unlock this level with an ad, try playing level %d first!",
		"lock_cooldown": "You can't unlock 2 levels in a row via ad (every other level).\n(Last unlocked: lvl %d. Next available: level %d)",
		"lock_need_stars": "To unlock this level, earn at least 2 stars on level %d!",
		"lock_must_open_earlier": "First unlock earlier levels!",
		"ad_loading_title": "LOADING AD",
		"ad_loading_msg": "Video ad is still loading — please try again in a moment!",
		"lvl_unlocked_title": "LEVEL UNLOCKED!",
		"lvl_unlocked_msg": "Level %d unlocked via rewarded ad!",
		"zone2_title": "ZONE 2: MISTY CASTLE",
		"zone2_req": "Requires 50 stars to unlock",
		"zone2_status": "%d / 50",
		
		# Game HUD
		"hud_level": "LEVEL %d",
		"hud_time": "%.2fs",
		"hud_deaths": "%d deaths",
		"btn_jump": "JUMP",
		"btn_dash": "DASH",
		"btn_hud_menu": "Menu",
		
		# Pause Modal
		"pause_title": "PAUSED",
		"btn_resume": "RESUME",
		"btn_restart": "Restart",
		"btn_map": "Map",
		"btn_home": "Main Menu",
		
		# Win Overlay
		"win_title": "LEVEL %d COMPLETED!",
		"win_3_stars": "Perfect run! Next level unlocked!",
		"win_2_stars": "Great job! Next level unlocked!",
		"win_1_star": "Earn at least 2 stars to unlock the next level!",
		"win_time": "Time: %.2fs",
		"win_deaths": "%d deaths",
		"win_stats": "Time: %ds   •   Deaths: %d",
		"win_all_60_complete": "ALL 60 LEVELS COMPLETED! 🎉\nCHAPTER 4 & 5 COMING SOON",
		"btn_next_lvl": "NEXT LEVEL",
		"btn_unlock_next_ad": "UNLOCK WITH AD",
		
		# Level & Trap Editor
		"btn_editor": "ZONE CREATOR",
		"editor_title": "ZONE & TRAP CREATOR",
		"btn_test": "PLAYTEST",
		"btn_stop_test": "RETURN TO EDIT",
		"btn_save": "SAVE",
		"btn_load": "LOAD",
		"btn_clear": "CLEAR",
		"btn_erase": "ERASER",
		"saved_notice": "Level saved successfully!",
		"cleared_notice": "Arena cleared!",
		"slot_label": "Slot %d",
		"slot_saved": "Saved",
		"slot_empty": "Empty",
		"loaded_notice": "Slot %d loaded!",
		"reloaded_notice": "Slot %d reloaded!",
		"btn_reload_current": "Reload (Revert)",
		"test_won_notice": "Playtest passed! Exit door reached.",
		"tool_platform": "Floor",
		"tool_trap_floor": "Trap Floor",
		"tool_spikes": "Spikes",
		"tool_saw": "Saw",
		"tool_crusher": "Crusher",
		"tool_spring": "Spring",
		"tool_fake_door": "Fake Door",
		"tool_falling": "Stalactite",
		"tool_laser": "Laser",
		"tool_door": "Exit Door",
		"tool_player": "Player",
		"tool_circular_saw": "Circular Saw",
		"tool_spike_ball": "Spike Ball",
		"tool_pop_up_spikes": "Pop-up Spikes"
	},
	
	"tr": {
		# Title Screen
		"game_title": "WRONG WAY",
		"game_subtitle": "Tuzaklar ve engeller arenası",
		"btn_start": "BAŞLA",
		
		# Main Menu
		"btn_play": "OYNA",
		"btn_level_select": "SEVİYELER",
		"btn_multiplayer": "ÇOK OYUNCULU",
		"btn_leaderboard": "LİDERLİK",
		"btn_settings": "AYARLAR",
		"btn_quit": "ÇIKIŞ",
		"best_chip": "Rekor: %s",
		"best_stars": "Yıldızlar: %d / 60",
		"level_header": "SEVİYE %d",
		"level_complete": "SEVİYE TAMAMLANDI",
		"great_job": "Harika iş!",
		"last_record": "En iyi rekor: %s",
		"not_available": "Yok",
		"multiplayer_title": "ÇOK OYUNCULU MOD",
		"multiplayer_desc": "1v1 Düello ve Çevrimiçi Yarış çok yakında!\n\nŞu anda Macera seviyeleri aktiftir.",
		"leaderboard_title": "LİDERLİK TABLOSU",
		"leaderboard_desc": "Şu anda yerel rekorlar kaydedilmektedir.\n\nEn iyi süreniz:\n%s",
		"total_time": "Toplam Süre: %ds",
		"leaderboard_total_stars": "Yıldızlar: %d",
		"leaderboard_total_time": "Toplam Süre: %d saniye",
		"level_time_item": "%d. Seviye: %s",
		"tab_global": "GLOBAL",
		"tab_friends": "ARKADAŞLAR",
		"player_you": "Sen",
		"leaderboard_guest_title": "Google Hesabı Gerekli",
		"leaderboard_guest_desc": "Global ve Arkadaşlar sıralamasını görmek ve rekorlarınızı kaydetmek için Google hesabınızla giriş yapın.",
		"leaderboard_google_login_btn": "Google ile giriş yap",
		"leaderboard_google_connecting": "Google'a bağlanılıyor...",
		"leaderboard_friends_empty": "Henüz sıralamada arkadaşınız yok. Arkadaşlarınızla oynayarak onları burada görün.",
		
		# Settings Modal
		"settings_title": "AYARLAR",
		"setting_language": "Dil (Language):",
		"setting_music": "Fon Müziği (BGM):",
		"setting_music_volume": "Müzik Düzeyi:",
		"setting_sound": "Ses Efektleri (SFX):",
		"setting_sound_volume": "Efekt Düzeyi:",
		"setting_shake": "Ekran Sarsıntısı:",
		"status_on": "AÇIK",
		"status_off": "KAPALI",
		"controls_title": "Kontroller ve Klavye:",
		"controls_desc": (
			"Hareket: A / D veya ◄ / ► (Dokunmatik)\nZıplama: W / Boşluk / ▲\n"
			+ "Hızlı Koşu (Dash): Shift / J\nHızlı Yeniden Başlat: R\n"
			+ "Menü / Duraklat: Esc / P\nTam Ekran: F11"
		),
		"controls_title_desktop": "Klavye Kontrolleri:",
		"controls_desc_desktop": (
			"Hareket: A / D veya ◄ / ►\nZıplama: W / Boşluk / ▲\n"
			+ "Hızlı Koşu (Dash): Shift / J\nYeniden Başlat: R  •  Duraklat: Esc / P  •  Tam Ekran: F11"
		),
		"controls_title_mobile": "Dokunmatik Kontroller:",
		"controls_desc_mobile": (
			"Sol / Sağ — Hareket  •  Zıpla  •  Atıl (Dash)\n"
			+ "Düğme konumlarını ve boyutunu kendinize göre ayarlayın."
		),
		"btn_close": "Kapat",
		"btn_customize_controls": "Tuşları Özelleştir",
		"controls_customizer_title": "TUŞLARI ÖZELLEŞTİR",
		"controls_customizer_hint": "Düğmeleri istediğiniz yere sürükleyin",
		"customizer_size": "Boyut:",
		"btn_reset_default": "Sıfırla",
		"offline_title": "İnternet Bağlantısı Yok",
		"offline_desc": "Sıralama ve Google girişi için internet gerekir. Seviyeler ve Bölge Oluşturucu çevrimdışı çalışır.",
		"btn_retry": "Tekrar Dene",
		"exit_press_again": "Çıkmak için tekrar basın",
		"tut_step_move_mobile": "Hareket etmek için ◄ / ► tuşlarına dokun",
		"tut_step_move_pc": "Hareket etmek için [A / D] veya [◄ / ►] tuşuna bas",
		"tut_step_jump_mobile": "Dikenlerin üzerinden zıpla!",
		"tut_step_jump_pc": "Dikenleri aşmak için [SPACE] veya [W] tuşuna bas!",
		"tut_step_dash_mobile": "Boşluğu geçmek için ATIL (DASH) tuşuna dokun!",
		"tut_step_dash_pc": "Boşluğu aşmak için [SHIFT] veya [J] ile Atıl!",
		"tut_step_door": "Sonraki seviye için en az 2 ★ yıldız kazan (≤ 2 ölüm)!",
		"tut_trap_floor_toast": "Asla zemine güvenme! 😈",
		
		# Level Select
		"map_title": "SEVİYELER",
		"chapter_1_title": "BÖLÜM 1: SEVİYELER",
		"chapter_2_title": "BÖLÜM 2: SEVİYELER",
		"chapter_3_title": "BÖLÜM 3: SEVİYELER",
		"chapter_4_title": "BÖLÜM 4: ALTIN KANYON",
		"chapter_5_title": "BÖLÜM 5: CEHENNEM ÇUKURU",
		"chapter_4_desc": "Çöl ve Kanyon güncellemesi çok yakında!",
		"chapter_5_desc": "Lav ve Volkan güncellemesi çok yakında!",
		"chapter_nav_btn": "BÖLÜM %d",
		"coming_soon_caps": "YAKINDA",
		"more_levels_soon": "Yeni seviyeler bir sonraki güncellemede sunulacak!",
		"chapter_2_locked": "2. BÖLÜM KİLİTLİ",
		"chapter_2_unlock_req": "Kilidi açmak için 1. bölümde en az 50 yıldız toplayın",
		"chapter_3_locked": "3. BÖLÜM KİLİTLİ",
		"chapter_3_unlock_req": "Kilidi açmak için 2. bölümde en az 55 yıldız toplayın",
		"btn_chapter_1": "BÖLÜM 1",
		"btn_chapter_2": "BÖLÜM 2",
		"btn_chapter_3": "BÖLÜM 3",
		"btn_back": "Geri",
		"btn_menu": "Menü",
		"lvl_label": "LVL %d",
		"lvl_ad_unlock": "Aç",
		"lvl_locked": "Kilitli",
		"total_stars": "%d / 180",
		"lock_title": "SEVİYE KİLİTLİ",
		"lock_need_attempt": "Bu seviyeyi reklamla açmak için önce %d seviyesini oynayın!",
		"lock_cooldown": "Art arda 2 seviye reklamla açılamaz (bir seviye arayla).\n(Son açılan: %d. seviye. Sıradaki: %d. seviye)",
		"lock_need_stars": "Bu seviyeyi açmak için %d seviyesinde en az 2 yıldız alın!",
		"lock_must_open_earlier": "Önce önceki seviyeleri açın!",
		"ad_loading_title": "REKLAM YÜKLENİYOR",
		"ad_loading_msg": "Video reklam henüz hazır değil, birazdan tekrar deneyin!",
		"lvl_unlocked_title": "SEVİYE AÇILDI!",
		"lvl_unlocked_msg": "%d. seviye reklam ile başarıyla açıldı!",
		"zone2_title": "BÖLGE 2: SİSLİ KALE",
		"zone2_req": "Açmak için 50 yıldız gerekli",
		"zone2_status": "%d / 50",
		
		# Game HUD
		"hud_level": "LEVEL %d",
		"hud_time": "%.2fs",
		"hud_deaths": "%d ölüm",
		"btn_jump": "ZIPLA",
		"btn_dash": "ATIL",
		"btn_hud_menu": "Menü",
		
		# Pause Modal
		"pause_title": "DURAKLATILDI",
		"btn_resume": "DEVAM ET",
		"btn_restart": "Yeniden Dene",
		"btn_map": "Harita",
		"btn_home": "Ana Menü",
		
		# Win Overlay
		"win_title": "%d. SEVİYE TAMAMLANDI!",
		"win_3_stars": "Kusursuz! Sonraki seviye açıldı!",
		"win_2_stars": "Harika! Sonraki seviye açıldı!",
		"win_1_star": "Sonraki seviyeyi açmak için en az 2 yıldız kazanın!",
		"win_time": "Süre: %.2fs",
		"win_deaths": "%d ölüm",
		"win_stats": "Süre: %ds   •   Ölüm: %d",
		"win_all_60_complete": "TÜM 60 SEVİYE TAMAMLANDI! 🎉\nBÖLÜM 4 VE 5 YAKINDA",
		"btn_next_lvl": "SONRAKİ SEVİYE",
		"btn_unlock_next_ad": "REKLAMLA AÇ",
		
		# Level & Trap Editor
		"btn_editor": "BÖLGE OLUŞTUR",
		"editor_title": "BÖLGE VE TUZAK DÜZENLEYİCİ",
		"btn_test": "TEST ET",
		"btn_stop_test": "DÜZENLEMEYE DÖN",
		"btn_save": "KAYDET",
		"btn_load": "YÜKLE",
		"btn_clear": "TEMİZLE",
		"btn_erase": "SİLGİ",
		"saved_notice": "Seviye başarıyla kaydedildi!",
		"cleared_notice": "Alan temizlendi!",
		"slot_label": "Slot %d",
		"slot_saved": "Kaydedildi",
		"slot_empty": "Boş",
		"loaded_notice": "Slot %d yüklendi!",
		"reloaded_notice": "Slot %d yeniden yüklendi!",
		"btn_reload_current": "Yeniden yükle (geri al)",
		"test_won_notice": "Test başarılı! Çıkış kapısına ulaşıldı.",
		"tool_platform": "Zemin",
		"tool_trap_floor": "Tuzak Zemin",
		"tool_spikes": "Diken",
		"tool_saw": "Testere",
		"tool_crusher": "Ezici",
		"tool_spring": "Yay",
		"tool_fake_door": "Sahte Kapı",
		"tool_falling": "Düşen Taş",
		"tool_laser": "Lazer",
		"tool_door": "Çıkış",
		"tool_player": "Oyuncu",
		"tool_circular_saw": "Döner Testere",
		"tool_spike_ball": "Dikenli Top",
		"tool_pop_up_spikes": "Tuzak Diken"
	}
}

func _ready() -> void:
	# Load language from SaveManager if available
	var sm = get_node_or_null("/root/SaveManager")
	if sm and "current_language" in sm:
		current_language = sm.current_language

func set_language(lang_code: String) -> void:
	if not LANGUAGES.has(lang_code):
		return
	current_language = lang_code
	var sm = get_node_or_null("/root/SaveManager")
	if sm and "current_language" in sm:
		sm.current_language = lang_code
		sm.save_data()
	language_changed.emit(lang_code)

func t(key: String, args: Array = []) -> String:
	var dict: Dictionary = STRINGS.get(current_language, STRINGS["uz"])
	var text: String = dict.get(key, key)
	if not args.is_empty():
		return text % args
	return text

# Convenience shorthand
func tr_text(key: String, args: Array = []) -> String:
	return t(key, args)

