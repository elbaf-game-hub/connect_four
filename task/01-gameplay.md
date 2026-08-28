# 01 — Gameplay

## Rules summary

Drop tokens, line up four.

> Full rules: https://en.wikipedia.org/wiki/Connect_Four

## Controls

Tap a column header to drop a token. AI opponent is single-player.

## Screen flow

1. Mode select (1P vs AI, 2P local)
2. Game (board + turn indicator + restart)
3. Win / draw dialog with 'New game'

## Difficulty

AI depth 4 default (toggleable: Easy depth 2, Hard depth 6).

## Scoring

Win streak count per side, persisted.

## State machine

The game moves through these states: **playing, won, draw**.

```
      ┌──────────────┐
      │   playing    │
      └──┬───┬───┬───┘
         │   │   │
         │   │   └──► won
         └──────────► draw
```
