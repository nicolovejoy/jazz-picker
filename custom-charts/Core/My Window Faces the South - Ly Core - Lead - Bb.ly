%% -*- Mode: LilyPond -*-

\include "../../lilypond-data/Include/lead-sheets.ily"

\header {
  title = "My Window Faces the South"
  subtitle = "Lead"
  poet = ""
  composer = "Jerry Livingston
Michael Parish
Abner Silver"
  copyright = \markup \small { \now " " }
}

refrainKey = bf

refrainChords = \chordmode {
  r2 bf1 bf1 bf1
  bf1 bf1 bf1 bf1:7
  bf1:7 ef1 ef1 bf1
  g1:7 c1:7 c1:7 f1:7
  f1:7 bf1 bf1 bf1
  bf1 bf1 bf1 bf1:7
  bf1:7 ef1 ef1 bf1
  g1:7 c1:7 f1:7 bf1
  bf1
}

refrainMelody = \relative f' {
  \time 4/4
  \key \refrainKey \major
  \clef \whatClef
  \tempo "Up Tempo" 4 = 200

  \partial 2
  f4 g4 |
  bf2 bf4 bf4 |
  bf4 f4 g2 |
  d1 |
  r4 f4 g4 a4 |
  \break
  bf2 c2 |
  bf2 f4 g4 |
  af2. r4 |
  r1 |
  \break
  r4 bf4 bf4 g4 |
  bf2 g4 bf4 |
  d2 bf4 g4 |
  g2. r4 |
  \break
  r4 bf4 bf4 g4 |
  bf2 g4 a4 |
  c4 a4 g4 f4 |
  f4. r8 f4 g4 |
  \break
  bf2 bf4 bf4 |
  bf4 f4 g2 |
  d1 |
  r4 f4 g4 a4 |
  \break
  bf2 c2 |
  bf2 f4 g4 |
  af2. r4 |
  r1 |
  \break
  r4 bf4 bf4 g4 |
  bf2 g4 bf4 |
  d2 bf4 g4 |
  g2. bf4 |
  \break
  d2 d2 |
  d4 f,2 g4 |
  bf1 |
  bf2. r4

  \bar "|."
}

\include "../../lilypond-data/Include/paper.ily"

\markup {
  % Leave a gap after the header
  \vspace #1
}

\include "../../lilypond-data/Include/refrain.ily"
