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
| `OPENROUTER_API_KEY` | `sk-or-v1-...` | Your LLM provider key — Hermes uses this to call the AI model |
| `HERMES_GATEWAY_TOKEN` | any random string | A password for your agent's API. E.g. `mysecrettoken123` |
| `HERMES_DASHBOARD` | `1` | Turns the web dashboard on (`1` = on, `0` = off) |
| `HERMES_DASHBOARD_HOST` | `0.0.0.0` | Makes the dashboard reachable from outside the container (not just localhost) |
| `HERMES_DASHBOARD_PORT` | `8080` | The port Railway expects your app to listen on |
| `HERMES_DASHBOARD_TUI` | `1` | Enables the full chat UI in the browser |
| `GATEWAY_ALLOW_ALL_USERS` | `true` | Lets you log in to the dashboard — without this everyone gets access denied |

#### Optional — for Telegram

| Variable | Value | What it does |
|---|---|---|
| `TELEGRAM_BOT_TOKEN` | `123456789:ABCdef...` | Your bot token from @BotFather — paste carefully, no extra spaces or newlines |
| `TELEGRAM_ALLOW_FROM` | `12345678` | Your numeric Telegram user ID from @userinfobot. Hermes ignores messages from anyone else |

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

## How it all works — file by file

### The Dockerfile

The Dockerfile is a **recipe for building your container**. Think of a container like a
sealed box with an operating system, all the software, and your app pre-installed inside it.
The Dockerfile describes exactly what goes in that box, step by step.

```dockerfile
FROM docker.io/nousresearch/hermes-agent:v2026.5.7
```
**"Start with NousResearch's official Hermes box."**
Instead of building from scratch, we grab the official pre-built Hermes container from
Docker Hub (like downloading a ready-made app). Everything Hermes needs is already inside.
We're just customising it on top.

```dockerfile
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*
```
**"Switch to admin mode and install `curl`."**
`USER root` = run the next commands as the system administrator (like right-clicking
"Run as Administrator" on Windows).
`apt-get install curl` = install the `curl` tool, which is needed for Railway to check
whether the app is alive (the health check hits `/api/status` using curl under the hood).
`rm -rf /var/lib/apt/lists/*` = delete the installer cache afterwards to keep the image small.

```dockerfile
COPY --chown=hermes:hermes config/config.yaml /opt/hermes/config.yaml
COPY --chown=hermes:hermes SOUL.md /opt/hermes/SOUL.md
```
**"Copy your custom files into the box — but put them in a safe drawer."**
This is the tricky part. Hermes normally stores everything (config, memory, sessions) in
a folder called `/opt/data`. But Railway plugs in a persistent hard drive at exactly that
path, which hides anything baked into the image at `/opt/data`.

So instead, we copy our files into `/opt/hermes/` — a different folder that Railway's
hard drive doesn't cover. They stay accessible no matter what.

`--chown=hermes:hermes` = make these files owned by the `hermes` user (not root),
so Hermes can read them when it runs.

---

### The railway.toml

This file is **Railway's instruction manual**. Railway reads it automatically when it
detects it in your repo. Without it, Railway guesses how to run your app and usually
gets it wrong.

```toml
[build]
builder = "DOCKERFILE"
dockerfilePath = "Dockerfile"
```
**"Build the container using the Dockerfile in this repo."**
By default Railway uses its own auto-detection system (called Railpack). This line
overrides that and says "use our Dockerfile instead". Without this, Railway ignores
the Dockerfile entirely and the custom config never gets included.

```toml
[deploy]
startCommand = "/bin/sh -c 'chown -R hermes:hermes /opt/data && cp /opt/hermes/config.yaml /opt/data/config.yaml && touch /opt/hermes/ui-tui/packages/hermes-ink/dist/ink-bundle.js /opt/hermes/ui-tui/dist/entry.js && chown -R hermes:hermes /opt/hermes/ui-tui /opt/hermes/node_modules && exec /usr/bin/tini -g -- /opt/hermes/docker/entrypoint.sh gateway run'"
```
**"Run this exact sequence of commands every time the container starts."**
This is the most important line. It runs five things in order before Hermes boots:

1. **`chown -R hermes:hermes /opt/data`**
   Railway's persistent volume (the hard drive at `/opt/data`) is initially owned by
   the system root user. Hermes runs as a limited user called `hermes` who can't write
   to root-owned folders. This command hands ownership of the volume to the `hermes`
   user so it can create its folders (sessions, memory, logs, etc.).

2. **`cp /opt/hermes/config.yaml /opt/data/config.yaml`**
   Copies our custom config (with the free `owl-alpha` model) from the safe drawer
   into `/opt/data/` where Hermes looks for it. Without this step, Hermes reads its
   hardcoded default config and uses `claude-opus-4.6`, which is expensive and hits
   rate limits immediately.

3. **`touch /opt/hermes/ui-tui/packages/hermes-ink/dist/ink-bundle.js` and `touch /opt/hermes/ui-tui/dist/entry.js`**
   `touch` creates empty files if they don't already exist. Hermes's web UI code
   expects these two JavaScript bundle files to be present on disk or it errors on
   startup. These files are generated during a full build but may be missing in the
   Docker image.

