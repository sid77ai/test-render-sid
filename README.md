# Hermes Agent on Cloud — Render POC

Deploy your own Hermes AI agent to the cloud. This repo contains a
ready-to-deploy configuration for Render.com, plus custom skills.

**What you get:**
- Hermes agent running 24/7 on Render
- Web dashboard at `https://your-service.onrender.com`
- In-browser chat (full TUI, no terminal needed)
- Persistent disk for skills, sessions, and memory
- Telegram bot support

---

## Prerequisites

1. **A Render account** — https://render.com (free signup, credit card required for Standard plan)
2. **An OpenRouter API key** — https://openrouter.ai/keys (free tier available)
3. **A Telegram bot** — create one via @BotFather on Telegram
4. **Your Telegram user ID** — get it from @userinfobot on Telegram
5. **A GitHub account** — to host this repo

---

## Step-by-Step Deployment Guide

### Step 1: Push this Repo to GitHub

```bash
cd /Users/sid/test-hermes-render
git init
git add .
git commit -m "Hermes cloud deployment"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/test-render-sid.git
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username.

---

### Step 2: Deploy to Render

```
1. Go to https://dashboard.render.com/blueprints
2. Click "New Blueprint Instance"
3. Connect your GitHub account if not already
4. Select your repo "test-render-sid"
5. Render reads render.yaml and shows you the service config
6. Click "Apply"
7. Render creates the service and starts deploying
```

**Note:** The first deploy takes ~3-5 minutes. It pulls the Docker image and starts the gateway.

---

### Step 3: Set Your API Keys in Render

```
1. In your Render Dashboard, click on your new service
2. Click "Environment" in the left sidebar
3. Add these environment variables:

   OPENROUTER_API_KEY = sk-or-v1-...     (your actual key)
   TELEGRAM_BOT_TOKEN = 123456:ABC...    (from @BotFather)
   TELEGRAM_HOME_CHANNEL = 8630066373    (your user ID from @userinfobot)

4. Click "Save Changes"
5. The service redeploys automatically with the new keys
```

---

### Step 4: Test It

**Dashboard:**
```
1. Copy your service URL from Render (e.g., test-render-sid.onrender.com)
2. Open it in your browser
3. You should see the Hermes dashboard
4. Click "Chat" tab
5. Start chatting
```

**Telegram:**
```
1. Open Telegram
2. Find your new bot (search by username you gave it)
3. Send /start
4. Send any message
5. Hermes should respond
```

---

## Important: Free vs Standard Plan

| Feature | Free | Standard ($7/mo) |
|---------|------|-------------------|
| Dashboard | Yes (sleeps after 15min) | Yes (always on) |
| Telegram | No (sleeps = no polling) | Yes |
| Persistent disk | Yes | Yes |
| Credit card needed | No | Yes |

**For the POC with Telegram, you need Standard ($7/mo).**

If you just want to test the dashboard first, Free works. You can upgrade later from Render Dashboard → Plan.

---

## Security Notes

- **NO secrets in GitHub.** The `render.yaml` has empty values. Real keys go in Render's Environment tab.
- **Telegram bot only responds to your user ID.** Set `TELEGRAM_HOME_CHANNEL` to your ID.
- **Dashboard is public by default.** Anyone with the URL can access it.

---

## Repo Structure

```
test-render-sid/
├── render.yaml             # Render Blueprint config (no secrets!)
├── docker-compose.yaml     # For local testing / future VPS migration
├── .env.example            # Template showing what keys to set
├── .gitignore              # Excludes .env, state.db, sessions/
├── .dockerignore
├── SOUL.md                 # Hermes personality
├── config/
│   └── config.yaml         # Base config (no secrets)
├── skills/
│   ├── agent-security/     # OWASP ASI threat defense
│   └── scrapify/           # Web scraping + security
└── README.md               # This file
```

---

## Troubleshooting

**"Deploy failed":**
- Check build logs in Render Dashboard
- Make sure the repo is pushed to the correct branch (main)

**"Service crashes":**
- Check service logs in Render Dashboard
- Most common: missing OPENROUTER_API_KEY
- Add the key in Environment tab and redeploy

**"Telegram bot doesn't respond":**
- Make sure plan is Standard (not Free)
- Check TELEGRAM_BOT_TOKEN is correct
- Check TELEGRAM_HOME_CHANNEL matches your user ID
- Check logs for errors

**"Chat tab shows error":**
- Known upstream bug. The dockerCommand fix should handle it.
- Try redeploying if it persists.

---

## Migrating to a VPS Later

When ready to move off Render:
```bash
# On your VPS:
git clone https://github.com/YOUR_USERNAME/test-render-sid.git
cd test-render-sid
cp .env.example .env
# Edit .env with your keys
docker compose up -d
```

Same Dockerfile, same config, different host.
