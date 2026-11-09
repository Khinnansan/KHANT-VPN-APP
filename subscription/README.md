# KHANT VPN Public Subscription

This folder hosts the public subscription feed for KHANT VPN.

## Subscription URL

`https://raw.githubusercontent.com/Khinnansan/KHANT-VPN-APP/main/subscription/servers.txt`

## Add VPN server keys

Edit `servers.txt` and add one complete server URI per line. Supported URI types depend on the KHANT VPN core, including supported Shadowsocks, VMess, and VLESS links.

Example format (fake placeholder only — replace with your real server URI):

```text
vless://UUID@example.com:443?security=tls&type=ws#Example
vmess://BASE64_CONFIG
ss://BASE64_CONFIG#Example
```

Do not add passwords, private tokens, or unrelated account credentials. This feed is public: anyone with the URL can read every server URI in it. Anyone using the subscription may also use the listed servers, subject to server limits and provider rules.

After editing and saving `servers.txt`, the same subscription URL remains unchanged. In KHANT VPN, add it as a remote subscription URL and refresh the profile to load updates.
