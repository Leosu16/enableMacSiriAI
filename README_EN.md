# enableMacSiriAI

`enableMacSiriAI` helps people use an Apple Silicon Mac purchased outside China mainland while they are in China mainland. It reads, changes, locks, and restores macOS's country-code cache without disabling SIP or installing a kernel extension. Setting the country code to a supported overseas region can also restore regional availability for Apple Maps and Apple News on eligible non-China-mainland Macs.

[中文说明](README.md)

> [!WARNING]
> This is an unofficial experimental tool. Changing the country cache may affect Maps, location-based services, content availability, and other regional features. It cannot guarantee that Apple Intelligence or Siri AI will become available.

## Requirements

- macOS 27
- Apple Silicon Mac
- Mac purchased outside China mainland
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

After changing a country code, restart the Mac. Run `enableMacSiriAI` again to confirm that the country code and lock status are correct.

## Restore the original cache

Open the menu, choose `5`, and enter `RESTORE` or `restore` when asked. After restoration, choose whether to keep or delete the saved backup.

You can also run:

```bash
sudo ./enableMacSiriAI restore                    # Restore and keep the backup
sudo ./enableMacSiriAI restore --delete-backup    # Restore, then delete the backup
```

The tool automatically saves the original cache for restoration. Restart the Mac after restoring it.

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

`diagnose` shows device eligibility, country code, language, Siri and ChatGPT extensions, and Siri AI network status. If it finds a network issue, it also displays troubleshooting guidance and the latest routing resource links.

The repository also includes optional Siri AI and ChatGPT routing resources:

- [Latest Loon plugin (`.lpx`)](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_ChatGPT.lpx)
- [Latest Shadowrocket module (`.srmodule`)](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_ChatGPT.srmodule)
- [Latest Clash/Mihomo rule set (`.yaml`)](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_Clash.yaml)

After importing the appropriate file, make sure the client configuration provides a `PROXY` policy backed by a node in a supported region. Loon can add the `.lpx` URL directly. In Shadowrocket, open Config → Modules → + and paste the `.srmodule` URL. These routing configurations are independent of the country-code feature.

For Clash/Mihomo, use the link above with `behavior: classical` and place the `RULE-SET` first.

If Siri AI cannot access the network normally, use one of the routing resources above, or enable global proxy and TUN mode.

## Important notes

- The tool only changes the macOS country-code cache. It does not disable SIP or change hardware region information.
- Apple Account region, language, network, hardware, and server-side eligibility can still affect Apple Intelligence, Siri AI, Apple Maps, and Apple News; the tool cannot guarantee that every feature will become available.
- Restart the Mac after changing or restoring the cache.
- A macOS update may replace the locked cache. Run `enableMacSiriAI status` after updating.
- See Apple's [Apple Intelligence requirements and regional availability](https://support.apple.com/en-asia/121115).

## License

Source code is available under the [PolyForm Noncommercial License 1.0.0](LICENSE).

Personal, educational, research, hobby, and other noncommercial use is permitted. Commercial use requires separate written permission from the project owner.
