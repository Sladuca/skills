---
name: ship
description: Deploy one of Seb's personal apps with as little thought as possible, on Cloudflare by default. Use for /ship, "deploy this", "put this online", "ship it", starting a new app that will be hosted, redeploying, checking what's deployed, or taking an app down.
---

# Ship a personal app

These are low-traffic personal apps, and an app nobody is using should cost about $0. Deploy to Cloudflare unless the app needs something Cloudflare cannot run. Don't ask Seb to pick a platform, a framework, or a language. Decide, deploy, and report the URL.

Cloudflare's official skills (`cloudflare`, `cf-cli`, `wrangler`, `frameworks-on-cloudflare`, `durable-objects`, `sandbox-*`) hold the current product and CLI details. Load the matching one before you write Cloudflare code or run Cloudflare commands. Your training data on Workers is likely stale. If those skills are missing, tell Seb to run `/plugin marketplace add cloudflare/skills` and then `/plugin install cloudflare@cloudflare`. Until then, fall back to `https://developers.cloudflare.com/cf/llms.txt`.

## Settings

- Domains: none yet. Every app uses its default `*.workers.dev` URL unless it has a domain of its own. Domains are per app, not one shared domain.
- Owned domains: (none). Add one line per domain as Seb buys them, e.g. `example.com: used by <app>` or `example.com: free subdomains`.
- Cloudflare account: credentials come from the `cloudflare` agent-secret profile (see Credentials).
- Plan: Workers Paid ($5/month) with usage notifications on. Don't raise any limits without asking.

## 1. Pick the platform by what the app needs

Use the first row that matches:

| The app needs | Platform |
| --- | --- |
| A GPU, or heavy batch compute | Modal, through `modal-agent` |
| A native binary or a full Linux process (ffmpeg, a headless browser, a Python ML stack, a long-running daemon) | Cloudflare Containers or Sandbox, called from a Worker. Load the `sandbox-*` skills. |
| Something Containers can't do, or an existing app built around a Dockerfile | Fly.io (see "Fly fallback") |
| Anything else: a website, an API, CRUD, auth, cron jobs, queues, websockets, realtime | Cloudflare Workers |

Storage on Cloudflare is D1 for relational data, R2 for files, KV for small config or cache, and Durable Objects for per-room or per-user state with coordination. Move to Neon Postgres only when D1's size or feature limits block the app. Never run a database on a VM.

Language follows the platform. Use TypeScript on Workers, and anything inside a container. Don't add Python to a Worker just because a library is familiar.

## 2. New app

1. Put it in its own directory, named in kebab-case. The name becomes the Worker name and the subdomain.
2. Create it with `cf init`, through the `cf-cli` skill, or with a framework through `frameworks-on-cloudflare`. Take the official template's defaults, and don't invent a custom layout. Add `cf` as a dev dependency so the version stays pinned.
3. Add `GET /api/health`, which returns `200` and `{"ok":true}`. Deploy verification uses it.
4. Turn on observability (Workers Logs) in the config.
5. Keep secrets out of git. Set them with the CLI's secret command. Local values go in a gitignored `.dev.vars` or `.env`.
6. If the app has a login or private data, put it behind Cloudflare Access, or have the app check auth. Never deploy private data to an open URL.

An existing project that has `wrangler.jsonc`, `wrangler.json`, or `wrangler.toml` stays on Wrangler (the `wrangler` skill). Don't migrate it as part of a deploy.

## 3. Deploy

1. Run the app's own checks first: typecheck, tests, and a build if it has one.
2. Create the D1, R2, and KV resources it uses, if they don't exist yet, and apply D1 migrations to the remote database.
3. Deploy with the credentials profile:

   ```sh
   agent-secret run cloudflare -- npx cf deploy
   ```

   On a Wrangler project, use `agent-secret run cloudflare -- npx wrangler deploy`.
4. Verify against the live URL, not the CLI's exit code. `curl` `/api/health`, then load the main page or hit one real endpoint. A deploy isn't done until the live check passes.
5. Report the URL, what was created (Worker, database, bucket), and anything that costs money even when idle. On Cloudflare that's normally nothing.

## Domains

Only Seb buys domains. Buying one costs money and can't be undone, so never purchase or renew one, even if the API allows it. When an app should have a domain:

1. Suggest a few names. Tell Seb to buy one through Cloudflare Registrar in the dashboard, which sells at cost and puts the zone in the same account. A domain bought somewhere else must be added as a Cloudflare zone, with its nameservers pointed at Cloudflare.
2. Once the zone is active, attach the domain to the Worker as a Custom Domain in the project config. Use either the apex domain or `<app>.<domain>`. Then redeploy. The token needs Workers Routes: Edit and DNS: Edit on that zone. If it doesn't have them, name the missing permissions and stop.
3. Check the live custom URL, including HTTPS. The certificate can take a few minutes to issue. Keep the `workers.dev` URL working unless Seb asks to turn it off.
4. Add the domain to the Owned domains list in Settings.

## Credentials

- Run Cloudflare commands through `agent-secret run cloudflare -- …`. Never print the token, write it to disk, put it in `.env`, or ask Seb to paste it into chat.
- If `agent-secret check cloudflare` fails, stop and tell Seb to add the profile from the trusted Mac:
  `agent-secret-put cloudflare CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID`
- If a command fails with a permission error, name the missing token permission. Don't look for a workaround.

## Fly fallback

Use Fly only after the routing table sends an app there, and say why in the report.

- In `fly.toml`, set `auto_stop_machines = "stop"`, `auto_start_machines = true`, and `min_machines_running = 0`. Use the smallest shared-CPU machine that runs the app.
- Avoid Fly volumes. They're billed while the machine is stopped. Use R2 or Neon for data.
- Fly has no hard spend cap, so list in the report anything that bills while idle.
- Credentials work the same way: an agent-secret `fly` profile with `FLY_API_TOKEN`. If it's missing, ask Seb to add it.

## Status and teardown

- To see what's deployed, list Workers, D1 databases, and R2 buckets with the CLI, plus `fly apps list` if Fly is in use. Point out anything that costs money while idle.
- To take an app down, delete its Worker. Delete its database and bucket only after Seb confirms, because that destroys data. Also remove its custom domain.
