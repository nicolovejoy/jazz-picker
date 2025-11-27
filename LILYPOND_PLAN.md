# LilyPond Integration Plan

## How Eric's System Works

**Three-layer architecture:**

1. **Core files** (`Core/*.ly`) - The actual music (melody, chords, lyrics) in a reference key
2. **Include files** (`Include/*.ily`) - Shared logic for transposition, layout, styling
3. **Wrapper files** (`Wrappers/*.ly`) - Set variables and include the core:

```lilypond
instrument = "Bb for Standard Key"
whatKey = b           % Target key
whatClef = "treble"   % or "bass"

\include "../Core/502 Blues - Ly Core - Am.ly"
```

**The magic:** `refrain.ily` contains `\transpose \refrainKey \whatKey` which transposes from the reference key to any target key.

---

## Integration Options

### Option 1: Run LilyPond Directly on Fly.io

**How:** Install LilyPond in the Docker container, generate PDFs on demand.

**Pros:**
- Simple architecture (one service)
- Full control over LilyPond version
- Can use Eric's exact Include files

**Cons:**
- LilyPond is ~200MB+ (larger Docker image)
- CPU-intensive compilation (~2-5 seconds per PDF)
- Fly.io may time out on slow compilations

**Implementation:**
```dockerfile
# Add to Dockerfile.prod
RUN apt-get update && apt-get install -y lilypond
COPY lilypond-data /app/lilypond-data
```

---

### Option 2: Separate LilyPond Microservice

**How:** Run [lilypond-api](https://github.com/GGracieux/lilypond-api) or similar as a separate service.

**Pros:**
- Isolates heavy compilation from API server
- Can scale independently
- Pre-built Docker images available

**Cons:**
- More complex deployment (2 services)
- Network latency between services
- May need to adapt Eric's includes

**Docker images available:**
- [codello/docker-lilypond](https://github.com/codello/docker-lilypond) - Clean, multi-version
- [GGracieux/lilypond-api](https://github.com/GGracieux/lilypond-api) - REST API ready
- [chilledgeek/lilypond-web](https://github.com/chilledgeek/lilypond-web) - Web interface

---

### Option 3: AWS Lambda + S3 (Serverless)

**How:** Lambda function compiles LilyPond, stores PDF in S3, returns URL.

**Pros:**
- Pay only for actual compilations
- Scales to zero when idle
- S3 caches generated PDFs

**Cons:**
- Lambda has 250MB limit (LilyPond is borderline)
- Cold starts (~10s first invocation)
- More AWS complexity

---

### Option 4: Pre-generate on Catalog Build

**How:** Generate all key combinations during `build_catalog.py`, upload to S3.

**Pros:**
- Instant PDF delivery (already compiled)
- No runtime dependencies
- Simple frontend

**Cons:**
- 735 songs × 12 keys × 4 instruments = ~35,000 PDFs
- ~50GB+ storage
- Long build times
- Wasteful for rarely-used combinations

---

## Recommendation: Option 1 (Start Simple)

**Phase 1: Proof of concept**
1. Add LilyPond to Docker image
2. Create `/api/generate` endpoint that accepts: `{song, key, clef}`
3. Generate wrapper on-the-fly, compile, return PDF
4. Cache generated PDFs in S3 for reuse

**Phase 2: Optimize**
- Add Redis/memory cache for hot PDFs
- Background job queue for slow compilations
- Progress indicator in UI

**Phase 3: If needed**
- Split into microservice (Option 2) if Fly.io struggles

---

## API Design (Draft)

```
POST /api/v2/generate
{
  "song": "502 Blues",
  "key": "c",           // Target key (LilyPond notation)
  "clef": "treble",     // or "bass"
  "instrument": "Bb"    // For display/subtitle
}

Response:
{
  "url": "https://s3.../generated/502-blues-c-treble.pdf",
  "cached": false,
  "generation_time_ms": 2340
}
```

---

## Questions for Eric

1. Should we support all 12 keys, or a curated list?
2. Do you want to preserve the "famous singer keys" as presets?
3. Any songs with special requirements (multiple core files, unusual includes)?
4. Acceptable generation time? (2-5 seconds typical)

---

## Sources

- [codello/docker-lilypond](https://github.com/codello/docker-lilypond) - Docker images
- [GGracieux/lilypond-api](https://github.com/GGracieux/lilypond-api) - REST API
- [chilledgeek/lilypond-web](https://github.com/chilledgeek/lilypond-web) - Web service
- [jeandeaual/docker-lilypond](https://github.com/jeandeaual/docker-lilypond/) - With fonts
