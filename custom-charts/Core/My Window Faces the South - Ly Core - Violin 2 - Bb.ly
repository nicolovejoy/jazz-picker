%% -*- Mode: LilyPond -*-

\include "../../lilypond-data/Include/lead-sheets.ily"

\header {
  title = "My Window Faces the South (Violin 2)"
  subtitle = \instrument
  poet = ""
  composer = "Jerry Livingston
Michael Parish
Abner Silver"
  copyright = \markup \small { \now " " }
}

refrainKey = bf

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
  bf'2 f4 d4 |
  d2. g4 |
  bf2 bf2 |
  bf4 a2 f4 |
  \break
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
