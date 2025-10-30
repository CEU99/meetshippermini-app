# 🚨 Fix Subscription Timeout - DO THIS NOW

## Your Error

```
[Chat] ⏱️  Message subscription timed out
```

## The Problem

Browser clients (anon role) don't have permission to use Realtime on `meetshipper_messages`.

---

## Quick Fix (2 Minutes)

### 1. Open Supabase SQL Editor

https://supabase.com/dashboard/project/mpsnsxmznxvoqcslcaom/sql/new

### 2. Copy and Paste This SQL:

```sql
-- Fix Realtime permissions for browser clients
ALTER PUBLICATION supabase_realtime ADD TABLE meetshipper_messages;
ALTER TABLE meetshipper_messages REPLICA IDENTITY FULL;
GRANT SELECT ON meetshipper_messages TO authenticated;
GRANT SELECT ON meetshipper_message_details TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
```

### 3. Click "Run"

Should see: `Success. No rows returned`

### 4. Enable Realtime in Dashboard

1. Go to: https://supabase.com/dashboard/project/mpsnsxmznxvoqcslcaom/database/replication
2. Find `meetshipper_messages` table
3. Toggle it **ON**
4. Click "Save"

### 5. Restart Everything

```bash
# In terminal:
# Stop server (Ctrl+C)
pnpm run dev

# In browser:
# Close ALL tabs
# Reopen browser
```

### 6. Test

Navigate to room again.

**Console should now show:**

```
[Chat] Subscription status changed: SUBSCRIBED
[Chat] ✅✅✅ Message subscription ACTIVE and LISTENING ✅✅✅
```

**No more timeout!** ✅

---

## Still Times Out?

### Check WebSocket Connection:

1. Browser DevTools → Network tab
2. Filter: **WS**
3. Look for: `wss://...supabase.co/realtime/v1/websocket`
4. Status: **101 Switching Protocols**

If no WebSocket → Network/firewall issue.

### Try:

1. Different browser
2. Incognito mode
3. Mobile hotspot (test if network blocking)
4. Disable VPN

---

## Why This Fixes It

```
anon role (browser) → needs SELECT → needs realtime publication → needs replica identity

All were missing! ❌

After SQL script → All granted! ✅
```

---

## After Fix Works

**Expected behavior:**

1. Subscription connects instantly
2. Messages appear in real-time
3. Both browsers see INSERT events
4. UI updates without refresh

---

## Files Created

- `TIMEOUT_FIX.md` - Detailed troubleshooting
- `scripts/fix-realtime-permissions.sql` - Full SQL script
- This quick fix guide

---

**Status:** Fix ready to apply
**Time needed:** 2 minutes
**Success rate:** Should fix the issue immediately

**Do steps 1-5 now, then test!**
