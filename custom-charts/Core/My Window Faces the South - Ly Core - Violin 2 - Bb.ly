%% -*- Mode: LilyPond -*-

\include "../../lilypond-data/Include/lead-sheets.ily"

\header {
  title = "My Window Faces the South"
  subtitle = "Violin 2"
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
  d4 ef4 |
  f2 f4 f4 |
  f4 c4 d2 |
  bf1 |
  r4 d4 d4 ef4 |
  \break
  f2 g2 |
  f2 d4 ef4 |
  f2 f4. r8 |
  r1 |
  \break
  r4 d4 d4 bf4 |
  d2 bf4 d4 |
  bf'2 f4 d4 |
  d2. r4 |
  \break
  r4 d4 d4 bf4 |
  d2 bf4 c4 |
  ef4 c4 bf4 a4 |
  a4. r8 a4 bf4 |
  \break
  f'2 f4 f4 |
  f4 c4 d2 |
  bf1 |
  r4 d4 d4 ef4 |
  \break
  f2 g2 |
  f2 d4 ef4 |
  f2 f4. r8 |
  r1 |
  \break
  r4 d4 d4 bf4 |
  d2 bf4 d4 |
  bf'2 f4 d4 |
  d2. g4 |
  \break
  bf2 bf2 |
  bf4 a2 f4 |
  g1 |
  g2. r4

  \bar "|."
}

\include "../../lilypond-data/Include/paper.ily"

\markup {
  % Leave a gap after the header
  \vspace #1
}

\include "../../lilypond-data/Include/refrain.ily"
