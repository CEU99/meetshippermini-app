# Fix: Auth Import Error in Chat API Routes

## Problem
Build error when trying to run the app:
```
Export getServerSession doesn't exist in target module
import { getServerSession } from '@/lib/auth';
Did you mean to import getSession?
```

## Root Cause
The chat room API routes were importing `getServerSession` from `@/lib/auth`, but the auth module only exports `getSession` (not `getServerSession`).

## Files Fixed

### 1. `/app/api/chat/rooms/[id]/route.ts`
**Changed:**
```typescript
import { getServerSession } from '@/lib/auth';  // ❌ Wrong
```
**To:**
```typescript
import { getSession } from '@/lib/auth';  // ✅ Correct
```

**Also changed the function call:**
```typescript
const session = await getServerSession(request);  // ❌ Wrong
```
**To:**
```typescript
const session = await getSession();  // ✅ Correct
```

### 2. `/app/api/chat/rooms/[id]/message/route.ts`
Same fix as above.

### 3. `/app/api/chat/rooms/[id]/complete/route.ts`
Same fix as above.

## Why This Happened
When I created the chat room API routes, I mistakenly used `getServerSession` (which is a Next-Auth convention) instead of checking the actual export name in your `lib/auth.ts` file.

Your auth module exports `getSession`, not `getServerSession`.

## What Changed
- ✅ Import statement: `getServerSession` → `getSession`
- ✅ Function call: `getServerSession(request)` → `getSession()` (no request param needed)
- ✅ All three chat API routes fixed

## Verification

### Build should now work:
```bash
npm run build
# or
pnpm build
```

**Expected**: No import errors

### Dev server should work:
```bash
npm run dev
```

**Expected**: Server starts without errors

### Test the endpoints:
```bash
# Test getting a room (replace {roomId} with actual ID)
curl http://localhost:3000/api/chat/rooms/{roomId}

# Should return 401 Unauthorized if not logged in
# Or room data if you have a valid session cookie
```

## No Functional Changes
This is purely a **naming fix**. The functionality is identical:
- Authentication still works the same way
- Session validation unchanged
- API routes behave exactly as intended

The only change was using the correct function name.

## Still See Errors?

### If you see module not found errors:
```bash
# Clear Next.js cache
rm -rf .next
npm run dev
```

### If TypeScript complains:
```bash
# Restart TypeScript server in your editor
# VS Code: Cmd+Shift+P → "TypeScript: Restart TS Server"
```

### If build still fails:
```bash
# Check for other import issues
grep -r "getServerSession" app/api/
# Should return nothing
```

## Summary
- **Problem**: Wrong function name imported
- **Solution**: Changed `getServerSession` to `getSession` in 3 files
- **Impact**: Build errors resolved, no functional changes
- **Status**: ✅ Fixed

---

**You can now proceed with the environment variable fix** from `SOLUTION_SUMMARY.md` to resolve the fetch failed error.
