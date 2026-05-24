# Hermes Agent on Railway

Deploy your own Hermes AI agent to Railway. This repo gives you a working
configuration with custom skills and a personality. Hermes runs 24/7, has a
web dashboard you can chat with, and connects to Telegram.

---

## What you get

- Hermes agent running 24/7 on Railway (~$5/month on the Hobby plan)
- Web dashboard at `https://your-service.up.railway.app`
- Chat with Hermes directly in the browser
- Telegram bot — message your agent from your phone
- Uses `openrouter/owl-alpha` — a free model (no API costs)
- Persistent storage for memory, sessions, and skills

---

## Prerequisites — get these first

1. **Railway account** — https://railway.app (free signup, Hobby plan ~$5/mo for always-on)
2. **GitHub account** — Railway deploys from GitHub
3. **OpenRouter API key** — https://openrouter.ai/keys (free, no credit card)
4. **Telegram bot token** — message @BotFather on Telegram, send `/newbot`, follow the steps
5. **Your Telegram user ID** — message @userinfobot on Telegram, it replies with your numeric ID

---

## How to deploy — step by step

### Step 1 — Push this repo to GitHub

If you haven't already:

```bash
git init
git add .
git commit -m "initial commit"
git branch -M master
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git push -u origin master
```

Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your actual values.

---

### Step 2 — Create a new project on Railway

1. Go to https://railway.app → click **New Project**
2. Choose **Deploy from GitHub repo**
3. Connect your GitHub account if prompted
4. Select this repo from the list
5. Railway detects `railway.toml` and automatically sets up the build

**Important:** Railway should show **Builder: Dockerfile** in the build logs.
If it shows "Railpack", the repo connection didn't work — try reconnecting.

---

### Step 3 — Add a persistent volume

Hermes needs a place to store memory, sessions, and user data that survives restarts.

1. Go to your Railway service → click the **+ Add Volume** button (or go to Settings → Add Volume)
2. Set the mount path to: `/opt/data`
3. Give it any name (e.g., `hermes-data`)
4. Railway will attach it automatically on next deploy

---

### Step 4 — Set your environment variables

Go to your Railway service → **Variables** tab → add each of these:

#### Required — Hermes won't start without these

| Variable | Value | What it does |
|---|---|---|
| `OPENROUTER_API_KEY` | `sk-or-v1-...` | Your LLM provider key (get from openrouter.ai) |
| `HERMES_GATEWAY_TOKEN` | any random string | Protects your agent's API. E.g. `mysecrettoken123` |
| `HERMES_DASHBOARD` | `1` | Turns on the web dashboard |
| `HERMES_DASHBOARD_HOST` | `0.0.0.0` | Makes the dashboard reachable from outside |
| `HERMES_DASHBOARD_PORT` | `8080` | The port Railway routes traffic to |
| `HERMES_DASHBOARD_TUI` | `1` | Enables the full chat UI in the browser |
| `GATEWAY_ALLOW_ALL_USERS` | `true` | Lets you log in to the dashboard (without this, access is blocked) |

#### Optional — for Telegram

| Variable | Value | What it does |
|---|---|---|
| `TELEGRAM_BOT_TOKEN` | `123456789:ABCdef...` | Your bot token from @BotFather — paste carefully, no extra spaces or newlines |
| `TELEGRAM_ALLOW_FROM` | `12345678` | Your numeric Telegram user ID from @userinfobot. Without this Hermes ignores all Telegram messages |

---

### Step 5 — Deploy

After setting variables, Railway redeploys automatically. Watch the **Deploy Logs** tab.

A successful startup looks like:

```
Dropping root privileges
Syncing bundled skills...
Starting hermes dashboard on 0.0.0.0:8080 (background)
Hermes Web UI → http://0.0.0.0:8080
Hermes Gateway Starting...
```

The first deploy takes 3–5 minutes — it's pulling and building a 2.6 GB image.

---

### Step 6 — Test it

**Web dashboard:**
1. Go to Railway → your service → click the public URL (e.g. `https://hermes-production-xxxx.up.railway.app`)
2. You should see the Hermes web UI
3. Click the chat area and start typing

**Telegram:**
1. Open Telegram and find your bot (search by the username you gave it in @BotFather)
2. Send it any message
3. Hermes should reply within a few seconds

---

## Why HERMES_CONFIG is needed (the volume problem explained simply)

Hermes stores all its data — config, sessions, memory — in a folder called `/opt/data`.
Railway also mounts your persistent volume (the hard drive from Step 3) at `/opt/data`.

