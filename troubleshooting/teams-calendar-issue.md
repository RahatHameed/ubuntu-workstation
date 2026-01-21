# Teams Calendar Issue - AccountSourceListStore Error

## Status: Partially Resolved

**Date:** 2026-01-21

## Error Message
```
Error: Assertion:AccountSourceListStore is not initialized
BootResult: fail
esrc: BeforeBoot
et: ClientError
```

## Symptoms
- Teams calendar fails to load with "AccountSourceListStore is not initialized" error
- Affects both Teams for Linux app and browser versions
- Error occurs during calendar boot initialization

## Root Cause
Chrome-specific issue - likely caused by:
- Cached/corrupted data
- Chrome extension interference

## What Works
- Firefox: Calendar works normally
- Chrome Incognito: Calendar works (confirms extension/cache issue)

## What Doesn't Work
- Chrome (normal mode)
- Teams for Linux app (Electron-based, uses similar rendering)

## Attempted Fixes

### Did Not Help
- [x] Clearing Teams for Linux cache (`rm -rf ~/snap/teams-for-linux/current/.config/teams-for-linux/`)
- [x] Updating snap (`sudo snap refresh teams-for-linux` - no updates available)
- [x] IPv6 disable (unrelated, but fixed IPv6 VPN leak)

### Helped
- [x] Using Firefox instead of Chrome
- [x] Chrome Incognito mode works

### TODO - Not Yet Tried
- [ ] Disable Chrome extensions one by one to find culprit
- [ ] Clear Chrome cache completely:
  ```bash
  rm -rf ~/.config/google-chrome/Default/Local\ Storage/*teams*
  rm -rf ~/.config/google-chrome/Default/IndexedDB/*teams*
  rm -rf ~/.config/google-chrome/Default/Cache/
  ```
- [ ] Launch Chrome with `--disable-extensions` flag
- [ ] Check for specific extension conflicts (ad blockers, privacy tools)

## Workaround
Use Firefox for Teams until Chrome issue is resolved.

## Related Links
- [Microsoft Q&A Thread](https://learn.microsoft.com/en-us/answers/questions/5727168/calendar-app-crashing-ms-teams-webapp)
- [Microsoft 365 Service Status](https://status.cloud.microsoft/)

## Notes
- This may also be a Microsoft server-side issue affecting certain accounts/regions
- If issue persists across all browsers, contact IT admin to open Microsoft support ticket
