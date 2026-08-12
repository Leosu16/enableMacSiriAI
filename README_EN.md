# enableMacSiriAI

`enableMacSiriAI` helps people use an Apple Silicon Mac purchased outside China mainland while they are in China mainland. It reads, changes, locks, and restores macOS's country-code cache without disabling SIP or installing a kernel extension. Setting the country code to a supported overseas region can also restore regional availability for Apple Maps and Apple News on eligible non-China-mainland Macs.

[中文说明](README.md)

> [!WARNING]
> This is an unofficial experimental tool. Changing the country cache may affect Maps, location-based services, content availability, and other regional features. It cannot guarantee that Apple Intelligence or Siri AI will become available.

## Requirements

- macOS 27
- Apple Silicon Mac
- Mac purchased outside China mainland (`region-info` must not be `CH/A`)
- Administrator account

China-mainland Mac models are not supported. The tool refuses to change an unsupported device or an unknown cache format.

## Quick start

Download the project, open Terminal in the project folder, and run:

```bash
chmod +x enableMacSiriAI
./enableMacSiriAI
```

Choose a country or region from the menu:

- `1` — United States (`US`)
- `2` — Canada (`CA`)
- `3` — United Kingdom, Australia, Japan, or Singapore
- `4` — unlock the current cache without changing it
- `5` — restore the original cache
- `6` — refresh the displayed status
- `7` — run the read-only Siri AI diagnosis
- `0` — exit

Changing or restoring the cache requires your Mac administrator password. The password is entered directly into the macOS `sudo` prompt and is not stored by this tool.

After changing a country code, restart the Mac. Run `enableMacSiriAI` again to confirm that every displayed country source uses the selected code and that the cache is marked `uchg`.

## Restore the original cache

Open the menu, choose `5`, and enter `RESTORE` or `restore` when asked. After restoration, choose whether to keep or delete the saved backup.

You can also run:

```bash
sudo ./enableMacSiriAI restore                    # Restore and keep the backup
sudo ./enableMacSiriAI restore --delete-backup    # Restore, then delete the backup
```

The backup is kept in `/private/var/db/enableMacSiriAI`. Restoration returns the cache to its original contents and unlocks it. If the backup is deleted, the next country-code change creates a new backup from the cache that exists at that time. Restart the Mac afterward.

## Other commands

```bash
./enableMacSiriAI status
./enableMacSiriAI diagnose
sudo ./enableMacSiriAI set US
sudo ./enableMacSiriAI set CA
sudo ./enableMacSiriAI unlock
sudo ./enableMacSiriAI restore
```

Available country codes are `US`, `CA`, `GB`, `AU`, `JP`, and `SG`.

`diagnose` does not require administrator access and never changes files. It checks all GREYMATTER inputs, Foundation Models and Siri App Intents eligibility, system and Siri languages, Siri and ChatGPT extension states, and actively connects to Siri AI/PCC endpoints. The network test geolocates the connected endpoint IP. If a China IP or an indeterminate result is detected, the tool hides the domain, IP, and failure details and only shows network troubleshooting guidance plus the latest module download links.

The repository also includes optional Siri AI and ChatGPT routing configurations. The two links below automatically download the latest versions from GitHub Releases and never need to change. Do not use a GitHub `blob` page URL:

Current module version: `0.1.7` (updated `2026-08-12 23:52 UTC+8`). The module description includes the version and minute-precise update time so users can confirm that it is current. If Siri traffic still bypasses routing in Clash rule mode on macOS, add `PROCESS-NAME,assistantd,your-proxy-policy` above the Siri rules. This is a macOS/Clash-specific rule and should not be added to the Loon or Shadowrocket modules intended for iPhone and iPad.

- [Automatically download the latest Loon plugin (`.lpx`)](https://github.com/Leosu16/enableMacSiriAI/releases/latest/download/Siri_AI_ChatGPT.lpx)
- [Automatically download the latest Shadowrocket module (`.srmodule`)](https://github.com/Leosu16/enableMacSiriAI/releases/latest/download/Siri_AI_ChatGPT.srmodule)
- Repository sources: [Loon](Siri_AI_ChatGPT.lpx) · [Shadowrocket](Siri_AI_ChatGPT.srmodule)

After importing the appropriate file, make sure the client configuration provides a `PROXY` policy backed by a node in a supported region. Loon can add the `.lpx` Release URL directly. In Shadowrocket, open Config → Modules → + and paste the `.srmodule` Release URL. These routing configurations are independent of the country-code feature.

If Siri AI cannot access the network normally, use one of the modules above, or enable global proxy and TUN mode. When using Clash, set the TUN stack to `system`.

## Important notes

- The tool only changes `/private/var/db/com.apple.countryd/countryCodeCache.plist`.
- It does not change SIP, NVRAM, AMFI, hardware region information, or `eligibility.plist`.
- Apple Account region, language, network, hardware, and server-side eligibility can still affect Apple Intelligence, Siri AI, Apple Maps, and Apple News; the tool cannot guarantee that every feature will become available.
- With SIP enabled, macOS protects `countryd` and `eligibilityd` from manual restart, so a Mac restart is required after changes.
- A macOS update may replace the locked cache. Run `enableMacSiriAI status` after updating.
- See Apple's [Apple Intelligence requirements and regional availability](https://support.apple.com/en-asia/121115).

## License

Source code is available under the [PolyForm Noncommercial License 1.0.0](LICENSE).

Personal, educational, research, hobby, and other noncommercial use is permitted under the license. Commercial use requires separate written permission from the project owner. Because commercial use is restricted, this is source-available software rather than OSI-approved open-source software.
