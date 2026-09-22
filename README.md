# enableMacSiriAI

`enableMacSiriAI` 面向在中国大陆使用外版 Apple Silicon Mac 的用户。它可以读取、修改、锁定和恢复 macOS 国家码缓存，无需关闭 SIP，也不安装内核扩展。将国家码设为受支持的海外地区后，还可以恢复海外版 Apple Maps（地图）和 Apple News 的地区可用性。

[English README](README_EN.md)

> [!WARNING]
> 这是非官方实验性工具。修改国家码缓存可能影响地图、定位服务、内容可用性及其他地区功能，也不能保证 Apple Intelligence 或 Siri AI 一定可用。

## 使用要求

- macOS 27
- Apple Silicon Mac
- 中国大陆以外地区销售的设备
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
- `7` — 运行只读 Siri AI 诊断
- `0` — 退出

修改或恢复时需要输入 Mac 管理员密码。密码只会直接输入到 macOS 的 `sudo` 提示中，本工具不会保存密码。

设置国家码后请重启 Mac。重启后再次运行 `enableMacSiriAI`，确认国家码和锁定状态正确。

## 恢复原始缓存

打开菜单，选择 `5`，然后根据提示输入 `RESTORE` 或 `restore`。恢复成功后，可以选择保留或删除备份。

也可以直接运行：

```bash
sudo ./enableMacSiriAI restore                    # 恢复并保留备份
sudo ./enableMacSiriAI restore --delete-backup    # 恢复成功后删除备份
```

工具会自动保存原始缓存用于恢复。恢复完成后请重启 Mac。

## 其他命令

```bash
./enableMacSiriAI status
./enableMacSiriAI diagnose
sudo ./enableMacSiriAI set US
sudo ./enableMacSiriAI set CA
sudo ./enableMacSiriAI unlock
sudo ./enableMacSiriAI restore
```

可用国家码为 `US`、`CA`、`GB`、`AU`、`JP`、`SG`。

`diagnose` 会展示设备资格、国家码、语言、Siri 与 ChatGPT 扩展以及 Siri AI 网络状态。发现联网异常时，还会显示处理建议和最新版分流资源链接。

仓库同时提供可选的 Siri AI 与 ChatGPT 分流配置：

- [最新版 Loon 插件（`.lpx`）](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_ChatGPT.lpx)
- [最新版 Shadowrocket 模块（`.srmodule`）](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_ChatGPT.srmodule)
- [Stash 覆写模块（`.stoverride`，iOS/iPadOS）](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_ChatGPT.stoverride)
- [sing-box JSON 规则集（`.json`）](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_ChatGPT.json)：与 Loon、Shadowrocket 的域名规则一致，导入后选择代理策略并置顶。
- [Clash/Mihomo 完整配置模板（`.yaml`）](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Clash_Global_Routing.yaml)
- [Siri 独立规则集（`.yaml`，已有配置用户）](https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_Clash.yaml)

Loon 可直接添加上面的 `.lpx` 地址，并为 `PROXY` 映射代理策略；Shadowrocket 可在“配置 → 模块 → +”中粘贴 `.srmodule` 地址，配置中需有 `PROXY` 策略。这些分流配置与国家码修改功能相互独立。

### Stash（iOS / iPadOS）

先在 Stash 导入并启用自己的节点订阅，再在“覆写”中通过上面的 `.stoverride` 链接导入并启用模块，将它排在其他覆写之前。在代理页面的 `Siri-ChatGPT` 组中选择节点，使用规则模式并启动 Stash VPN。

模块自动收集原配置的节点，置顶 Siri / ChatGPT 域名和语音 IP 规则，并追加 Siri Fake-IP 例外。原订阅的其他分流和 DNS 设置保留，无需填写订阅链接或安装 HTTPS 解密证书。如果已有同名 `Siri-ChatGPT` 组，请保留一个，避免重复定义。仅导入模块而没有节点订阅时，无法提供代理。格式已校验，移动端实际效果待测试。参见 [Stash 覆写说明](https://stash.wiki/configuration/override)。

### Clash/Mihomo 完整模板

适用于 Mihomo 内核客户端。模板包含 Siri、ChatGPT、语音 IP、国内直连和 Siri Fake-IP 过滤配置。

1. 下载完整模板，用文本编辑器将 `YOUR_CLASH_SUBSCRIPTION_URL` 替换为自己的 **Clash YAML 节点订阅链接**，保留两侧引号。
2. 保存文件，在客户端选择“导入本地配置”并启用它。
3. 在 `Siri-ChatGPT` 中选择用于 AI 的节点，在 `Proxy` 中选择其他代理流量使用的节点。
4. 使用规则模式，并按客户端提示开启 TUN / VPN 接管流量。

模板从订阅获取节点，使用模板自己的分流和 DNS 设置，不继承机场的规则。国内和局域网流量直连，其余流量走 `Proxy`。订阅必须返回包含 `proxies` 的 Clash YAML，不能使用网页地址或 Base64 节点订阅。填写过的文件包含私人订阅链接，请保留在本机。以后更新完整模板时，需要重新填写自己的订阅链接；远程规则集和节点订阅会自动更新。

### 只添加 Siri 独立规则集

已有配置可单独使用 `Siri_AI_Clash.yaml`。将以下内容合并到对应配置段，保留原内容，并把 `RULE-SET` 放在规则列表首位：

```yaml
rule-providers:
  Siri-AI:
    type: http
    behavior: classical
    url: https://raw.githubusercontent.com/Leosu16/enableMacSiriAI/main/Siri_AI_Clash.yaml
    path: ./ruleset/Leosu16-Siri_AI_Clash.yaml
    interval: 86400
rules:
  - RULE-SET,Siri-AI,你的代理组名
```

将 `你的代理组名` 替换为配置中**已存在**的代理组名称，然后在客户端的该组中选择节点。独立规则集不会创建策略组，也不包含 ChatGPT 补充规则或 DNS 设置。使用 Fake-IP 时，还需按 [Siri Fake-IP 过滤文件](Siri_AI_FakeIP_Filter.yaml) 的说明添加过滤；完整模板已配置好。

如果 Siri AI 无法正常访问，可使用上述分流资源，或将代理切换为全局并开启 TUN 模式。

## 注意事项

- 工具只修改 macOS 国家码缓存，不会关闭 SIP 或修改硬件区域信息。
- Apple 账户地区、语言、网络、硬件及服务端资格仍可能影响 Apple Intelligence、Siri AI、Apple Maps 和 Apple News；工具不保证所有功能一定可用。
- 修改或恢复后需要重启 Mac。
- macOS 系统升级可能替换已经锁定的缓存，升级后请重新运行 `enableMacSiriAI status` 检查。
- 参见 Apple 官方的 [Apple Intelligence 要求及地区可用性说明](https://support.apple.com/zh-cn/121115)。

## 许可证

本项目源码按 [PolyForm Noncommercial License 1.0.0](LICENSE) 提供。

许可证允许个人、教育、研究、兴趣项目及其他非商业用途。商业用途需要另行取得项目所有者的书面授权。
