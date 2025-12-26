%% -*- Mode: LilyPond -*-

\include "../../lilypond-data/Include/lead-sheets.ily"

\header {
  title = "My Window Faces the South"
  subtitle = "Clean Electric Guitar"
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

refrainMelody = \relative f {
  \time 4/4
  \key \refrainKey \major
  \clef \whatClef
  \tempo "Up Tempo" 4 = 200

  \partial 2
  <bf, g' d' f>4 <bf g' d' f>4 |
  <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 |
  <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 |
  <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 |
  <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 |
  \break
  <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 |
  <bf g' d' f>4 <bf g' d' f>4 <bf af' d' f>4 <bf af' d' f>4 |
  <bf af' d' f>4 <bf af' d' f>4 <bf af' d' f>4 <bf af' d' f>4 |
  <bf af' d' f>4 <bf af' d' f>4 <bf g' c g'>4 <bf g' c g'>4 |
  \break
  <bf g' c g'>4 <bf g' c g'>4 <bf g' c g'>4 <bf g' c g'>4 |
  <bf g' c g'>4 <bf g' c g'>4 <bf g' d' f>4 <bf g' d' f>4 |
  <bf g' d' f>4 <bf g' d' f>4 <g f' b d>4 <g f' b d>4 |
  <g f' b d>4 <g f' b d>4 <g e' bf c>4 <g e' bf c>4 |
  \break
  <g e' bf c>4 <g e' bf c>4 <g e' bf c>4 <g e' bf c>4 |
  <g e' bf c>4 <g e' bf c>4 <f ef' a c>4 <f ef' a c>4 |
  <f ef' a c>4 <f ef' a c>4 <f ef' a c>4 <f ef' a c>4 |
  <f ef' a c>4 <f ef' a c>4 <bf g' d' f>4 <bf g' d' f>4 |
  \break
  <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 |
  <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 |
  <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 |
  <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 |
  \break
  <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 <bf g' d' f>4 |
  <bf g' d' f>4 <bf g' d' f>4 <bf af' d' f>4 <bf af' d' f>4 |
  <bf af' d' f>4 <bf af' d' f>4 <bf af' d' f>4 <bf af' d' f>4 |
  <bf af' d' f>4 <bf af' d' f>4 <bf g' c g'>4 <bf g' c g'>4 |
  \break
  <bf g' c g'>4 <bf g' c g'>4 <bf g' c g'>4 <bf g' c g'>4 |
  <bf g' c g'>4 <bf g' c g'>4 <bf g' d' f>4 <bf g' d' f>4 |
  <bf g' d' f>4 <bf g' d' f>4 <g f' b d>4 <g f' b d>4 |
  <g f' b d>4 <g f' b d>4 <g e' bf c>4 <g e' bf c>4 |
  \break
  <g e' bf c>4 <g e' bf c>4 <f ef' a c>4 <f ef' a c>4 |
  <f ef' a c>4 <f ef' a c>4 <bf af' d' f>4 <bf af' d' f>4 |
  <bf af' d' f>4 <bf af' d' f>4 <bf af' d' f>4 <bf af' d' f>4 |
  <bf af' d' f>4 <bf af' d' f>4

  \bar "|."
}

\include "../../lilypond-data/Include/paper.ily"

\markup {
  % Leave a gap after the header
  \vspace #1
}

\include "../../lilypond-data/Include/refrain.ily"
