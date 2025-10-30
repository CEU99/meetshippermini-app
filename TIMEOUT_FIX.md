# Real-Time Subscription Timeout - FIX 🔧

## Error Identified

```
[Chat] ⏱️  Message subscription timed out
```

This means the subscription is trying to connect but **failing to establish a connection** within the timeout period.

---

## Root Cause

The **anon role** (used by browser clients) does not have permission to access Realtime on the `meetshipper_messages` table.

The test script worked because it used the **service_role** key, which has full access.
Browser clients use the **anon** key, which needs explicit permissions.

---

## Quick Fix (2 minutes)

### Step 1: Apply SQL Permissions Fix

1. **Go to Supabase SQL Editor:**
   ```
   https://supabase.com/dashboard/project/mpsnsxmznxvoqcslcaom/sql/new
   ```

2. **Copy and paste this entire SQL script:**

```sql
-- Grant Realtime permissions for browser clients

-- Add table to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE meetshipper_messages;

-- Set replica identity
ALTER TABLE meetshipper_messages REPLICA IDENTITY FULL;

-- Grant SELECT to authenticated role
GRANT SELECT ON meetshipper_messages TO authenticated;
GRANT SELECT ON meetshipper_message_details TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
```

3. **Click "Run"**

4. **Verify output shows:**
   ```
   Success. No rows returned
   ```

### Step 2: Enable Realtime in Dashboard

1. **Go to Database → Replication:**
   ```
   https://supabase.com/dashboard/project/mpsnsxmznxvoqcslcaom/database/replication
   ```

2. **Find `meetshipper_messages` table**

3. **Toggle it ON** if it's not already enabled

4. **Click "Save"**

### Step 3: Restart Everything

```bash
# Stop dev server (Ctrl+C)

# Restart
pnpm run dev
```

### Step 4: Close and Reopen Browser

**Important:** Close ALL browser tabs and reopen.

This ensures a fresh WebSocket connection.

### Step 5: Test Again

1. Open two browsers (with DevTools)
2. Navigate to same room
3. Check console

**Should now see:**
```
[Chat] Subscription status changed: SUBSCRIBED
[Chat] ✅✅✅ Message subscription ACTIVE and LISTENING ✅✅✅
```

---

## Why This Happens

### The Permission Chain

```
Browser Client (anon key)
      ↓
Needs SELECT on table
      ↓
Needs table in realtime publication
      ↓
Needs REPLICA IDENTITY set
      ↓
Then Realtime works! ✅
```

### What Was Missing

1. **Table not in publication** for anon role
2. **SELECT permission** not granted to authenticated role
3. **Realtime not enabled** in Dashboard for this table

---

## Verification Steps

### After Applying Fix

**Run in Supabase SQL Editor:**

```sql
-- Check if table is in publication
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'meetshipper_messages';

-- Should return 1 row
```

**Check permissions:**

```sql
-- Verify authenticated role has access
SELECT has_table_privilege('authenticated', 'meetshipper_messages', 'SELECT');

-- Should return: true
```

**Check replica identity:**

```sql
-- Verify REPLICA IDENTITY
SELECT relreplident
FROM pg_class
WHERE relname = 'meetshipper_messages';

-- Should return: f (FULL)
```

---

## Alternative: Full Script

If you prefer to use the complete script I created:

1. **Open:**
   ```
   scripts/fix-realtime-permissions.sql
   ```

2. **Copy entire file**

3. **Paste in Supabase SQL Editor**

4. **Run**

5. **Should see:**
   ```
   ✅ Added meetshipper_messages to realtime publication
   ✅ Set REPLICA IDENTITY to FULL
   ✅ Granted SELECT on meetshipper_messages to authenticated
   ✅ Granted SELECT on meetshipper_message_details to authenticated
   ✅ Granted USAGE on schema public to authenticated
   ✅ RLS policy for viewing messages exists
   ✅ Permission test passed
   🎉 Realtime Permissions Configuration Complete!
   ```

---

## Testing After Fix

### Expected Console Output

**Opening room:**
```
[Chat] 🚀 Initializing real-time subscriptions for room: abc123...
[Chat] Supabase URL: https://mpsnsxmznxvoqcslcaom.supabase.co
[Chat] Channel name: room:abc123...
[Chat] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Chat] Subscription status changed: SUBSCRIBED
[Chat] ✅✅✅ Message subscription ACTIVE and LISTENING ✅✅✅
[Chat] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Sending message:**
```
[Chat] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Chat] 🎉 INSERT EVENT RECEIVED FOR ROOM: abc123...
[Chat] Content: Test message
[Chat] ✅ UI SHOULD UPDATE NOW
```

---

## If Still Times Out After Fix

### Check WebSocket Connection

1. **Open Browser DevTools**
2. **Go to Network tab**
3. **Filter: WS (WebSocket)**
4. **Look for:** `wss://mpsnsxmznxvoqcslcaom.supabase.co/realtime/v1/websocket`
5. **Status should be:** `101 Switching Protocols`

**If no WebSocket connection:**
- Firewall blocking WebSockets
- Corporate network restrictions
- VPN interfering

### Check Supabase Status

Visit: https://status.supabase.com

Verify no outages.

### Check Browser Console Errors

Look for:
- WebSocket connection errors
- CORS errors
- Network errors

### Try Different Network

Test on:
- Mobile hotspot
- Different WiFi
- Different computer

This helps rule out network issues.

---

## Common Errors After Fix

### Error: "insufficient_privilege"

**SQL Output:**
```
ERROR: permission denied for table meetshipper_messages
```

**Fix:**
Re-run the GRANT statements:
```sql
GRANT SELECT ON meetshipper_messages TO authenticated;
GRANT SELECT ON meetshipper_message_details TO authenticated;
```

### Error: "relation does not exist"

**Means:** Migration not applied

**Fix:** Run the migration:
```bash
npx tsx scripts/check-message-setup.ts
```

### Still Times Out

**Last resort steps:**

1. **Disable and re-enable Realtime:**
   - Dashboard → Database → Replication
   - Toggle meetshipper_messages OFF
   - Wait 10 seconds
   - Toggle ON
   - Save

2. **Restart Supabase (if self-hosted):**
   - Not applicable for cloud Supabase

3. **Contact Supabase support:**
   - Dashboard → Support
   - Mention "Realtime subscription timeout"
   - Provide project ID: mpsnsxmznxvoqcslcaom

---

## Success Checklist

After applying the fix, verify ALL of these:

- [ ] SQL script ran without errors
- [ ] Realtime enabled in Dashboard for meetshipper_messages
- [ ] Dev server restarted
- [ ] Browser completely closed and reopened
- [ ] Console shows "SUBSCRIBED" (not TIMED_OUT)
- [ ] No WebSocket errors in Network tab
- [ ] INSERT events received when sending messages
- [ ] Messages appear in real-time in both browsers

---

## Summary

**Problem:** Subscription timeout
**Cause:** Anon role lacks Realtime permissions
**Fix:** Run SQL script + Enable in Dashboard + Restart

**Steps:**
1. Run `scripts/fix-realtime-permissions.sql` in Supabase SQL Editor
2. Enable Realtime in Dashboard → Database → Replication
3. Restart dev server and browser
4. Test again

**Expected:** Subscription changes from TIMED_OUT to SUBSCRIBED ✅

---

**File Created:** `scripts/fix-realtime-permissions.sql`
**Status:** Ready to apply
**Time to fix:** ~2 minutes
