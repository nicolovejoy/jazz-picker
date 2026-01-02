# Vision

## Proposed Rebrand: MusicForge

**Tagline candidates:**
- "Craft your charts"
- "Professional charts, your key"
- "Forged for the gig"

**Why MusicForge:**
- Emphasizes the craftsmanship angle (LilyPond engraving quality)
- "Forge" implies precision, durability, professional tools
- Distinctive - less likely to conflict with existing apps
- Works for the broader scope (not just jazz)

**Alternative considered:** AnyKey ("Your key to playing in tune") - clever wordplay on transposition, but sounds generic.

**Domain:** musicforge.org (Cloudflare)

---

## Brand Migration Plan

### Phase 1: Domain Setup (now)
- [x] Register musicforge.org on Cloudflare
- [ ] Point musicforge.org → Vercel (same deployment as jazzpicker.pianohouseproject.org)
- [ ] Keep jazzpicker.pianohouseproject.org working (redirect later)

### Phase 2: App & Backend
- [ ] Rename iOS app display name to "MusicForge"
- [ ] Update App Store listing
- [ ] Add musicforge:// URL scheme (keep jazzpicker:// for backwards compat)
- [ ] Rename Fly.io app: jazz-picker → musicforge (or add api.musicforge.org alias)

### Phase 3: Cleanup
- [ ] Redirect jazzpicker.pianohouseproject.org → musicforge.org
- [ ] Update GitHub repo name (optional - causes link breakage)
- [ ] Update Firebase project name (optional - internal only)

### Domain Notes

**Cloudflare vs GoDaddy:**
- You can use Cloudflare for DNS without transferring the domain registration
- "Adding to Cloudflare" = pointing nameservers to Cloudflare (GoDaddy still owns registration)
- Domain transfers have 60-day lock after registration (not 1 year)
- For now: keep registration at GoDaddy, use Cloudflare for DNS management

**Current state:**
- pianohouseproject.org: GoDaddy registration, Cloudflare DNS
- musicforge.org: Cloudflare registration + DNS

Pending feedback from Eric and James on name.

---

## What It Is

A real-time, transposition-aware, ensemble-first music stand.

**One sentence:** "Any chart, in your key, synced with your band."

---

## Scope

Not jazz-specific. Any music using charts: jazz, worship, theater pits, big bands.

---

## Origin

- **Eric**: LilyPond chart library (750+ songs)
- **Nico**: Needed setlists that survive source updates + auto-transposition. forScore broke on every update.
- **James**: Multi-part arrangements with real-time transposition across instrumentations

---

## Tenets

1. **Gig-ready first** - Features must survive live performance pressure
2. **Transposition is invisible** - Right chart, right key, automatically
3. **The band is the unit** - Ensemble coordination is the differentiator
4. **Notation quality matters** - Professional engraving via LilyPond
5. **Offline is not optional** - Must work with no signal
6. **Speed over features** - Seconds to access, not minutes

---

## Open Questions for Eric & James

- Books vs. setlists - is a book just a named setlist, or something more?
- One-sentence description you'd use at a gig?
