# Wrong Way — Game Design & Technical Architecture Document

## 1. O‘yin mahsuloti (Product Overview)

| Bo‘lim | Qaror |
| :--- | :--- |
| **Nomi** | **Wrong Way** |
| **Janr** | Competitive 2D trap-platformer |
| **Asosiy maqsad** | Qisqa, ayyor, ammo adolatli zonalardan chiqish |
| **Farqi** | Global leaderboard, ghost race, multiplayer, community zone editor |
| **Platformalar** | Desktop avval; mobil boshqaruv keyin yoki bir vaqtda |
| **Vizual uslub** | To‘liq original: nom, qahramon, level, trap, ovoz va assetlar nusxa bo‘lmaydi |

---

## 2. Funksiyalar ustuvorligi (Feature Priorities)

| Qavat | Majburiy funksiyalar |
| :--- | :--- |
| **Core game** | Harakat, sakrash, o‘lim, tez respawn, checkpoint, finish, traplar |
| **Campaign** | Dunyo xaritasi, level unlock, progress save, 40–60 original level |
| **Competition** | Vaqt, o‘limlar soni, personal best, per-level va global leaderboard |
| **Social** | Profil, nickname, friend list, ghost replay, daily challenge |
| **Multiplayer** | 1v1 duel, async ghost race, keyin 2–8 online race va co-op |
| **Creator** | Zone editor, test, publish, like, report, featured zones |
| **Live operations** | Season, cosmetic reward, daily/weekly event, analytics, moderatsiya |

---

## 3. Arxitektura (System Architecture)

| Qism | Javobgarligi | Qoidasi |
| :--- | :--- | :--- |
| **GameApp** | Ilova holati, sozlamalar, autentifikatsiya, sahna yuklash | Gameplay logikasini o‘ziga yig‘masin |
| **GameSession** | Bitta urinish: timer, deaths, checkpoint, finish | Leaderboardga yuboriladigan yagona ishonchli manba |
| **LevelSystem** | Level yuklash, level versiyasi, spawn/finish | Level ma’lumotlari koddan ajratilgan bo‘lsin |
| **PlayerController** | Input, movement, jump, death state | UI, server yoki level progression’ni boshqarmasin |
| **TrapSystem** | Barcha traplarning umumiy lifecycle’i | Har trap bir xil interfeysga amal qilsin |
| **ReplaySystem** | Input/eventlarni yozish va ghost ko‘rsatish | Natijani o‘zgartira olmasin |
| **LeaderboardSystem** | Natija jo‘natish, olish, cache | Client natijasiga ko‘r-ko‘rona ishonmasin |
| **MultiplayerSystem** | Lobby, room, synchronisation, reconnect | Gameplay state server tekshiruviga ega bo‘lsin |
| **ZoneEditor** | Yaratish, test, saqlash, publish | O‘yinchi kod yoki tashqi fayl yuklay olmasin |
| **UI** | Menyu, HUD, result, ranking | Game logic’dan signal/event orqali ma’lumot olsin |
| **Audio/VFX** | Ovoz, effekt, feedback | Gameplay qarorlariga ta’sir qilmasin |

---

## 4. Loyiha tuzilmasi (Project Directory Structure)

```text
scenes/
  app/           # Game root, scene loader, splash, transitions
  menu/          # Main menu, level select, settings, profile
  gameplay/      # Core gameplay loop, HUD overlay, camera rig
  levels/        # Level scenes (layout & configurations only)
  multiplayer/   # Lobby, match room, duel arena
  editor/        # Zone editor canvas, toolbars, inspector
  ui/            # Shared UI components, dialogs, buttons, toasts

scripts/
  core/          # AppManager, SaveSystem, ConfigManager
  gameplay/      # GameSession, PlayerController, Checkpoint, Finish
  traps/         # TrapBase interface and standard implementations
  systems/       # LevelSystem, ReplaySystem, LeaderboardSystem
  network/       # NetworkManager, DuelSession, GhostSync
  editor/        # EditorController, ZoneSerializer, Validator
  ui/            # BaseMenu, HUDView, LeaderboardView

resources/
  level_data/    # Custom LevelData resources (.tres)
  trap_configs/  # Trap configuration definitions
  themes/        # UI themes, color palettes, fonts
  cosmetics/     # Skins, trails, death effects

tests/
  gameplay/      # Physics, movement, checkpoint, jump-gap tests
  leaderboard/   # Score verification and validation tests
  multiplayer/   # Sync, latency compensation, duel rules tests

assets/
  art/           # Original sprites, vector graphics, icons
  audio/         # SFX, ambient loops, music
  fonts/         # Licensed/original typography
```

