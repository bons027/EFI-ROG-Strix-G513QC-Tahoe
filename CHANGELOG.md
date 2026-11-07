# Changelog

All notable changes to this EFI. Dates in WIB (UTC+7).

## 2026-11-07 — andgarriv method (current)

- **Added ECEnabler 1.0.6** (Lilu plugin, taken from andgarriv's repo) — the last piece of andgarriv's brightness-key method. Registered in `Kernel → Add` after Lilu.
- **LogScanCodes turned back off** (`1` → `0`) — the Fn-key diagnostic logging is removed.
- Karabiner-based Fn mapping approach dropped (EventViewer proved only `Fn+F1 = mute` generates a HID event; `Fn+F2`–`Fn+F12` generate nothing, so Karabiner cannot remap them either).
- Deliberately **not** copied from andgarriv: NVMeFix enabled, `itlwm`, VoodooPS2 Mouse/Trackpad enabled, UTBMap, `alcid=21`, SSDT-dGPU-Off / HPET / FixShutdown, removing the AppleIntelPanelA block, SIP `0x0803`.

## 2026-11-07 — USB mapping

- **USBPorts.kext added** (Hackintool map, 8 ports: XHC0 HS01/HS03/SS06 + XHC1 HS01/HS02/HS04/SS05/SS06). All ports `UsbConnector=3`.
- **USBToolBox.kext + UTBDefault.kext removed** (they conflict with USBPorts.kext).
- Kept the EFI's existing SSDT-USBX (functionally equivalent to the uploaded one).

## 2026-11-07 — Brightness fixed 🎉

- **Brightness slider works.** The fix, landed together:
  - `Kernel → Block` `com.apple.driver.AppleIntelPanelA` (the Intel driver was hijacking PNLF; blocking it lets AppleBacklight attach).
  - **SSDT-PNLF, 105-byte root-scope variant** (`_UID 0x13`, andgarriv/G513QM variant).
  - **SSDT-ALS0** (ambient light sensor).
  - Boot-arg **`-NRedDPDelay`**.
  - NullMoth boot-args removed (Vega-only build).
- Earlier attempts that did **not** fix it: SSDT-PNLF 135-byte under VGA (`_UID 0x0A`), AMDPNLF 97-byte variant alone, MonitorControl (slider snapped back to 0 — macOS had no brightness interface at all).

## 2026-11-07 — Wi-Fi fixed

- **AirportMtkWlan v2.0.0 (Tahoe build)** — native MediaTek MT7921 driver.
- Root cause: v1.6.0–1.7.0 fail to load (`kxld` unresolved `HMAC_SHA256` symbols, kextstat empty); v1.7.2 fixed `wifid` rejecting the interface.
- AsusSMC removed (`MaxKernel 23.99.99`, dead on Tahoe).

## 2026-11-04 — First boot

- Tahoe booted from USB EFI. Hardware identified from SysReport/Report.json + DSDT: Ryzen 5 5600H, Vega 7 (`1002:1638`), RTX 3050 Laptop (`10DE:25A5`), MT7921 (`14C3:7961`), ALC294 (layout 28), BOE NV156FHM-NX3 144 Hz.
- Reference: andgarriv's G513IC EFI (Tahoe 26.2, OC 1.0.6, NootedRed 0.8.10, BrightnessKeys, `-NRedDPDelay`, SMBIOS MacBookPro16,2).

## 2026-11-07 — Verbose removed

- Removed boot-arg `-v` (clean boot: Apple logo + progress bar instead of verbose text).
- Kept `debug=0x100 keepsyms=1` for panic diagnosis (they don't produce verbose output).
