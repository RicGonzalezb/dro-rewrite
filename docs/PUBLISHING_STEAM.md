# Publishing to Steam Workshop

I can't run this for you — it requires the **Arma 3 Tools** (Publisher) app and Steam on your machine. This is the full procedure plus a pre-flight checklist. Do the checklist first; two items below are currently missing from the mission and will hurt the Workshop listing if you skip them.

---

## Pre-flight checklist

- [ ] **Mission runs clean.** Test in the editor and in a hosted MP session with only **CBA_A3** loaded (then again with ACE/LAMBS if you play with them). Watch the `.rpt` for errors.
- [ ] **Add an MP `Header`** to `description.ext`. It currently has **none**, so the mission won't advertise player count / game type in the MP browser. The mission has **15 playable slots**. Paste this near the top of `description.ext` (after the `#include` lines):

  ```cpp
  class Header
  {
      gameType   = "Coop";   // or "CTI"/"Unknown"; Coop fits DRO
      minPlayers = 1;
      maxPlayers = 15;
  };
  ```

- [ ] **Add overview metadata** to `description.ext` (also currently missing) so the scenario shows a name, blurb, and image in the Scenarios list:

  ```cpp
  author         = "mbrdmn (original) / R. Gonzalez (Rewrite)";
  onLoadName     = "Dynamic Recon Ops — Rewrite (Livonia)";
  onLoadMission  = "Dynamic special-ops. Requires CBA_A3.";
  overviewText   = "Randomized recon operations. Requires CBA_A3; ACE3 and LAMBS optional.";
  overviewPicture = "images\recon_image_notext.jpg";
  loadScreen     = "images\recon_image_notext.jpg";
  ```

- [ ] **Confirm the mod list** for the Workshop description: **CBA_A3** required. List **ACE3** and **LAMBS Danger** as *optional* (soft-compatible).
- [ ] **Prepare a preview image** (`images\recon_image.jpg` works; Workshop wants ~512×512+).
- [ ] **Decide the license / attribution** — see [LICENSE](../LICENSE). This is a derivative of mbrdmn's DRO; credit the original author in the Workshop description.

---

## Method A — pack a `.pbo` and upload (recommended for MP scenarios)

MP scenarios are distributed as a `.pbo` whose name ends with the world suffix.

1. **Name the folder correctly.** The packed folder must be named `Dynamic Recon Ops ACE - Livonia.Enoch` (the `.Enoch` suffix is the world). If your working copy shows URL-encoded characters in the path (`%20`, `%2e`), copy it out to a clean folder named literally `Dynamic Recon Ops ACE - Livonia.Enoch` before packing.
2. **Pack it.** Open **Arma 3 Tools → Addon Builder** (or use `BankRev`/`MakePbo` from the tools). Source = the mission folder; Destination = a build folder. This produces `Dynamic Recon Ops ACE - Livonia.Enoch.pbo`.
   - Exclude the internal docs from the pbo (`*.md`) — they don't belong in the shipped mission. Add `*.md` to the Addon Builder exclusion list, or pack from a copy with the `.md` files removed.
3. **Upload.** Open **Arma 3 Tools → Publisher**:
   - *New* item → point it at the folder or the `.pbo`.
   - Set **Title**, **Description** (include the required-mods list and credit), **Tags** (e.g. `Scenario`, `Coop`), **Visibility** (start with *Private* or *Friends only* to test).
   - Set the **preview image**.
   - **Upload.**
4. **Verify.** Subscribe from your own account, confirm it appears under *Scenarios / MP*, launches with the required mods, and shows the correct player count.
5. **Go public** once you've confirmed it works, and paste the required-mod dependencies into the Workshop item so subscribers get prompted.

## Method B — upload the mission folder directly

The Publisher can also upload an unpacked mission folder. Same steps as A but skip the Addon Builder pack and point Publisher at the mission folder. Packing (Method A) is cleaner because it keeps internal `.md` files and any `_archive/` out of the shipped item and loads faster.

---

## After publishing

- **Updating:** re-open the item in Publisher, point at the new build, and *Update*. Add **change notes** each time.
- **Dependencies:** in the Workshop item page, add CBA_A3 as a required item so Steam links it (ACE3 and LAMBS are optional — mention them in the description rather than as hard dependencies).
- **Keep the GitHub repo as source of truth**; the Workshop item is the built artifact. Tag a release in git that matches each Workshop update so you can reproduce any published version.

---

## What I can and can't do

I can prepare the mission for packing (add the `Header`/overview snippets above, clean up files, write the Workshop description text). I **cannot** run Addon Builder or the Publisher, or upload to Steam — those need the desktop tools and your Steam login. Ask me if you want me to apply the `Header`/overview edits to `description.ext` and draft the Workshop description copy.
