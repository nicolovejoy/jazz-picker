%% -*- Mode: LilyPond -*-

\include "../../lilypond-data/Include/lead-sheets.ily"

\header {
  title = "My Window Faces the South"
  subtitle = "Bass"
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

refrainMelody = \relative f, {
  \time 4/4
  \key \refrainKey \major
  \clef \whatClef
  \tempo "Up Tempo" 4 = 200

  \partial 2
  bf4 r4 |
  f4 r4 bf4 r4 |
  f4 r4 bf4 r4 |
  f4 r4 bf4 r4 |
  f4 r4 bf4 r4 |
  \break
  f4 r4 bf4 r4 |
  f4 r4 bf4 r4 |
  f4 r4 bf4 r4 |
  f4 r4 ef'4 r4 |
  \break
  a,4 r4 ef'4 r4 |
  a,4 r4 bf4 r4 |
  f4 r4 g4 r4 |
  d'4 r4 c4 r4 |
  \break
  f,4 r4 c'4 r4 |
  f,4 r4 f4 r4 |
  c'4 r4 f,4 r4 |
  c'4 r4 bf4 r4 |
  \break
  f4 r4 bf4 r4 |
  f4 r4 bf4 r4 |
  f4 r4 bf4 r4 |
  f4 r4 bf4 r4 |
  \break
  f4 r4 bf4 r4 |
  f4 r4 bf4 r4 |
  f4 r4 bf4 r4 |
  f4 r4 ef'4 r4 |
  \break
  a,4 r4 ef'4 r4 |
  a,4 r4 bf4 r4 |
  f4 r4 g4 r4 |
  d'4 r4 c4 r4 |
  \break
  f,4 r4 f4 r4 |
  c'4 r4 bf4 r4 |
  f4 r4 bf4 r4 |
  f4 r4

  \bar "|."
}

\include "../../lilypond-data/Include/paper.ily"

\markup {
  % Leave a gap after the header
  \vspace #1
}

\include "../../lilypond-data/Include/refrain.ily"