> **Qoida:** Har bir level sahnasi faqat joylashuv va konfiguratsiyani saqlaydi. Trap, player, ranking yoki UI logikasi level fayliga yozilmaydi.

---

## 5. Gameplay qoidalari (Gameplay Rules)

* **O‘lim:** Juda tez feedback va 0.5–1 soniyadan qisqa retry.
* **Trap:** Har o‘limdan keyin sabab tushunarli bo‘lishi kerak (adolatli trolling).
* **Checkpoint:** Uzun yoki murakkab zonalarda beriladi.
* **Finish:** Faqat ishonchli collision/event orqali yakunlanadi.
* **Level:** Har level bitta yangi g‘oya o‘rgatadi, keyingisi uni kombinatsiyalaydi.
* **Qiyinlik:** “Impossible” emas; yaxshi o‘yinchi amaliyot bilan o‘ta olishi shart.
* **Tasodif:** Competitive rejimlarda random element seed bilan qayta tiklanadigan bo‘lsin.

---

## 6. Trap standartlari (Trap Standards & Lifecycle)

Har bir trap quyidagi umumiy tuzilishga ega bo‘lishi shart:

| Maydon | Mazmuni |
| :--- | :--- |
| **ID** | Noyob trap turi (`trap_falling_floor`, `trap_spike_wall`, va h.k.) |
| **Config** | Tezlik, damage, trigger radius, cooldown kabi parametrlar (Resource) |
| **State** | `IDLE`, `ARMED`, `ACTIVE`, `RESET` holatlari |
| **Trigger** | Player proximity/step/jump, timer, button yoki global event |
| **Reset** | Retry/checkpointdan keyin toza boshlang‘ich holatga qaytish |
| **Visual/Audio** | Gameplay kodidan ajralgan feedback qatlami |
| **Editor metadata** | Icon, kategoriya, joylashtirish chegarasi, qoidalar |

> **Qoida:** Traplar bir-biridan nusxa ko‘chirib yaratilmasin; umumiy `TrapBase` interfeysi orqali ishlasin.

---

## 7. Leaderboard qoidalari (Leaderboard System)

| Jadval | Saralash tartibi |
| :--- | :--- |
| **Speedrun** | Eng tez vaqt (`time_ms`) → kamroq o‘lim (`deaths`) |
| **Perfect Run** | Eng kam o‘lim (`deaths`) → eng tez vaqt (`time_ms`) |
| **Daily Challenge** | Kunlik bir xil level bo‘yicha natija |
| **Season** | Mavsum davomida yig‘ilgan umumiy ball |
| **Community Zone** | Har zona uchun vaqt va o‘limlar rekordi |
| **Creator** | Like, play, completion rate va featured statistikasi |

### Natija yozuvi formati:
Har bir rekord quyidagi ma’lumotlarni o‘z ichiga oladi:
* `player_id`: O‘yinchi identifikatori
* `level_id`: Daraja ID si
* `level_version`: Daraja versiyasi
* `time_ms`: Sarflangan vaqt (millisekundda)
* `deaths`: O‘limlar soni
* `completed_at`: Sana va vaqt
* `game_version`: O‘yin versiyasi
* `verification_status`: Natijaning haqiqiyligi (anti-cheat statusi)

> **Muhim qoida:** Level yangilansa eski rekordlar yangi versiya reytingi bilan aralashmasin (`level_version` bo‘yicha ajratiladi).

---

## 8. Anti-cheat va adolat (Fair Play & Security)

| Xavf | Himoya chorasi |
| :--- | :--- |
| **Soxta vaqt** | Server/Sessionda minimal mumkin bo‘lgan nazariy vaqt va harakat validatsiyasi |
| **O‘lim sonini almashtirish** | Natijani to‘g‘ridan-to‘g‘ri `GameSession`dan avtomatik olish |
| **Levelni o‘zgartirib rekord olish** | `level_version` va level layout checksum (hash) tekshiruvi |
| **Replay soxtalashtirish** | Replay eventlari va yakuniy natijani deterministik tekshirish |
| **Multiplayer lag** | Server-authoritative natija, reconnect va timeout qoidalari |
| **Toxic nickname/zone** | Filter, report, moderation queue va ban tizimi |

