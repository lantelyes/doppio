<p align="center">
  <img src="docs/assets/hero.png" width="880" alt="Doppio: keep your Mac awake. Its menu shows Awake, 30 min left, and a list of durations.">
</p>

# Doppio

[![Release](https://img.shields.io/github/v/release/lantelyes/doppio)](https://github.com/lantelyes/doppio/releases/latest)
[![CI](https://github.com/lantelyes/doppio/actions/workflows/ci.yml/badge.svg)](https://github.com/lantelyes/doppio/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/github/license/lantelyes/doppio)](LICENSE)
![macOS 14 or later](https://img.shields.io/badge/macOS-14%2B-informational)

Doppio is a small menu bar app that keeps your Mac from falling asleep. Click the cup to turn it on, click it again to turn it off, or right-click to set a timer.

**[Download Doppio 1.0.1](https://github.com/lantelyes/doppio/releases/download/v1.0.1/Doppio-1.0.1.zip)** · [Website](https://lantelyes.github.io/doppio/)

## What it does

- Left-click the cup to keep your Mac awake. Click again to let it sleep.
- Right-click for a timed session of 15 minutes, 30 minutes, 1, 2, 4 or 8 hours. Doppio turns itself off when the time is up.
- Keep the display on, or let it sleep while your Mac keeps working.
- Record a keyboard shortcut to turn Doppio on or off from any app.
- Open Doppio at login, if you want it always there.

Doppio has no Dock icon and no account. It collects no analytics and makes no network connections.

## Settings

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/settings-dark.png">
    <img src="docs/assets/settings-light.png" width="460" alt="Doppio's settings window, with Startup, Sessions and Shortcut sections.">
  </picture>
</p>

## Install

1. Download [Doppio-1.0.1.zip](https://github.com/lantelyes/doppio/releases/download/v1.0.1/Doppio-1.0.1.zip) and unzip it.
2. Drag **Doppio** into your Applications folder and open it.
3. macOS blocks Doppio the first time you open it, because it isn't notarized by Apple. Go to **System Settings**, then **Privacy & Security**, scroll down, and click **Open Anyway**. You only need to do this once.

Doppio needs macOS 14 or later and runs on Apple silicon and Intel. It's developed and tested on macOS 27. Earlier versions should work but haven't been tested.

## Use

| Action | Result |
| --- | --- |
| Left-click the cup | Turn Doppio on or off. It stays on indefinitely unless you choose another **Default duration** in Settings. |
| Right-click the cup | Open the menu: time remaining, Turn On or Turn Off, durations, Settings, Quit Doppio. |
| Your shortcut | Same as a left-click, from any app. Record it in Settings. |

The cup is outlined when Doppio is off and filled when it's on.

Doppio prevents *idle* sleep. Closing the lid, choosing Sleep from the Apple menu, or a scheduled sleep will still put your Mac to sleep.

## How it works

Doppio holds an IOKit power assertion while a session is active, the same mechanism as the built-in `caffeinate` command. A session survives a manual sleep and wake. Timed sessions follow the real clock, so one that ran out while your Mac was asleep is off when it wakes. Quitting Doppio always ends the session.

## Build from source

You need Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
git clone https://github.com/lantelyes/doppio.git
cd doppio
xcodegen generate
open Doppio.xcodeproj
```

Run the tests with:

```sh
xcodebuild -project Doppio.xcodeproj -scheme Doppio -derivedDataPath build test
```

`Scripts/release.sh` builds the universal, ad-hoc signed app and zips it into `dist/`.

## License

MIT. See [LICENSE](LICENSE).

Doppio uses [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus, also MIT.
