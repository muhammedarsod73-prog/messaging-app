# 💬 DuoChat - 2-Person WhatsApp Clone (Flutter + Free Supabase)

A high-performance, private 2-person WhatsApp clone built with **Flutter 3** and **Supabase (100% Free Tier)**. Designed exclusively for instant 1-on-1 text messaging between couples, best friends, or private pairs.

---

## 🌟 Key Features

- **WhatsApp Dark Emerald Theme**: Authentic WhatsApp aesthetic (`#075E54`, `#128C7E`, `#25D366`, `#111B21`, `#202C33`, `#0B141A`).
- **Real-Time Text Messaging**: Powered by Supabase Realtime WebSockets for instant message delivery.
- **Read Receipts & Ticks**: `✓` Sent, `✓✓` Delivered, `✓✓` Blue Read ticks.
- **Live Typing & Online Indicators**: Real-time status update badges ("typing...", "online").
- **Message Reactions & Quote Replies**: Double-tap or long-press to react with emojis (❤️, 😂, 👍, 😮, 😢, 🔥) and quote reply to specific messages.
- **Text Search & Starred Messages**: Fast local searching and favorite message starring.
- **Custom Wallpapers**: WhatsApp Dark, WhatsApp Emerald, Solid Midnight, Deep Charcoal, and Light Doodle.
- **Passcode Privacy Lock**: 4-Digit PIN screen gate for extra privacy.
- **Dual-Role Switcher ("User A" vs "User B")**: Switch roles in 1 tap directly from the app bar to test 2-way real-time messaging on a single device or across devices.

---

## 🚀 Free Supabase Backend Setup (1-Click SQL)

1. Create a free account at [supabase.com](https://supabase.com).
2. Create a new project.
3. Open the **SQL Editor** in your Supabase Dashboard.
4. Copy and paste the contents of `supabase_schema.sql` (found in this project's root) into the SQL editor and click **Run**.
5. Copy your **Project URL** and **Anon API Key** from Project Settings -> API.
6. Paste your credentials into `lib/services/supabase_service.dart` or via the **Settings -> Supabase Free Cloud Backend** screen inside the app!

---

## 📱 How to Run the App

```bash
# 1. Install dependencies
flutter pub get

# 3. Run on Android, iOS, Web, or Desktop
flutter run
```

---

## 🤖 GitHub Auto-Release Setup

1. Create a repository on GitHub named **`duo-chat`** (or your preferred name).
2. Initialize and push your project to GitHub:
   ```bash
   git init
   git add .
   git commit -m "Initial commit - DuoChat Release"
   git branch -M main
   git remote add origin https://github.com/dinuwa2500/duo-chat.git
   git push -u origin main
   ```
3. **Automatic APK Release**:
   - Every time you push to `main` (or create a git tag like `v1.0.0`), GitHub Actions will automatically compile `app-release.apk` and publish a **GitHub Release** on your repo page!
   - You can download your APK anytime from `https://github.com/dinuwa2500/duo-chat/releases`.

---

## 🔒 100% Free & Private Forever

Supabase's free plan provides 500MB of database storage and unlimited real-time WebSocket messages, which will easily support years of 2-person text messaging without any cost.
