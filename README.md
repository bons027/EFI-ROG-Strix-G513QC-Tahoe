# ASUS ROG Strix G513QC — macOS Tahoe Hackintosh EFI

[![macOS](https://img.shields.io/badge/macOS-Tahoe%2026.x-blue?style=for-the-badge&logo=apple)](https://www.apple.com/macos/tahoe/)
[![OpenCore](https://img.shields.io/badge/OpenCore-1.0.6-blue?style=for-the-badge&logo=opencore&logoColor=white)](https://github.com/acidanthera/OpenCorePkg)
[![CPU](https://img.shields.io/badge/CPU-Ryzen%205%205600H-red?style=for-the-badge&logo=amd)](https://www.amd.com/)
[![GPU](https://img.shields.io/badge/iGPU-Vega%207%20(NootedRed)-red?style=for-the-badge&logo=amd)](https://github.com/ChefKissInc/NootedRed)

OpenCore EFI for the **ASUS ROG Strix G15 G513QC** (2021, Ryzen 5 5600H + Vega 7) running **macOS Tahoe 26.x**. Built and debugged hardware-first: every fix below was verified against the laptop's own DSDT, `ioreg` output, and kernel logs — not copied blind from another repo.

> **This EFI boots and runs daily.** Brightness slider works, native MediaTek Wi-Fi works, USB is fully mapped, and the Fn volume/brightness keys work natively. See [What works](#what-works) for the honest status of everything else.

---

## Hardware

| Component | Model | Notes |
|---|---|---|
| **Laptop** | ASUS ROG Strix G15 G513QC (2021) | Optimus-only, **no MUX** — the RTX can never drive the internal panel |
| **CPU** | AMD Ryzen 5 5600H (Cezanne) | 6C/12T |
| **iGPU** | AMD Vega 7, `1002:1638` | Drives the internal display via NootedRed |
| **dGPU** | NVIDIA RTX 3050 Laptop, `10DE:25A5` | HDMI is wired to the RTX. No macOS driver in this EFI (see [RTX 3050](#rtx-3050--nullmoth-experimental)) |
| **Display** | BOE NV156FHM-NX3, 1920×1080, 144 Hz IPS | Wired to Vega only |
| **Wi-Fi** | MediaTek MT7921, `14C3:7961` (PCIe) | Native driver, no HeliPort |
| **Bluetooth** | MediaTek, USB `13D3:3563` | SimpleMtkBtFw stack |
| **LAN** | Realtek RTL8111, `10EC:8168` | |
| **Audio** | Realtek ALC294, layout-id `28` | AppleALC + SimpleHDA |
| **Trackpad** | ASUS Precision Touchpad (I2C HID) | VoodooI2C, **not** PS2 |
| **USB** | 2× AMD controllers (`1022:1639`) | Fully mapped — see [USB mapping](#usb-mapping) |
| **Storage** | 512 GB NVMe SSD + 1 TB HDD | NVMeFix is **disabled** (it panicked this SSD) |
| **SMBIOS** | MacBookPro16,2 | ⚠️ **Generate your own — see [SMBIOS](#smbios--generate-your-own)** |

---

## What works

| Feature | Status | Notes |
|---|---|---|
| Boot (OpenCore → Tahoe) | ✅ | From SSD EFI, dual-boot with Windows preserved |
| Vega 7 acceleration (NootedRed 0.8.10) | ✅ | Internal display, 144 Hz |
| **Brightness slider** | ✅ | Fixed — see [the brightness story](#the-brightness-story) |
| **Brightness keys (Fn+F4/F5)** | ✅ | Native via BRTN + BrightnessKeys + ECEnabler (andgarriv method) |
| **Volume / mute keys (Fn+F1/F2/F3)** | ✅ | Native via EC → PS2 stock map, no remapping needed |
| **Native Wi-Fi (MT7921)** | ✅ | AirportMtkWlan v2.0.0 — see [the Wi-Fi story](#the-wi-fi-story) |
| Bluetooth | ⚠️ | Stack installed (SimpleMtkBtFw + patcher + BlueToolFixup); on/off unconfirmed — please report |
| Audio (ALC294, layout 28) | ⚠️ | AppleALC loaded per `ioreg`; speaker/mic unconfirmed — please report |
| Trackpad (I2C) + gestures | ✅ | VoodooI2C |
| USB (all ports) | ✅ | Mapped with Hackintool, 8 ports (see below) |
| Ethernet (RTL8111) | ✅ | RealtekRTL8111 2.4.2 (author's AMD recommendation over 3.0.0) |
| Battery | ✅ | SMCBatteryManager |
| Keyboard backlight (Fn+F7) | ⚠️ | EC-controlled at hardware level; macOS does not see it (see [Fn keys](#fn-keys)) |
| Sleep / wake | ❓ | Untested — please report |
| Shutdown / restart | ❓ | Untested — please report |
| RTX 3050 / HDMI out | ❌ | No driver in this EFI (see [RTX 3050](#rtx-3050--nullmoth-experimental)) |
| Fn keys F6–F12 (touchpad, backlight, display, lock, camera, screenshot, MyASUS) | ❌ | Dead by design — see [Fn keys](#fn-keys) |

---

## The brightness story

This was the hardest fix in the build, and the reason this EFI exists.

**Symptom:** macOS booted fine, but System Settings → Displays had **no brightness slider at all**.

**What was ruled out:**
- `SSDT-PNLF` was loading (`PNLF@0` present in `ioreg`).
- MonitorControl didn't help — its slider snapped back to `0`. macOS had no brightness interface to talk to.
- NootedRed version wasn't the differentiator (HP laptops work on NootedRed 1.0.0).

**Root cause (proven by `ioreg`):** `PNLF@0` was loaded, but **`AppleIntelPanelA` — Apple's *Intel* backlight driver — had attached to it and hijacked it**. `AppleBacklight` never loaded. On an AMD Vega laptop, the Intel driver has no business touching PNLF, but nothing stopped it.

**The fix (all four changes landed together; the AppleIntelPanelA collision is the strongest candidate):**
1. **Block `com.apple.driver.AppleIntelPanelA`** in `Kernel → Block` — lets `AppleBacklight` attach to PNLF.
2. **SSDT-PNLF, 105-byte root-scope variant** (`_UID 0x13`, `_STA 0x0B`, no `_BCL`/`_BCM`) — the variant used by the G513QM and andgarriv G513IC repos (md5 `aed5c827…`).
3. **SSDT-ALS0** (ambient light sensor, `ACPI0008`) — present in every working AMD Ryzen laptop repo.
4. **Boot-arg `-NRedDPDelay`** — NootedRed display delay flag.
5. **ECEnabler 1.0.6** — added later to follow andgarriv's brightness-key method (see [Fn keys](#fn-keys)).

After this build the slider appeared **and actually dims the panel**. If you remove the AppleIntelPanelA block, the slider disappears again.

**Pattern found during research:** ASUS Ryzen laptops = brightness broken, HP (Victus/Pavilion, same 5600H CPU) = brightness works. It's the ASUS EC/DSDT implementation, not the CPU or the panel — the BOE NV156FHM-NX3 is a common panel that works elsewhere.

## The Wi-Fi story

**Symptom:** Wi-Fi showed "Wi-Fi is off" and the driver never attached. `kextstat` was empty for the MediaTek driver.

**Root cause (from the driver's own release notes):** AirportMtkWlan **v1.6.0–1.7.0 fail to load** — `kxld` reports unresolved `HMAC_SHA256` symbols, so the kext silently never loads (it looks "as if the kext were absent"). v1.7.2 fixed `wifid` rejecting the interface.

**Fix:** **AirportMtkWlan v2.0.0 (Tahoe build)**, native driver, PCI match `0x796114c3`. No HeliPort, no `itlwm` (do not switch — `itlwm` is what andgarriv uses after swapping his card for an Intel AX210; this laptop keeps the stock MT7921).

## USB mapping

Mapped on macOS with **Hackintool** and exported as `USBPorts.kext` (replaces `USBToolBox.kext` + `UTBDefault.kext` — never run both at once, they conflict).

| Controller | Ports |
|---|---|
| XHC0 (`Pci(0x8,0x1)/Pci(0x0,0x3)`) | HS01, HS03, SS06 |
| XHC1 (`Pci(0x0,0x4)`) | HS01, HS02, HS04, SS05, SS06 |

**8 ports total, all `UsbConnector=3`.** Caveat: no port is marked Internal (255) or USB-C (9), so if Bluetooth or the webcam stops working after installing this EFI, its port is missing from the map — open an issue with which device died and the map will be fixed (or revert to USBToolBox + UTBDefault).

## Fn keys

Fn keys are handled by the **EC firmware + DSDT**, not by VoodooPS2. VoodooPS2 never sees the Fn key being pressed — it only receives the scan code the EC decides to send. That shapes everything below.

**What the DSDT actually does (verified line-by-line):**

| EC query | PS2 code | macOS function | Status |
|---|---|---|---|
| `_Q11` | `e020` | Mute | ✅ Works natively (stock map) |
| `_Q35` | `e02e` | Volume Down | ✅ Works natively (stock map) |
| `_Q36` | `e030` | Volume Up | ✅ Works natively (stock map) |
| `_Q17` | — (ACPI `BRTN 0x87`) | Brightness Up | ✅ Works (BrightnessKeys) |
| `_Q18` | — (ACPI `BRTN 0x86`) | Brightness Down | ✅ Works (BrightnessKeys) |
| `_Q1A` | — (WMI `ATKD.IANE 0x6B`) | Touchpad toggle | ❌ Dead without AsusSMC |
| `_Q12`/`_Q13` | — (WMI `0xC4`/`0xC5`) | Keyboard backlight | ❌ Dead without AsusSMC (EC may still drive the LED directly) |
| `_Q37`/`_Q38` | — (WMI) | Mic mute / fan mode | ❌ Dead without AsusSMC |

Volume/mute need **no Custom ADB Map** — `e020`/`e02e`/`e030` are already correct in VoodooPS2's stock map. Brightness needs no map either — it travels via ACPI `BRTN`, not PS2.

**Why F6–F12 can't be fixed by remapping:** those keys fire WMI events (`ATKD.IANE`), which only AsusSMC listens to. AsusSMC 1.4.1 has `MaxKernel 23.99.99` (Ventura) and does not load on Tahoe. No Custom ADB Map entry can help, because the keys never become PS2 codes — and Karabiner can't help either: EventViewer proves only `Fn+F1 = mute` generates a HID event; `Fn+F2`–`Fn+F12` generate nothing at all. This is also why the G513QM, G513IC, and Victus repos don't handle Fn keys beyond brightness — "only brightness + volume" is the normal state for this laptop family, not a broken one.

**Fn+F6 = "switch tab" explained:** the EC doesn't fire an ACPI query for Fn+F6 on this sub-model, so the keyboard sends plain F6 — and in a browser/VS Code, F6 moves focus (address bar / panel), which feels like switching tabs.

## RTX 3050 / NullMoth (experimental)

The RTX 3050 Laptop (`10DE:25A5`) is in NullMoth's `SUPPORTED_IDS`, but Ampere physical validation is still "Pending" and the driver implements no Optimus mux. Tahoe support landed in NullMoth v2.0.0. **This EFI is Vega-only by design** — the NullMoth boot-args (`nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth`) were removed, and NullMoth is **not** installed.

If you want to experiment with RTX-driven HDMI output: install NullMoth post-install via its Mac app into `/Library/Extensions` (never put it in the EFI), re-add the four `nvfb` flags, and use the debug args `-NRedOff`, `-NRedNoAccel`, `-nvoff` if it panics. There is no documented precedent for a NootedRed + NullMoth combo — report back if you try it.

**VRAM note:** the Vega 7 VRAM (512 MB default) can only be changed in firmware, not in macOS or the EFI. The ASUS BIOS hides AMD CBS; the path is **Smokeless UMAF** (boot from a FAT32 USB → AMD CBS → NBIO Common Options → GFX Configuration → iGPU Configuration = `UMA_SPECIFIED` → UMA Frame buffer Size = `4G` on 16 GB RAM / `2G` on 8 GB). More VRAM adds capacity, not speed.

---

## Installation

### Prerequisites

- A macOS Tahoe installer USB (created with `createinstallmedia`).
- This EFI copied to the **EFI partition of your SSD** (see below).
- **Your own SMBIOS** — see [SMBIOS](#smbios--generate-your-own). Do not boot with the placeholder values in this repo.
- BIOS: disable Secure Boot, set SATA to AHCI, disable Fast Boot. (VT-d / Above 4G decoding: leave at defaults unless you know you need them.)

### Steps

1. **Mount your SSD's EFI partition** (209 MB, `disk1s1` in a typical dual-boot layout). **Do not delete the `Microsoft` folder** — Windows lives there.
2. **Copy `BOOT` and `OC` from this repo into the EFI partition** (merge, don't replace the whole partition).
3. **Generate your SMBIOS** with [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) (model `MacBookPro16,2`) and fill in `PlatformInfo → Generic` in `config.plist`: `SystemSerialNumber`, `MLB`, `SystemUUID`, `ROM`. See [SMBIOS](#smbios--generate-your-own).
4. **Unplug the installer USB** and boot from the SSD. Pick the macOS installer / macOS entry in the OpenCore picker.
5. Install macOS, then run through the [post-install checks](#post-install-checks).

### SMBIOS — generate your own

> ⚠️ **This repo ships with placeholder SMBIOS values** (`C02XXXXXXXXX`, nil UUID, zero ROM). They are intentionally invalid. **Never boot iCloud / iMessage with them, and never share your real serials publicly.**
>
> Generate your own with GenSMBIOS:
> ```
> ./GenSMBIOS.command  # pick MacBookPro16,2, generate, check coverage on Apple's website
> ```
> Paste the generated `SystemSerialNumber`, `MLB`, `SystemUUID`, and `ROM` into `EFI/OC/config.plist → PlatformInfo → Generic`. Do not change them again after signing into iCloud / iMessage.

### Post-install checks

After first boot, verify (and report back if anything differs):

- [ ] Brightness slider exists in System Settings → Displays **and** dims the panel
- [ ] `Fn+F4` / `Fn+F5` change brightness
- [ ] `Fn+F1` mutes, `Fn+F2` / `Fn+F3` change volume
- [ ] Wi-Fi connects (MT7921, native, no HeliPort)
- [ ] Bluetooth on/off + pairing
- [ ] Audio: speakers + microphone
- [ ] Every USB-A and USB-C port with a flash drive
- [ ] Webcam (FaceTime / Photo Booth)
- [ ] Trackpad gestures
- [ ] Sleep / wake, shutdown, restart

---

## Configuration notes

- **OpenCore 1.0.6**, `SecureBootModel: Disabled`, SIP `csr-active-config 0x0A43` (`430a0000`, required by AMFIPass).
- **Boot-args:** `-v debug=0x100 keepsyms=1 -vi2c-force-polling -lilubetaall amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 -NRedDPDelay`
- **Kernel → Block:** `com.apple.driver.AppleIntelPanelA` (the brightness fix — do not remove), `com.apple.iokit.IONDRVSupport` (prevents the firmware framebuffer from taking display index 0).
- **NVMeFix is disabled** — it kernel-panicked this SSD. Do not re-enable blindly.
- **VoodooPS2Trackpad / VoodooPS2Mouse are disabled** — the trackpad is I2C (VoodooI2C), not PS2.
- **AsusSMC is removed** — `MaxKernel 23.99.99`, dead on Tahoe (and the reason Fn F6–F12 are dead).
- **RealtekRTL8111 2.4.2** is kept deliberately — the author recommends it over 3.0.0 for AMD.
- **Do not copy** from andgarriv's G513IC EFI without checking: `NVMeFix` enabled, `itlwm` (Intel Wi-Fi), `VoodooPS2Trackpad/Mouse` enabled, `UTBMap`, `alcid=21`, `SSDT-dGPU-Off` (this DSDT has no GPU `_OFF` method), and SIP `0x0803`.

### Kexts

| Kext | Version | Purpose |
|---|---|---|
| Lilu | 1.7.3 | Patching framework |
| VirtualSMC + SMCBatteryManager + SMCLightSensor | 1.3.9 | SMC emulation, battery, ambient light |
| NootedRed | 0.8.10 | Vega 7 acceleration |
| AMFIPass | 1.4.1 | AMFI bypass (with SIP `0x0A43`) |
| AirportMtkWlan | 2.0.0 | Native MT7921 Wi-Fi (Tahoe build) |
| SimpleMtkBtFw / SimpleMtkBtPatcher | 1.0.0 | MediaTek Bluetooth firmware + patcher |
| BlueToolFixup | 2.7.2 | Third-party Bluetooth controller |
| AppleALC | 1.9.9 | ALC294 audio, layout-id 28 |
| SimpleHDA | 1.0.1 | Audio helper |
| BrightnessKeys | 1.0.4 | Fn brightness keys |
| ECEnabler | 1.0.6 | EC access (andgarriv brightness-key method) |
| VoodooI2C (+ GPIO, Services, Input) / VoodooI2CHID | 2.9.1 | I2C trackpad |
| VoodooPS2Controller (+ Keyboard) | 2.3.8 | PS2 keyboard (stock map, no custom ADB map) |
| USBPorts | 1.0 | Hackintool USB map (8 ports) |
| GenericUSBXHCI | 1.3.0b2 | USB (highest remaining panic risk — test with it disabled if you panic) |
| RealtekRTL8111 | 2.4.2 | Ethernet |
| RestrictEvents / ForgedInvariant | 1.1.7 / 1.5.0 | macOS version / hardware checks |
| AppleMCEReporterDisabler | 1.2 | Disable AppleMCE on AMD |
| NVMeFix | 1.1.4 | **Disabled** — panics this SSD |

### SSDTs

| SSDT | Purpose |
|---|---|
| SSDT-EC | Embedded controller |
| SSDT-PLUG-ALT | CPU power management (AMD) |
| SSDT-PNLF | Backlight (105-byte root-scope, `_UID 0x13` — andgarriv variant) |
| SSDT-ALS0 | Ambient light sensor |
| SSDT-USBX | USB power |
| SSDT-XOSI | OS identification |
| SSDT-USB-Reset | USB reset |
| SSDT-Disable_Network_GPP4 | Disabled (Wi-Fi now works natively) |

---

## Credits

- [andgarriv/EFI_ROG_STRIX_G15_G513](https://github.com/andgarriv/EFI_ROG_STRIX_G15_G513) — the G513IC EFI this build's brightness method follows (PNLF variant, `-NRedDPDelay`, ECEnabler).
- [Acidanthera](https://github.com/acidanthera) — OpenCore, Lilu, VirtualSMC, AppleALC, and friends.
- [ChefKissInc/NootedRed](https://github.com/ChefKissInc/NootedRed) — Vega iGPU acceleration.
- [Arxusion/AirportMtkWlan](https://github.com/Arxusion/AirportMtkWlan) — native MediaTek Wi-Fi (the release notes documented the load failure).
- [Dortania](https://dortania.github.io/OpenCore-Install-Guide) — the OpenCore Install Guide.
- The HP Victus 15 / M3401QC / G513QM repos whose brightness configs proved the pattern (ASUS = broken, HP = works).

## Disclaimer

For educational and personal use. Not affiliated with Apple, ASUS, or any kext author. macOS is a trademark of Apple Inc. Use at your own risk — back up your data and your working EFI before trying this one. **Never share your real SMBIOS serials publicly.**
