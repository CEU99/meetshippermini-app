# Dev Auth Quick Start

## ⚡ TL;DR

```bash
# 1. Ensure .env.local has JWT_SECRET
echo "JWT_SECRET=your-super-secret-key-at-least-32-chars-long-12345678" >> .env.local

# 2. Start dev server
npm run dev

# 3. Login as Alice (browser)
http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951

# 4. Check session
http://localhost:3000/api/dev/session
# Should show: { "authenticated": true, ... }

# 5. Go to inbox
http://localhost:3000/mini/inbox
```

## 🎯 Test Scenario: Alice → Emir Match

```bash
# 1. Create test match
psql <conn> -f test-manual-match-alice-emir.sql

# 2. Login as Emir
http://localhost:3000/api/dev/login?fid=543581&username=cengizhaneu&displayName=Emir%20Cengizhan%20Ulu&userCode=7189696562

# 3. Go to inbox and click Accept
http://localhost:3000/mini/inbox

# 4. Verify in DB
psql <conn> -c "SELECT status, b_accepted FROM matches WHERE user_a_fid=1111 AND user_b_fid=543581;"
# Expected: status='accepted_by_b', b_accepted=true

# 5. Logout and login as Alice
http://localhost:3000/api/dev/logout
http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951

# 6. Accept the match
http://localhost:3000/mini/inbox

# 7. Verify both accepted and meeting link exists
psql <conn> -c "SELECT status, meeting_link FROM matches WHERE user_a_fid=1111 AND user_b_fid=543581;"
# Expected: status='accepted', meeting_link='https://...'
```

## 🔍 Verification Commands

### Check session cookie is set
```bash
curl -v "http://localhost:3000/api/dev/login?fid=1111&username=alice" 2>&1 | grep -i "set-cookie"
# Should see: Set-Cookie: session=eyJ...; Path=/; HttpOnly; SameSite=Lax
```

### Save and reuse cookie
```bash
# Save cookie
curl -c cookies.txt "http://localhost:3000/api/dev/login?fid=1111&username=alice"

# Use cookie
curl -b cookies.txt http://localhost:3000/api/dev/session
# Should show: { "authenticated": true, ... }
```

### Check user in DB
```sql
SELECT fid, username, display_name, user_code
FROM users
WHERE fid = 1111;
-- Should return Alice
```

## 🐛 Quick Troubleshooting

| Issue | Check | Fix |
|-------|-------|-----|
| `authenticated: false` | JWT_SECRET in .env.local | Add 32+ char secret, restart server |
| Cookie not set | Browser DevTools → Cookies | Check `secure: false` for localhost |
| User not in DB | `SELECT * FROM users WHERE fid=1111` | Login endpoint auto-creates, check logs |
| Session expires immediately | System clock | `date` - ensure correct time |
| Route not found | Dev server running | `npm run dev` |

## 📱 Visual Login Switcher

```
http://localhost:3000/dev/login
```

- Click-to-login UI
- Current session display
- Quick links to inbox/create match
- curl examples

## 🔑 Cookie Settings

```typescript
{
  name: 'session',
  httpOnly: true,
  secure: false,      // localhost = http
  sameSite: 'lax',
  maxAge: 604800,     // 7 days
  path: '/',
}
```

## 📝 Test Users

### Alice
```
http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951
```

### Emir
```
http://localhost:3000/api/dev/login?fid=543581&username=cengizhaneu&displayName=Emir%20Cengizhan%20Ulu&userCode=7189696562
```

## ✅ Expected Flow

1. **Login:** Visit `/api/dev/login?fid=...`
2. **Response:** `{ "authenticated": true, "session": {...} }`
3. **Cookie:** Browser stores `session` cookie
4. **Inbox:** Visit `/mini/inbox` - no redirect
5. **API calls:** Automatically include session cookie
6. **Match actions:** Accept/Decline work as logged-in user

## 🚨 Common Mistakes

1. ❌ Forgot to restart server after adding JWT_SECRET
   ✅ `npm run dev` (env vars loaded on startup)

2. ❌ Using `secure: true` on localhost
   ✅ Already set to `false` for development

3. ❌ Missing `export const dynamic = 'force-dynamic'`
   ✅ Already added to all routes

4. ❌ Checking session before cookie propagates
   ✅ Wait 1 second or use same curl session

5. ❌ Browser blocking cookies
   ✅ Check DevTools → Application → Cookies

## 📚 Full Documentation

See `DEV-AUTH-GUIDE.md` for:
- Complete API reference
- Detailed troubleshooting
- Security notes
- All verification steps
- curl examples with cookie files

## 🎉 Success Criteria

You should be able to:
- [x] Login via browser URL
- [x] See `authenticated: true`
- [x] Access protected routes
- [x] Switch between users
- [x] Accept matches as different users
- [x] Logout and confirm session cleared

---

**Need help?** Check terminal logs - they show exactly what's happening:
```
[Dev Login] ✅ Session created for alice (1111)
[Dev Login] User already exists: alice (1111)
```
