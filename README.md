# enableMacSiriAI

`enableMacSiriAI` 面向在中国大陆使用外版 Apple Silicon Mac 的用户。它可以读取、修改、锁定和恢复 macOS 国家码缓存，无需关闭 SIP，也不安装内核扩展。

[English README](README_EN.md)

> [!WARNING]
> 这是非官方实验性工具。修改国家码缓存可能影响地图、定位服务、内容可用性及其他地区功能，也不能保证 Apple Intelligence 或 Siri AI 一定可用。

## 使用要求

- macOS 27
- Apple Silicon Mac
- 中国大陆以外地区销售的设备（`region-info` 不能是 `CH/A`）
- 管理员账户

本工具不支持国行 Mac。遇到不支持的设备或无法识别的缓存格式时，工具会拒绝修改。

## 快速使用

下载项目，在项目目录打开“终端”，然后运行：

```bash
chmod +x enableMacSiriAI
./enableMacSiriAI
```

在菜单中选择国家或操作：

- `1` — 美国（`US`）
- `2` — 加拿大（`CA`）
- `3` — 英国、澳大利亚、日本或新加坡
- `4` — 只解除当前缓存锁，不修改内容
- `5` — 恢复原始缓存
- `6` — 刷新显示状态
- `0` — 退出

修改或恢复时需要输入 Mac 管理员密码。密码只会直接输入到 macOS 的 `sudo` 提示中，本工具不会保存密码。

设置国家码后请重启 Mac。重启后再次运行 `enableMacSiriAI`，确认所有国家码来源都变为所选代码，并且缓存显示为 `uchg` 锁定状态。

## 恢复原始缓存

打开菜单，选择 `5`，然后根据提示输入 `RESTORE` 或 `restore`。恢复成功后，可以选择保留或删除备份。

也可以直接运行：

```bash
sudo ./enableMacSiriAI restore                    # 恢复并保留备份
sudo ./enableMacSiriAI restore --delete-backup    # 恢复成功后删除备份
```

备份保存在 `/private/var/db/enableMacSiriAI`。恢复操作会还原缓存内容并解除锁定。如果删除备份，下次设置国家码时，工具会把当时的缓存重新保存为新的原始备份。完成后请重启 Mac。

## 其他命令

```bash
./enableMacSiriAI status
sudo ./enableMacSiriAI set US
sudo ./enableMacSiriAI set CA
sudo ./enableMacSiriAI unlock
sudo ./enableMacSiriAI restore
```

可用国家码为 `US`、`CA`、`GB`、`AU`、`JP`、`SG`。

## 注意事项

- 工具只修改 `/private/var/db/com.apple.countryd/countryCodeCache.plist`。
- 不会修改 SIP、NVRAM、AMFI、硬件区域信息或 `eligibility.plist`。
- Apple 账户地区、语言、网络、硬件及服务端资格仍可能影响 Apple Intelligence 和 Siri AI。
- SIP 开启时，macOS 会保护 `countryd` 和 `eligibilityd`，因此修改后需要重启 Mac。
- macOS 系统升级可能替换已经锁定的缓存，升级后请重新运行 `enableMacSiriAI status` 检查。
- 参见 Apple 官方的 [Apple Intelligence 要求及地区可用性说明](https://support.apple.com/zh-cn/121115)。

## 许可证

本项目源码按 [PolyForm Noncommercial License 1.0.0](LICENSE) 提供。

许可证允许个人、教育、研究、兴趣项目及其他非商业用途。任何商业用途都需要另行取得项目所有者的书面授权。由于禁止未经授权的商业使用，本项目属于“源码可用（source-available）”，而不是 OSI 认证的开源软件。