4. **`chown -R hermes:hermes /opt/hermes/ui-tui /opt/hermes/node_modules`**
   Gives the `hermes` user ownership of the UI files and Node.js packages so it can
   read and serve them.

5. **`exec /usr/bin/tini -g -- /opt/hermes/docker/entrypoint.sh gateway run`**
   Actually starts Hermes. `tini` is a tiny process manager that handles signals
   properly (so Ctrl+C and Railway restarts work cleanly). It runs Hermes's own
   `entrypoint.sh` script with the argument `gateway run`, which starts both the
   web dashboard and the messaging gateway (Telegram etc.).

```toml
healthcheckPath = "/api/status"
healthcheckTimeout = 300
```
**"Check if the app is alive by hitting this URL. Wait up to 5 minutes."**
Railway repeatedly calls `https://your-app.up.railway.app/api/status` after the
container starts. If it gets a successful response, the deployment is marked as
successful. If it never responds within 300 seconds (5 minutes), the deployment
is marked as failed. Hermes takes ~60-90 seconds to fully boot, so we give it plenty
of headroom.

```toml
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 3
```
**"If the app crashes, restart it automatically. Give up after 3 crashes."**

```toml
numReplicas = 1
```
**"Run exactly one copy of this container."** (More = load balancing, which we don't need.)

---

### config/config.yaml

This is **Hermes's settings file**. The most important part:

```yaml
model:
  default: openrouter/owl-alpha
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
```
Sets which AI model Hermes uses. `openrouter/owl-alpha` is a free model — no cost
per message. Without this file loading correctly, Hermes defaults to
`anthropic/claude-opus-4.6` which costs money and will immediately fail with a 402 error
if your OpenRouter account has no credits.

```yaml
terminal:
  backend: docker
```
When Hermes runs code (e.g., a Python script), it spins up a separate Docker container
to run it in, instead of running it directly. Safer and more isolated.

```yaml
approvals:
  mode: manual
```
Hermes asks for your approval before running any tool (like running code or browsing the web).
Change to `auto` if you want it to act without asking.

---

### SOUL.md

This is **Hermes's personality file**. It's essentially a system prompt — instructions that
define how your agent should behave, what it's called, its tone, what it knows, and what
it should focus on. Hermes reads this on startup and uses it as the base context for every
conversation. You can edit it to give your agent a different name, personality, or set of
priorities.

---

### The volume problem (why the config injection was needed)

This tripped us up during deployment and is worth understanding.

Imagine Hermes's data folder `/opt/data` is a physical filing cabinet in the office.

**During the Docker build:** We put our `config.yaml` in that cabinet at `/opt/data/config.yaml`. ✅

**When Railway starts the container:** Railway rolls in its own filing cabinet (the persistent
volume) and places it in exactly the same spot. Our original cabinet gets pushed behind it —
completely inaccessible. Hermes opens the new cabinet, finds it empty, and uses its hardcoded
defaults instead of our config. ❌

**The fix:** During the build, we put the config in `/opt/hermes/config.yaml` instead — a
different spot Railway's cabinet doesn't cover. Then, every time the container boots, the
first thing the start command does is copy that file into the right cabinet (`/opt/data/`)
before Hermes opens it. ✅

---

## Troubleshooting

**Build shows "Railpack" instead of "Dockerfile":**
Railway isn't connected to your GitHub repo. Go to service → Settings → Source and reconnect.

**"Permission denied" errors in deploy logs (`mkdir: cannot create directory '/opt/data/...'`):**
The `chown` in the start command handles this. Make sure `railway.toml` is committed and pushed.

**Model shows `anthropic/claude-opus-4.6` and you get 402 errors:**
The config injection isn't working. Check that `config/config.yaml` exists in the repo and
that the Dockerfile COPY line is present. Redeploy after fixing.

**Telegram: "InvalidURL" or connection errors:**
Your `TELEGRAM_BOT_TOKEN` has a trailing newline from copy-paste. Delete the variable in
Railway, then re-add it — paste the token and make sure there's no blank line after it.

**Telegram bot doesn't respond to your messages:**
Set `TELEGRAM_ALLOW_FROM` to your numeric user ID (get it from @userinfobot on Telegram).
Without this, Hermes silently ignores all messages.

**Healthcheck fails (service unavailable) after 5 minutes:**
Check the Deploy Logs for the actual error. Common cause: a missing required environment
variable like `OPENROUTER_API_KEY`.

**Web dashboard says access denied:**
Add `GATEWAY_ALLOW_ALL_USERS=true` to Railway Variables.

**Docker backend warning in logs (media file delivery):**
This is harmless for basic use. It only matters if you ask Hermes to generate and send
image/video files via Telegram. Ignore it for now.

---

## Running locally (for testing)

```bash
cp .env.example .env
# Edit .env with your real API keys

docker compose up
```

Open http://localhost:8642 in your browser. Local runs use port 8642 (not 8080).

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