---

## 9. Multiplayer tartibi (Multiplayer Modes)

1. **Ghost Race (1-bosqich):** Boshqa o‘yinchining yozib olingan runi bilan asinxron poyga.
2. **Duel (2-bosqich):** 1v1 to‘g‘ridan-to‘g‘ri bahs (5 raunddan 3 tasini yutish qoidasi).
3. **Online Race:** 2–8 o‘yinchi, bir xil level, real vaqt rejimi.
4. **Co-op:** Ikki o‘yinchi tugma, platforma va kalitlar bilan hamkorlikda o‘tishi.
5. **Spectator:** Marraga yetgan o‘yinchilar qolganlarni jonli kuzatishi.

> **Rivojlanish tartibi:** Avval Ghost Race va Duel tayyor bo‘ladi. Ular stabil bo‘lgandan keyin katta online roomlar qo‘shiladi.

---

## 10. Community Zone Editor (Tahrirchi)

| Bosqich | Qoida |
| :--- | :--- |
| **Create** | Faqat ruxsat etilgan block va traplar palitrasi |
| **Test** | Muallif publishdan oldin yaratgan zonasini **o‘zi boshidan oxirigacha o‘tib berishi shart** |
| **Validate** | Obyektlar soni, xarita o‘lchami, unumdorlik (FPS) va finish mavjudligi tekshiriladi |
| **Publish** | Nom, tag, qiyinlik darajasi va avtomatik preview snapshot bilan e’lon qilinadi |
| **Discover** | Search, tag, trending, newest, featured bo‘limlari |
| **Feedback** | Like, favorite, report, completion rate statistikasi |
| **Moderation** | Shikoyat tushgan zonalar avtomatik yashiriladi va moderatsiyaga yuboriladi |

---

## 11. Kod sifati qoidalari (Engineering Rules for AI Agent)

1. **Bitta vazifa (Single Responsibility):** Har script faqat bitta aniq javobgarlikka ega bo‘lsin.
2. **Script hajmi:** Juda katta “God script” yaratmasin; ixcham modullarga ajratsin.
3. **Magic number:** Tezlik, vaqt, radius kabi barcha qiymatlar config/resource’da bo‘lsin.
4. **Typing:** Funksiya argumentlari, qaytish qiymatlari (`-> void`, `-> bool`) va state’lar doimo qat’iy tiplangan (`typed`) bo‘lsin.
5. **Eventlar (Loose Coupling):** Tizimlar signal/event orqali bog‘lansin; chuqur node-path bog‘liqliklari cheklansin.
6. **Error handling:** Tarmoq, save va scene load xatolari tushunarli tarzda ushlanib boshqarilsin.
7. **Duplicate code:** Takrorlangan kod umumiy helper yoki base componentga o‘tkazilsin.
8. **Comment:** “Nima qiladi” emas, faqat “nega shunday qilinganini” (arxitekturaviy sababni) izohlash.
9. **Test:** Har yangi trap, scoring, save/load va ranking uchun test checklist tayyor bo‘lsin.
10. **Logging:** Development rejimida aniq log; release rejimida keraksiz log bo‘lmasin.
11. **Backward compatibility:** Save, replay va level versiyalari buzilmasligi kafolatlansin.
12. **Commit / Bosqichlar:** Har bir funksiya alohida, kichik va tekshirish oson bo‘lgan bosqichlarda amalga oshirilsin.

---

## 12. Tayyorlik mezonlari (Definition of Done)

* **Core gameplay:** O‘yinchi bloklanmasdan boshlaydi, harakatlanadi, o‘ladi, tezda respawn bo‘ladi va levelni tugatadi.
* **Trap:** Trigger, reset, collision, visual va audio to‘g‘ri ishlaydi, umumiy interfeysga mos.
* **Level:** Boshidan oxirigacha o‘tiladi, softlock yoki nohaq o‘lim yo‘q.
* **Leaderboard:** Natija saqlanadi, tartib to‘g‘ri, anti-cheat tekshiruvi mavjud.
* **Multiplayer:** Disconnect, reconnect, ping va yutuvchi holati to‘g‘ri sinovdan o‘tgan.
* **Zone editor:** Yaratilgan zona muallif tomonidan test qilinmasdan publish bo‘lmaydi.
* **Reliz:** Crash, progress yo‘qolishi va o‘yinni buzuvchi xatolar mavjud emas.
