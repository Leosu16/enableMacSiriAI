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
- [sing-box JSON rule set (`.json`)](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_ChatGPT.json): matches the Loon and Shadowrocket domain rules. Assign a proxy policy and place it first after importing.
- [Complete Clash/Mihomo configuration template (`.yaml`)](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Clash_Global_Routing.yaml)
- [Standalone Siri rule set (`.yaml`, for existing configurations)](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_Clash.yaml)

In Loon, add the `.lpx` URL and map `PROXY` to a proxy policy. In Shadowrocket, open Config → Modules → + and paste the `.srmodule` URL; the configuration must provide a `PROXY` policy. These resources are independent of the country-code feature.

### Complete Clash/Mihomo template

For Mihomo-based clients. Includes Siri, ChatGPT, voice IPs, China direct routing, and the Siri Fake-IP filter.

1. Download the template and replace `YOUR_CLASH_SUBSCRIPTION_URL` with your **Clash YAML node subscription URL** in a text editor, keeping the surrounding quotes.
2. Save the file, import it as a local configuration in your client, and activate it.
3. Select an AI node in `Siri-ChatGPT` and a node for other proxied traffic in `Proxy`.
4. Use rule mode and enable TUN / VPN as prompted by your client to route traffic.

The template fetches subscription nodes but uses its own routing and DNS settings, not the provider's rules. China and local-network traffic go direct; other traffic uses `Proxy`. The subscription must return Clash YAML containing `proxies`, not a web page or a Base64 node subscription. Keep the edited file private because it contains your subscription URL. When downloading an updated template, fill in your URL again; remote rule sets and subscription nodes update automatically.

### Add only the standalone Siri rule set

To use `Siri_AI_Clash.yaml` with an existing configuration, merge these entries into the corresponding sections, preserving existing content, and place the `RULE-SET` first:

```yaml
rule-providers:
  Siri-AI:
    type: http
    behavior: classical
    url: https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_Clash.yaml
    path: ./ruleset/Leosu16-Siri_AI_Clash.yaml
    interval: 86400
rules:
  - RULE-SET,Siri-AI,YOUR_PROXY_GROUP
```

Replace `YOUR_PROXY_GROUP` with a proxy group that **already exists** in your configuration, then select a node in that group. This rule set does not create a group or include the additional ChatGPT rules or DNS settings. If using Fake-IP, also follow the instructions in the [Siri Fake-IP filter file](Siri_AI_FakeIP_Filter.yaml); the complete template already includes them.

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
