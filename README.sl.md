# Makedam — Specifikacija zahtev

**Projekt:** Makedam — 2D dirkalna igra s pogledom od zgoraj, grafični slog po navdihu GTA 1/2
**Avtor:** Jernej Peter
**Repozitorij:** https://github.com/Jero009/makedam

---

## 1. Pregled projekta

Enoigralska 2D reli dirkalna igra s pogledom od zgoraj v vizualnem slogu iger Grand Theft Auto 1/2
(nizkoločljivostni pixel art spriti, ptičja perspektiva). Igralec vozi reli avtomobil po
makadamski oziroma peščeni hitrostni preizkušnji skozi podeželje in gozd, pri čemer v pravilnem
vrstnem redu prečka kontrolne točke (checkpoints) in tekmuje s časom. Časi krogov se beležijo;
cilj igre je doseči osebni rekord.

- **Pogonski sistem (Engine):** Godot 4.x (GDScript), Compatibility renderer (OpenGL — omogoča izvoz za splet)
- **Platforma:** namizni izvoz za Linux + Windows (spletni izvoz kot dodatni cilj)
- **Ekipa:** samostojni projekt

## 2. Funkcionalne zahteve

### FR1 — Igralcev avtomobil
- FR1.1: Igralec upravlja avtomobil s pospeševanjem, zaviranjem in zavijanjem (tipkovnica).
- FR1.2: Avtomobil ima arkadno fiziko drsenja (drift): vektor hitrosti zaostaja za smerjo
  obrnjenosti vozila, oprijem se pri zavijanju pri večjih hitrostih zmanjša.
- FR1.3: Avtomobil trči v drevesa, skale in ovire; trki ga upočasnijo.

### FR2 — Proga in kontrolne točke (checkpoints)
- FR2.1: Ena reli etapa, sestavljena iz tilemapa: vijugasta makadamska/peščena cesta skozi
  travnike, gozd in skale.
- FR2.2: 6–10 kontrolnih točk (checkpoints) v določenem vrstnem redu; naslednja kontrolna
  točka je vizualno označena.
- FR2.3: En krog = vse kontrolne točke v pravilnem vrstnem redu, nazaj do startno-ciljne črte.

### FR3 — Časovnik in točkovanje
- FR3.1: Časovnik kroga se sproži na ciljni črti in se prikazuje med igro (MM:SS.ms).
- FR3.2: Najboljši čas kroga se shrani med sejami (zapis v lokalno datoteko).
- FR3.3: Po vsakem krogu se prikažeta trenutni čas kroga in osebni rekord.

### FR4 — Potek igre
- FR4.1: Glavni meni: Začni dirko, Izhod, pregled upravljanja (kontrol).
- FR4.2: Tipka za ponovni zagon (restart) igralca takoj vrne na startno črto.
- FR4.3: Meni za premor (Esc): Nadaljuj, Ponovni zagon, Izhod v glavni meni.

### FR5 — Zvok (osnovno)
- FR5.1: Zvok motorja, katerega višina tona sledi hitrosti vozila.
- FR5.2: Zvočni signal (»ping«) ob prečkanju kontrolne točke (checkpoint) in zvok ob zaključku kroga.
- FR5.3: Zanka glasbe v ozadju (meni + igranje).

## 3. Grafične in zvočne zahteve

- **Slog:** videz GTA 1/2 — pixel art s ptičje perspektive, avtomobil velikosti ~32×16 px,
  omejena barvna paleta (manj kot ali enako 16 barv), umirjeni podeželski toni (travnato
  zelena, rjava barva makadama, sive skale, temno zelena barva gozda).
- **Ločljivost za igralca:** nizkoločljivostni pixel art, povečan z metodo nearest-neighbor
  (celoštevilska povečava brez zameglitve).
- **Potrebni grafični elementi (assets):** 1 reli avtomobil (4 stanja rotacije ali prosta
  rotacija), podeželski tileset (~8–12 ploščic: trava, makadamska cesta, pesek, drevesa,
  skale, bale sena), oznaka za checkpoint, pisava za uporabniški vmesnik (pixel font).
- **Orodja:** LibreSprite (pixel art), jsfxr (zvočni učinki SFX), brezplačna glasbena zanka
  (OpenGameArt / LMMS).

## 4. Tehnične zahteve

- TR1: Projekt v okolju Godot 4.x, izključno GDScript, brez plačljivih vtičnikov ali virov.
- TR2: Nadzor različic: git + GitHub (https://github.com/Jero009/makedam).
- TR3: Izvoz: preverjeno delujoči različici (build) za Linux (X11) in Windows.
- TR4: Vsi uporabljeni zunanji viri (third-party assets) so navedeni v datoteki CREDITS.
