# KHANT VPN — Private Subscription Gateway

This folder contains a Cloudflare Worker that serves a private VPN subscription
file to KHANT VPN app users. The Android app only receives the subscription
content; the GitHub credential stays in Cloudflare and is never packaged in
the APK or committed to this repository.

## Architecture

KHANT VPN app → per-friend access key → Cloudflare Worker → private GitHub
subscription file

The app already supports HTTPS remote subscription URLs. After deployment,
give each friend a URL in this form:

`https://YOUR-WORKER.workers.dev/sub/FRIEND_ACCESS_KEY`

## One-time setup (account owner)

1. Create a **separate private GitHub repository** for server subscriptions.
   Do not put real server links or keys in the public KHANT VPN app repository.
2. Add a text file such as `servers.txt` to that private repository. Put one
   supported Outline/Shadowsocks, VMess, or VLESS link per line (or the
   subscription format provided by your server panel).
3. In Cloudflare, create a KV namespace named `KHANT_ACCESS_KEYS`.
4. Create a Worker and deploy `worker.js`.
5. Bind the KV namespace to the Worker using the binding name
   `ACCESS_KEYS`.
6. Set these Worker variables:
   - `GITHUB_OWNER`: private repository owner
   - `GITHUB_REPO`: private repository name
   - `GITHUB_FILE`: path to the subscription file, e.g. `servers.txt`
   - `GITHUB_BRANCH`: branch name, usually `main`
7. Add a GitHub fine-grained token as a **Worker secret** named
   `GITHUB_TOKEN`. Give it read-only Contents access to only the private
   subscription repository. Never add this token to the app, this repository,
   or a subscription URL.

## Add or revoke a friend

Generate a unique random access key for each friend (at least 24 URL-safe
characters). In Cloudflare KV, add the key with value `active`. Share only
that friend's subscription URL.

To revoke access, delete that key from KV (or change its value from
`active`). Each friend can then be managed independently.

Do not reuse one key for everyone. A friend can still share their own URL, so
individual keys make revocation possible but cannot technically prevent
someone from copying their URL.

## Important

- This repository contains no real server credentials and no live access keys.
- The Worker is only the private delivery layer. It does not create VPN
  servers, provide bandwidth, or make an expired server key work.
- A working Outline/VMess/VLESS server or provider subscription is still needed.
- Cloudflare deployment and the private GitHub repository require the owner's
  account setup. No account credentials are requested or stored here.
