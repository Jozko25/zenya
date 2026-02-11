# Quick Fix for Build Errors

## The Issue
The new security files were created but not added to your Xcode project, so Xcode can't find them.

## Solution: Add Files to Xcode

### Step 1: Add the Security Utility Files

1. Open Xcode
2. In the Project Navigator (left sidebar), find the `anxiety/Utilities` folder
3. Right-click on the `Utilities` folder → **"Add Files to 'anxiety'"** (or drag the files directly)
4. Navigate to `anxiety/Utilities/` and select these 5 files:
   - `KeychainManager.swift`
   - `SecureNetworkManager.swift`
   - `InputValidator.swift`
   - `SecureLogger.swift`
   - `SecurityManager.swift`
5. Make sure **"Copy items if needed"** is UNCHECKED (files are already in the right place)
6. Make sure **"Add to targets: zenya"** is CHECKED
7. Click **"Add"**

### Step 2: Build Again

Press **⌘+B** to build. The errors should be gone!

---

## If You Still Get Errors

### Error: "Cannot find 'SecureStorage' in scope"

**Cause:** `KeychainManager.swift` not added to target

**Fix:** 
1. Click on `KeychainManager.swift` in Project Navigator
2. In File Inspector (right sidebar), check the box next to "zenya" under "Target Membership"

### Error: "Cannot find 'SHA256' in scope"

**Cause:** Missing CryptoKit import

**Fix:** Already fixed in the code. Just clean build folder:
1. Product → Clean Build Folder (⇧⌘K)
2. Build again (⌘+B)

### Error: "Cannot find 'SecureLogger' in scope"

**Cause:** `SecureLogger.swift` not added to target

**Fix:** Same as SecureStorage - add to target membership

---

## Alternative: Quick Add All Files

If you want to add all files at once:

1. In Finder, navigate to `/Users/janharmady/Desktop/projekty/anxiety/anxiety/Utilities/`
2. Select all 5 new `.swift` files (KeychainManager, SecureNetworkManager, InputValidator, SecureLogger, SecurityManager)
3. Drag them into Xcode's Project Navigator under the `Utilities` folder
4. In the dialog that appears:
   - **UNCHECK** "Copy items if needed"
   - **CHECK** "Add to targets: zenya"
   - Click "Finish"

---

## Files That Need to Be Added

```
anxiety/Utilities/
  ├── KeychainManager.swift          ← ADD THIS
  ├── SecureNetworkManager.swift     ← ADD THIS
  ├── InputValidator.swift           ← ADD THIS
  ├── SecureLogger.swift             ← ADD THIS
  └── SecurityManager.swift          ← ADD THIS
```

---

## Verify Files Are Added

After adding files, in Xcode:

1. Click on the project name (zenya) at the top of Project Navigator
2. Select the "zenya" target
3. Go to "Build Phases" tab
4. Expand "Compile Sources"
5. You should see all 5 new files listed there

If any are missing, click the **+** button and add them manually.

---

## After Adding Files

The build should succeed! If you get any warnings, they're safe to ignore for now.

Next step: Update the certificate pins as described in `INTEGRATION_STEPS.md`