When the volume plugs in, it **replaces** everything that was at `/opt/data` in the image.
That means your `config/config.yaml` (which sets the free `owl-alpha` model) gets hidden —
Hermes never sees it and falls back to its built-in default model (`claude-opus-4.6`),
which costs money and hits rate limits immediately.

The fix in this repo: `config.yaml` is copied to `/opt/hermes/config.yaml` during build —
a folder Railway's volume doesn't touch. The start command in `railway.toml` then copies
it into `/opt/data/config.yaml` every time the container boots, before Hermes reads it.

---

## What each file does

```
├── Dockerfile              # Builds your custom Hermes image on top of the official one
├── railway.toml            # Tells Railway how to build and run the container
├── docker-compose.yaml     # For running Hermes locally (not used by Railway)
├── render.yaml             # Old config for Render.com — ignore this
├── .env.example            # Template of all env vars — do NOT put real keys here
├── .gitignore              # Keeps secrets and temp files out of GitHub
├── SOUL.md                 # Hermes's personality — what it's called, how it talks
├── config/
│   └── config.yaml         # Sets the model (owl-alpha), agent settings, tool config
└── skills/
    ├── agent-security/     # Custom skill: security threat analysis
    └── scrapify/           # Custom skill: web scraping
```

### Dockerfile — what each line does

```dockerfile
FROM docker.io/nousresearch/hermes-agent:v2026.5.7
```
Start from the official Hermes image. Like buying a pre-built PC.

```dockerfile
USER root
RUN apt-get install curl
```
Install `curl` as root. Needed for Railway's health check to reach `/api/status`.

```dockerfile
COPY config/config.yaml /opt/hermes/config.yaml
COPY SOUL.md /opt/hermes/SOUL.md
```
Copy your config and personality into `/opt/hermes/` — a folder Railway's volume
doesn't overlay, so these files are always accessible.

### railway.toml — what each line does

```toml
[build]
builder = "DOCKERFILE"          # Use the Dockerfile above (not Railway's auto-detection)

[deploy]
startCommand = "..."            # Runs when the container boots (fixes permissions, then starts Hermes)
healthcheckPath = "/api/status" # Railway pings this to know the app is alive
healthcheckTimeout = 300        # Give Hermes up to 5 minutes to start (it's slow)
restartPolicyType = "ON_FAILURE"# Restart automatically if it crashes
```

The start command does three things in order:
1. `chown -R hermes:hermes /opt/data` — fixes permissions on the mounted volume so Hermes can write to it
2. `touch ...` — creates two UI files that Hermes expects to exist
3. `exec /usr/bin/tini -- entrypoint.sh gateway run` — actually starts Hermes

---

## Troubleshooting

**Build fails immediately:**
- Check you're connected to GitHub (not Docker Hub image mode)
- Railway service → Settings → Source should show your GitHub repo

**"Permission denied" errors in deploy logs:**
- The volume permissions fix in the start command handles this — make sure railway.toml is in your repo and Railway is reading it

**Model shows `claude-opus-4.6` instead of `owl-alpha`:**
- `HERMES_CONFIG` variable is missing or wrong — set it to `/opt/hermes/config.yaml`
- Check Railway Variables tab

**Telegram: "InvalidURL" or connection errors:**
- Your `TELEGRAM_BOT_TOKEN` has a trailing newline — re-paste it carefully
- Make sure `TELEGRAM_ALLOW_FROM` is set to your numeric user ID (not your username)

**Healthcheck fails (service unavailable):**
- Hermes takes 60–90 seconds to fully start after the container boots
- If it times out after 5 minutes, check deploy logs for the actual error

**"Gateway failed to connect any configured messaging platform":**
- Your Telegram token is invalid — check it in Railway Variables
- Or set `TELEGRAM_BOT_TOKEN` to empty string to disable Telegram

**Web dashboard loads but says access denied:**
- Add `GATEWAY_ALLOW_ALL_USERS=true` to Railway Variables

---

## Running locally (for testing)

```bash
cp .env.example .env
# Edit .env and fill in your real API keys

docker compose up
```

Open http://localhost:8642 in your browser.

---

## Migrating to a VPS later

When you want to move off Railway:

```bash
# On your VPS (Hetzner, DigitalOcean, etc.)
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
cp .env.example .env
# Edit .env with your keys
docker compose up -d
```

The same Dockerfile and config work everywhere.
