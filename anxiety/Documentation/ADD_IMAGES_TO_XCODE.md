# Add Meditation Images to Xcode

## Images You Have

Location: `/Users/janharmady/Desktop/projekty/anxiety/anxiety/Resources/Images/`

Files:
- `rain.jpg` - Forest Rain image
- `ocean.jpg` - Ocean Waves image
- `thunderstorm.jpg` - Thunderstorm image
- `fire.jpg` - Crackling Fire image

---

## Quick Add (Drag & Drop)

### Step 1: Open Finder
Navigate to: `/Users/janharmady/Desktop/projekty/anxiety/anxiety/Resources/Images/`

### Step 2: Select Images
Select all 4 image files:
- rain.jpg
- ocean.jpg
- thunderstorm.jpg
- fire.jpg

### Step 3: Drag to Xcode
1. Open Xcode
2. In Project Navigator, find `Resources` → `Images` folder
3. **Drag the 4 files** from Finder into the `Images` folder in Xcode

### Step 4: Configure Options
In the dialog that appears:
- ✅ **"Copy items if needed"** - CHECK THIS
- ✅ **"Add to targets: zenya"** - CHECK THIS
- Click **"Finish"**

---

## Verify

### Check Project Navigator:
```
anxiety
  ├── Resources
  │   ├── Images
  │   │   ├── fire.jpg          ← Should be here
  │   │   ├── ocean.jpg         ← Should be here
  │   │   ├── rain.jpg          ← Should be here
  │   │   └── thunderstorm.jpg  ← Should be here
```

### Check Target Membership:
1. Select each image file
2. Open File Inspector (right sidebar)
3. Verify **"zenya"** is checked under "Target Membership"

### Check Build Phases:
1. Click project name → zenya target
2. Build Phases → Copy Bundle Resources
3. All 4 images should be listed

---

## Build & Test

1. **Clean Build** (⇧⌘K)
2. **Build** (⌘B)
3. **Run** (⌘R)
4. **Open Meditation Library**
5. **You should see beautiful images!** 🖼️

---

## Expected Result

Each meditation card will now show:
- **Forest Rain** → Green forest/rain scene
- **Ocean Waves** → Ocean/beach scene
- **Thunderstorm** → Dark stormy sky
- **Crackling Fire** → Warm fireplace

Instead of solid color gradients!

---

Done! Your meditation cards will look professional with real images! 🎨
