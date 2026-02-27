# Chrome Debug Mode Explained

## What is Chrome Debug Mode?

When you run `./start-chrome-debug.sh`, it launches a **separate Chrome instance** specifically for debugging and automation.

## Key Characteristics

### ✅ Advantages

1. **Complete Isolation**: Doesn't affect your daily Chrome usage
2. **Independent Configuration**: Uses a separate user data directory
3. **Debugging Capabilities**: Can be automated via CDP (Chrome DevTools Protocol)
4. **Security**: Doesn't expose your daily browsing data

### ❌ Disadvantages

1. **No Bookmarks**: This is a fresh Chrome instance
2. **No History**: No browsing history available
3. **No Saved Passwords**: Need to login to websites again
4. **No Extensions**: No extensions installed

## Why Debug Mode is Needed?

OpenClaw needs Chrome DevTools Protocol (CDP) to:

1. **Auto-capture Authentication Credentials**:
   - Monitor network requests
   - Extract Claude sessionKey
   - Auto-save to config files

2. **Bypass Cloudflare Detection**:
   - Use real browser context
   - Maintain complete browser fingerprint
   - Avoid bot detection

3. **Keep Session Active**:
   - Auto-refresh tokens
   - Handle session expiration
   - Re-authenticate when needed

## Use Cases

### Scenario 1: Initial Setup (Debug Mode Required)

```bash
# 1. Start debug Chrome
./start-chrome-debug.sh

# 2. Login to Claude in the opened Chrome
# (Even though you can't see bookmarks, complete the login)

# 3. Run configuration wizard
./onboard.sh

# 4. System auto-captures credentials
```

**Debug Chrome is REQUIRED for this scenario!**

### Scenario 2: Daily Usage (Debug Mode NOT Required)

```bash
# 1. Start Gateway service
./server.sh start

# 2. Use Web UI or API
open http://127.0.0.1:3001

# No need to keep Chrome debug mode running
```

**You can close debug Chrome for daily usage!**

### Scenario 3: Reconfigure Auth (Debug Mode Required)

```bash
# 1. Restart debug Chrome
./start-chrome-debug.sh

# 2. Re-run configuration wizard
./onboard.sh

# 3. Can close debug Chrome after completion
```

**Only needed when auth expires or reconfiguration is required!**

## How to See Your Bookmarks?

If you want to see your bookmarks and data in debug Chrome, there are three methods:

### Method 1: Pre-login with Daily Chrome (Recommended)

```bash
# 1. Login to Claude in your daily Chrome
# Open your regular Chrome browser
# Visit https://claude.ai
# Complete login and save credentials

# 2. Start debug Chrome
./start-chrome-debug.sh

# 3. Debug Chrome might auto-login (if Chrome synced the session)
```

**Note**: This depends on Chrome's account sync feature and may not always work.

### Method 2: Manual Mode (No Debug Chrome Needed)

```bash
# 1. Visit Claude in your daily Chrome
# Open your regular Chrome
# Visit https://claude.ai and login

# 2. Manually extract sessionKey
# Press F12 to open DevTools
# Application → Cookies → Find sessionKey
# Copy sessionKey value (sk-ant-sid02-...)

# 3. Run config wizard and choose manual mode
./onboard.sh
# Select: Claude Web → Manual Paste
# Paste sessionKey

# 4. No need to start debug Chrome
```

**This method doesn't require debug Chrome at all!**

### Method 3: Temporarily Close Debug Mode (Not Recommended)

```bash
# 1. Close debug Chrome
pkill -f "chrome.*remote-debugging-port=9222"

# 2. Use daily Chrome
# Now you can use your regular Chrome and see all bookmarks

# 3. But cannot auto-capture credentials
# Need to use manual mode (Method 2)
```

**Downside**: Loses automation capability, requires manual operation each time.

## Technical Details

### Debug Chrome Launch Parameters

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/.openclaw-chrome-debug" \
  --no-first-run \
  --no-default-browser-check \
  https://claude.ai/new
```

**Key Parameters:**

- `--remote-debugging-port=9222`: Enable CDP debug port
- `--user-data-dir`: Use separate user data directory (this is why you can't see bookmarks)
- `--no-first-run`: Skip first-run wizard
- `--no-default-browser-check`: Don't check default browser

### User Data Directory Locations

```bash
# Debug Chrome data directory
~/.openclaw-chrome-debug/

# Daily Chrome data directory
~/Library/Application Support/Google/Chrome/
```

**These two directories are completely independent!**

### CDP Connection Method

```typescript
// OpenClaw connects to debug Chrome
const browser = await puppeteer.connect({
  browserURL: 'http://127.0.0.1:9222',
  defaultViewport: null,
});
```

## FAQ

### Q1: Why can't I see my bookmarks?

**A**: Because debug Chrome uses a separate user data directory (`~/.openclaw-chrome-debug/`), completely isolated from your daily Chrome (`~/Library/Application Support/Google/Chrome/`).

**Solutions**:
- Use Method 1 (pre-login) or Method 2 (manual mode)
- Or accept this limitation and only use debug Chrome for configuration

### Q2: Can I use my daily Chrome?

**A**: Not recommended. If you use your daily Chrome's data directory:
- May interfere with daily usage
- May cause data conflicts
- Higher security risks

**Recommended approach**:
- Use debug Chrome for configuration (even without bookmarks)
- Daily usage doesn't need Chrome (only Gateway service)

### Q3: Do I need to re-login to Claude every time?

**A**: Not necessarily.
- If Chrome synced login state, may auto-login
- If not synced, need to re-login
- After logging in once, sessionKey is saved to config, Chrome not needed afterwards

### Q4: Do I need to keep debug Chrome running for daily use?

**A**: No!
- After configuration, you can close debug Chrome
- Gateway service uses the saved sessionKey
- Only need to restart debug Chrome when reconfiguring

### Q5: How to check if debug Chrome is running?

```bash
# Check process
ps aux | grep "chrome.*remote-debugging-port=9222" | grep -v grep

# Check port
lsof -i:9222

# Test connection
curl http://127.0.0.1:9222/json/version
```

### Q6: How to close debug Chrome?

```bash
# Method 1: Close window directly (recommended)
# Click the Chrome window's close button

# Method 2: Use command line
pkill -f "chrome.*remote-debugging-port=9222"

# Method 3: Find and kill process
ps aux | grep "chrome.*remote-debugging-port=9222" | grep -v grep
kill <PID>
```

## Best Practices

### ✅ Recommended

1. **Initial Setup**:
   - Use debug Chrome (even without bookmarks)
   - Complete automated configuration
   - Close debug Chrome after completion

2. **Daily Usage**:
   - Only run Gateway service
   - No Chrome needed
   - Use Web UI or API

3. **Reconfiguration**:
   - Only restart debug Chrome when auth expires
   - Close immediately after configuration

### ❌ Not Recommended

1. **Don't** keep debug Chrome running all the time (wastes resources)
2. **Don't** use daily Chrome's data directory (security risk)
3. **Don't** browse daily in debug Chrome (data won't be saved)

## Summary

| Scenario | Debug Chrome Needed | Can See Bookmarks | Recommended Method |
|----------|-------------------|------------------|-------------------|
| Initial Setup | ✅ Yes | ❌ No | Accept limitation, complete setup |
| Daily Usage | ❌ No | N/A | Only run Gateway |
| Reconfiguration | ✅ Yes | ❌ No | Quick completion, close immediately |
| Manual Config | ❌ No | ✅ Yes | Use daily Chrome to extract manually |

**Core Concept**: Debug Chrome is a temporary tool, only used during configuration, not needed for daily usage!
