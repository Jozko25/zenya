# Quick Guide: Add RealAudioPlayer to Xcode

## 📁 File to Add

**New file created:** `anxiety/Services/RealAudioPlayer.swift`

This file replaces the procedural audio generation with real audio file playback.

---

## ⚡ Quick Steps

### 1. Open Xcode
Open your project in Xcode.

### 2. Find the Services Folder
In the Project Navigator (left sidebar), navigate to:
- `anxiety` → `Services`

### 3. Add the File
**Right-click** on the `Services` folder → **"Add Files to 'anxiety'"**

OR

**Drag** the file from Finder:
- Open Finder to: `/Users/janharmady/Desktop/projekty/anxiety/anxiety/Services/`
- Find `RealAudioPlayer.swift`
- Drag it into Xcode's `Services` folder

### 4. Configure Options
In the dialog that appears:
- ✅ **"Add to targets: zenya"** (CHECK THIS!)
- ⚠️ **"Copy items if needed"** (UNCHECK - file is already in right place)
- Click **"Add"**

### 5. Verify
In Xcode:
- Click on project name at top (zenya)
- Select "zenya" target
- Go to "Build Phases" tab
- Expand "Compile Sources"
- You should see `RealAudioPlayer.swift` in the list

---

## ✅ Done!

Now build and run (⌘+R). The app will use real audio files instead of procedural generation!

---

## 🎵 Also Check: Audio Files

Make sure these 4 audio files are also in your Xcode project:

**Location in Finder:**
`/Users/janharmady/Desktop/projekty/anxiety/anxiety/Resources/Sounds/`

**Files:**
- `fire.wav`
- `rain.wav`
- `thunderstorm.mp3`
- `waves.wav`

**To verify in Xcode:**
- Look in Project Navigator
- Navigate to: `anxiety` → `Resources` → `Sounds`
- You should see all 4 files

**If they're missing:**
1. Create `Sounds` folder in `Resources` (if needed)
2. Drag the 4 audio files from Finder into that folder
3. Make sure "Copy items if needed" is **CHECKED**
4. Make sure "Add to targets: zenya" is **CHECKED**

---

That's it! 🚀
