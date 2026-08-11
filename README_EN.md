# enableMacSiriAI

`enableMacSiriAI` helps people use an Apple Silicon Mac purchased outside China mainland while they are in China mainland. It reads, changes, locks, and restores macOS's country-code cache without disabling SIP or installing a kernel extension.

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
sudo ./enableMacSiriAI set US
sudo ./enableMacSiriAI set CA
sudo ./enableMacSiriAI unlock
sudo ./enableMacSiriAI restore
```

Available country codes are `US`, `CA`, `GB`, `AU`, `JP`, and `SG`.

## Important notes

- The tool only changes `/private/var/db/com.apple.countryd/countryCodeCache.plist`.
- It does not change SIP, NVRAM, AMFI, hardware region information, or `eligibility.plist`.
- Apple Account region, language, network, hardware, and server-side eligibility can still affect Apple Intelligence and Siri AI.
- With SIP enabled, macOS protects `countryd` and `eligibilityd` from manual restart, so a Mac restart is required after changes.
- A macOS update may replace the locked cache. Run `enableMacSiriAI status` after updating.
- See Apple's [Apple Intelligence requirements and regional availability](https://support.apple.com/en-asia/121115).

## License

Source code is available under the [PolyForm Noncommercial License 1.0.0](LICENSE).

Personal, educational, research, hobby, and other noncommercial use is permitted under the license. Commercial use requires separate written permission from the project owner. Because commercial use is restricted, this is source-available software rather than OSI-approved open-source software.
