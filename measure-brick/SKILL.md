---
name: measure-brick
description: Measure a USB-C charger / brick / powerbank by reading its negotiated USB-C Power Delivery profile on a Mac. Use when the user says "measure my charger", "measure this brick", "how fast does this charge", "is this a fast charger", or wants to characterize/compare power adapters.
allowed-tools: Bash, Read, Write
---

# Measure Brick — USB-C charger profiler (macOS)

Characterize whatever charger is plugged into a Mac by reading its **negotiated USB-C
Power Delivery profile** from the battery controller (`ioreg AppleSmartBattery`).

## How to run

The tool lives next to this file:

```bash
~/.claude/skills/measure-brick/measure-brick.sh "label"        # one-shot snapshot
~/.claude/skills/measure-brick/measure-brick.sh watch "label"  # live, refresh every 2s
~/.claude/skills/measure-brick/measure-brick.sh                # quick unlabeled read
```

It prints a verdict line (negotiated V / W, tier, description) plus the full PD ladder
and live watts going into the battery.

## How to interpret

**Rank bricks by negotiated VOLTAGE, not live wattage.** Near a full battery the Mac
only sips a few watts no matter how strong the brick is — so live wattage is misleading.
The negotiated voltage is the truth:

- **5 V** → legacy / slow. Either a dumb 5 V charger, or a *proprietary* fast-charge brick
  (Huawei SuperCharge / "22.5 W", Qualcomm QC, OPPO VOOC) whose fast tier Apple devices
  **cannot use** — Macs and iPhones only speak standard USB-C PD, so they fall back to 5 V.
- **9–15 V** → partial PD. Real charging; modest for a MacBook, but **ideal for iPhone**
  (iPhones cap around 20–27 W and love the 9 V rung).
- **20 V** → full PD. A MacBook's full speed (e.g. 65 W = 20 V × 3.24 A).

## Things to tell the user

- **Identity is NOT readable.** Third-party bricks report `AdapterID = 0` and a generic
  `"pd charger"` string — no model number, manufacturer, or serial. (Genuine *Apple*
  adapters do report `Name`/`Manufacturer`/`SerialString`.) The only fingerprint is the
  wattage + PD ladder + FamilyCode, which identifies a *class*, not identical twins. To
  get a real model number, read the physical label (offer to read it from a photo).
- **iPhone fast charging needs a USB-C → Lightning cable.** A USB-A → Lightning cable
  can't carry PD and defeats even a 65 W brick. (iPhone 15+ is USB-C.)
- **FamilyCode cheats:** `0xe0004009` = legacy 5 V family, `0xe000400a` = PD family.

## Logging results

Persist comparisons to `~/brick-results.md` (a table of brick → negotiated profile →
iPhone/MacBook verdict, plus PD ladders for the good ones). Append new bricks there.
```
