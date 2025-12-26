%% -*- Mode: LilyPond -*-

\include "../../lilypond-data/Include/lead-sheets.ily"

\header {
  title = "My Window Faces the South (Rhythm)"
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

  r1 |
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  \break
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  \break
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  \break
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  \break
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  \break
  b4 b4 b4 b4 |
  b4 b4 b4 b4 |
  b4 b4 b4 b4

  \bar "|."
}

\include "../../lilypond-data/Include/paper.ily"

\markup {
  % Leave a gap after the header
  \vspace #1
}

\include "../../lilypond-data/Include/refrain.ily"
