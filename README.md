# Hermes Agent on Cloud — Render POC

Deploy your own Hermes AI agent to the cloud. This repo contains a
ready-to-deploy configuration for Render.com, plus custom skills.

**What you get:**
- Hermes agent running 24/7 on Render
- Web dashboard at `https://your-service.onrender.com`
- In-browser chat (full TUI, no terminal needed)
- Persistent disk for skills, sessions, and memory
- Telegram bot support (optional)

---

## Prerequisites

1. **A Render account** — https://render.com (free, no credit card)
2. **An OpenRouter API key** — https://openrouter.ai/keys (free tier available)
3. **A GitHub account** — to host this repo
4. **~10 minutes**

---

## Step-by-Step Deployment Guide

### Step 1: Fork/Copy this Repo to GitHub

Option A — Fork:
```
1. Go to the original repo URL
2. Click "Fork" in the top-right
3. Your copy: github.com/YOUR_USERNAME/hermes-cloud
```

Option B — Create a new repo:
```
1. Create a new repo on GitHub (e.g., "hermes-cloud")
2. Push this folder to it:
```

```bash
cd /Users/sid/test-hermes-render
git init
git add .
git commit -m "Initial Hermes cloud deployment"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/hermes-cloud.git
git push -u origin main
```

---

### Step 2: Get an OpenRouter API Key

```
1. Go to https://openrouter.ai/keys
2. Sign up (free)
3. Click "Create Key"
4. Copy the key (starts with "sk-or-v1-...")
You need this for Step 4.
```

---

### Step 3: Create the Render Service

```
1. Go to https://dashboard.render.com
2. Click "New +" → "Web Service"
3. Connect your GitHub repo ("hermes-cloud")
4. Configure:
   - Name: hermes (or whatever you like)
   - Region: Oregon (or closest to you)
   - Branch: main
   - Runtime: Docker
   - Plan: Free (for POC) or Standard $7/mo (for always-on + Telegram)
5. Click "Create Web Service"
```

---

### Step 4: Set Your API Key

Wait for the build to finish (~2-3 minutes for Docker build). Then:

```
1. In Render Dashboard, go to your service
2. Click "Environment" in the left sidebar
3. Click "Add Environment Variable"
4. Key: OPENROUTER_API_KEY
5. Value: sk-or-v1-... (your actual key)
6. Click "Save Changes"
7. The service will redeploy automatically
```

---

### Step 5: Open the Dashboard

```
1. Copy your service URL from Render (e.g., hermes.onrender.com)
2. Open it in your browser
3. You should see the Hermes dashboard
4. Click the "Chat" tab
5. Start talking to Hermes!
```

---

### Step 6 (Optional): Connect Telegram

```
1. On Telegram, message @BotFather
2. Send /newbot, follow the prompts
3. Copy the bot token (looks like 123456:ABC-DEF...)
4. In Render Dashboard → Environment:
   - Add TELEGRAM_BOT_TOKEN = your token
5. Message @userinfobot on Telegram to get your user ID
6. In Render Dashboard → Environment:
   - Add TELEGRAM_ALLOW_FROM = your user ID
7. Service redeploys
8. Message your bot on Telegram — Hermes should respond!
```

---

## Important Notes

### Free Tier Limitations
- Free tier SLEEPS after 15 min of inactivity
- First request after sleep takes ~30 sec to wake up
- Telegram gateway does NOT work on free tier (needs always-on)
- Upgrade to Standard ($7/mo) for Telegram + always-on

### Where Your Data Lives
- All state (skills, sessions, memory) is on a 5GB persistent disk
- Survives deploys, restarts, and upgrades
- NOT backed up automatically — see "Backups" below

### Security
- Your API keys are set via Render's environment, NOT in the repo
- .env is in .gitignore — never gets committed
- The service is public by default — anyone with the URL can access
- If you add Telegram, only your user ID can interact with the bot

### Backups
To back up your Hermes state:
```
1. Go to your service in Render Dashboard
2. Click "Shell" (if available on your plan)
3. Run: tar -czf /tmp/hermes-backup.tar.gz /opt/data/
4. Download via Render's file browser, OR
5. Set up automated backups with cron to an external location
```

---

## Repo Structure

```
hermes-cloud/
├── Dockerfile              # Docker image definition
├── render.yaml             # Render blueprint (optional, for Blueprint deploys)
├── .env.example            # Template for environment variables
├── .gitignore              # Excludes secrets from git
├── SOUL.md                 # Hermes personality file
├── config/
│   └── config.yaml         # Base configuration (no secrets)
├── skills/
│   ├── agent-security/     # OWASP ASI threat defense
│   └── scrapify/           # Web scraping + AI analysis
└── README.md               # This file
```

---

## Updating Hermes

To update to a new version of Hermes:
```
1. Edit Dockerfile, change the image tag
2. Push to GitHub
3. Render auto-deploys (if autoDeploy is on)
4. Or manually deploy from Render Dashboard
```

To add more skills:
```
1. Copy skill folder into skills/
2. Push to GitHub
3. Redeploy
```

---

## Migrating to a VPS Later

When you're ready to move off Render:
```
1. Same Dockerfile works on any Docker host
2. Same docker-compose.yaml works anywhere
3. Just need to:
   - Provision a VPS (Hetzner CPX22 recommended)
   - Install Docker + docker-compose
   - Copy this repo
   - docker compose up -d
```

The Hermes state (sessions, memory, skills) is on the persistent disk.
You'll need to migrate that separately if you want to keep history.

---

## Troubleshooting

**"Build failed" in Render:**
- Check the build logs in Render Dashboard
- Most common issue: Dockerfile syntax error
- Make sure the base image tag is correct

**"Service crashes on start":**
- Check the service logs in Render Dashboard
- Most common issue: missing OPENROUTER_API_KEY
- Make sure the key is set in Environment variables

**"Chat tab shows error":**
- This is a known upstream bug with the ink-bundle.js
- The dockerCommand in render.yaml already includes the fix
- If it persists, try redeploying

**"Telegram bot doesn't respond":**
- Make sure plan is Standard (not Free — free sleeps)
- Check TELEGRAM_BOT_TOKEN is correct
- Check TELEGRAM_ALLOW_FROM matches your user ID
- Check logs in Render Dashboard
