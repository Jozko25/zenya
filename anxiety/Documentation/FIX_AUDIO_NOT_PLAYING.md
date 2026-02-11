# Fix: Audio Files Not Playing

## Problem
Audio files exist in your project folder but aren't being included in the app bundle, so they can't be found at runtime.

## Solution: Add Audio Files to Xcode Target

### Step 1: Check if Files are in Xcode

1. Open Xcode
2. In Project Navigator (left sidebar), look for:
   - `anxiety` → `Resources` → `Sounds`
3. Do you see these files?
   - `fire.wav`
   - `rain.wav`
   - `thunderstorm.mp3`
   - `waves.wav`

**If YES → Go to Step 2**
**If NO → Go to Step 3**

---

### Step 2: Verify Target Membership

If files are visible in Xcode:

1. **Select one of the audio files** (e.g., `rain.wav`)
2. **Open File Inspector** (right sidebar, or View → Inspectors → File)
3. Look for **"Target Membership"** section
4. **Is "zenya" checked?** ✅

**Do this for ALL 4 audio files!**

If "zenya" is NOT checked:
- ✅ Check the box next to "zenya"
- Do this for all 4 files

---

### Step 3: Add Files to Xcode (If Not Visible)

If files are NOT in Xcode:

1. **In Xcode Project Navigator:**
   - Right-click on `Resources` folder
   - Select **"New Group"**
   - Name it **"Sounds"**

2. **Add the audio files:**
   - Right-click on the new `Sounds` folder
   - Select **"Add Files to 'anxiety'"**
   - Navigate to: `/Users/janharmady/Desktop/projekty/anxiety/anxiety/Resources/Sounds/`
   - Select all 4 files:
     - `fire.wav`
     - `rain.wav`
     - `thunderstorm.mp3`
     - `waves.wav`
   - **IMPORTANT OPTIONS:**
     - ✅ **"Copy items if needed"** - CHECK THIS
     - ✅ **"Add to targets: zenya"** - CHECK THIS
     - Folder: **"Create groups"** (default)
   - Click **"Add"**

---

### Step 4: Verify Bundle Resources

1. Click on **project name** at top (zenya)
2. Select **"zenya" target**
3. Go to **"Build Phases"** tab
4. Expand **"Copy Bundle Resources"**
5. **Look for your audio files:**
   - fire.wav
   - rain.wav
   - thunderstorm.mp3
   - waves.wav

**If they're NOT there:**
- Click the **"+"** button
- Add each audio file
- They should now appear in the list

---

### Step 5: Clean and Rebuild

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)
3. **Product** → **Run** (⌘R)

---

### Step 6: Test

1. Open Meditation Library
2. Tap on "Forest Rain"
3. Press Play
4. **Check Xcode Console** for logs:

**✅ Success - You should see:**
```
🔧 Setting up real audio for: Forest Rain
📁 Looking for file: rain.wav
✅ Found audio file at path: Sounds
✅ Audio file loaded: rain.wav
▶️ Playback started for Forest Rain
```

**❌ Error - You might see:**
```
❌ Audio file not found: rain.wav in any path
   Searched: Sounds/, Resources/Sounds/, root
```

If you see the error, **go back to Step 2 or Step 3**.

---

## Quick Visual Check

### In Xcode Project Navigator:

```
anxiety
  ├── Resources
  │   └── Sounds
  │       ├── fire.wav          ← Should be here
  │       ├── rain.wav          ← Should be here
  │       ├── thunderstorm.mp3  ← Should be here
  │       └── waves.wav         ← Should be here
```

### In File Inspector (for each file):

```
Target Membership:
  ☑ zenya          ← Must be checked!
```

### In Build Phases → Copy Bundle Resources:

```
Copy Bundle Resources (4 items)
  - fire.wav
  - rain.wav
  - thunderstorm.mp3
  - waves.wav
```

---

## Alternative: Drag and Drop

**Easiest method:**

1. Open **Finder** to: `/Users/janharmady/Desktop/projekty/anxiety/anxiety/Resources/Sounds/`
2. Open **Xcode** side-by-side
3. **Select all 4 audio files** in Finder
4. **Drag them** into Xcode's `Resources/Sounds` folder
5. In the dialog:
   - ✅ "Copy items if needed"
   - ✅ "Add to targets: zenya"
   - Click "Finish"

---

## Still Not Working?

### Check Console Output

When you press play, look in Xcode console (bottom panel, or View → Debug Area → Activate Console).

**Look for:**
- 🔧 Lines starting with emoji (our secure logs)
- ❌ Error messages about files not found
- ✅ Success messages about file loading

**Share the console output** and I can help diagnose!

---

## Common Issues

### Issue: "File not found in any path"
**Cause:** Files not added to Xcode target
**Fix:** Follow Step 3 above

### Issue: No console output at all
**Cause:** RealAudioPlayer not being used
**Fix:** Make sure you built after adding the file

### Issue: "Failed to load audio file: [error]"
**Cause:** File is corrupted or wrong format
**Fix:** Re-download the audio file

### Issue: Play button doesn't respond
**Cause:** Different issue - check if UI is connected
**Fix:** Look for errors about RealAudioPlayer class not found

---

## Expected File Sizes (to verify files are complete)

- `fire.wav` → ~13.3 MB
- `rain.wav` → ~131 MB
- `thunderstorm.mp3` → ~47 MB
- `waves.wav` → ~38 MB

If your files are much smaller, they might be corrupted.

---

After following these steps, your audio should play! 🎵
