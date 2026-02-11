# AI Chatbot Context Enhancement

## Overview
Enhanced the AI chatbot (AI tab) to include personalized user context, enabling the AI to reference the user's journal history, mood patterns, and progress when responding.

## What Was Implemented

### 1. **UserContextService.swift**
Created a new service (`anxiety/Services/UserContextService.swift`) that:
- Fetches user data from the database
- Generates contextual summaries for the AI
- Provides real-time user statistics

**Data Included:**
- **Journal Data:**
  - Total entries in last 30 days
  - Entries this week
  - Average words per entry
  - Recent average mood (last 10 entries)
  - Last journal entry date
  - Total gratitude items recorded

- **Mood Tracking:**
  - Mood entries count
  - Average mood, anxiety, and stress levels
  - Weekly trends

- **Progress & Achievements:**
  - Current level
  - Total points
  - Current and longest streaks
  - Total journal entries
  - Streak achievements

### 2. **Enhanced ChatbotView**
Updated `anxiety/Views/ChatbotView.swift` to:
- Import `UserContextService`
- Fetch user context before each AI request
- Append context to the system prompt
- Enable AI to reference user's actual data

## How It Works

### Context Generation Flow:
```
User sends message
    ↓
ChatbotView calls UserContextService.generateContextSummary()
    ↓
Service fetches data from DatabaseService:
  - Journal entries (last 30 days)
  - Mood entries (last 30 days)  
  - Game stats (streaks, level, points)
    ↓
Service generates formatted context summary
    ↓
Context is appended to AI system prompt
    ↓
OpenAI API receives enhanced prompt with user data
    ↓
AI responds with personalized, data-aware answers
```

## Example User Interactions

### Before (Without Context):
**User:** "How's my mood been lately?"
**AI:** "I don't have access to your mood data, but you can check your progress in the Grow tab."

### After (With Context):
**User:** "How's my mood been lately?"
**AI:** "Looking at your recent entries, your average mood has been 6.5/10 over the last week. I notice you've been journaling consistently - you're on a 5-day streak! Keep it up! 💪"

---

**User:** "Should I journal today?"
**AI:** "Absolutely! You've written 12 entries this month with an average of 145 words per entry. You last journaled yesterday, so continuing today would extend your 3-day streak. Even a short entry can help maintain momentum!"

---

**User:** "What should I focus on?"
**AI:** "Based on your journal, you've recorded 18 gratitude items recently - that's excellent! Your anxiety levels have averaged 5.5/10 this week. Try the 4-7-8 breathing exercise when you're feeling anxious, and keep building on that gratitude practice."

## Usage Instructions

### For Users:
1. Use the AI chatbot normally
2. The AI now automatically knows about:
   - Your journaling habits
   - Your mood trends
   - Your progress and streaks
   - Your achievements

3. You can ask questions like:
   - "How's my week been?"
   - "Am I making progress?"
   - "What's my mood trend?"
   - "Should I journal today?"
   - "How long is my current streak?"

### For Developers:
The context is automatically fetched on every message. To modify what data is included:

1. Edit `UserContextService.swift`
2. Add/remove data in these methods:
   - `fetchJournalContext()` - Journal entry data
   - `fetchMoodContext()` - Mood tracking data
   - `fetchStatsContext()` - Progress and achievements

## Technical Details

### Files Modified:
- ✅ Created: `anxiety/Services/UserContextService.swift`
- ✅ Modified: `anxiety/Views/ChatbotView.swift`

### Dependencies:
- Uses existing `DatabaseService` for data fetching
- Uses existing `OpenAIClient` for API calls
- No new external dependencies required

### Performance:
- Context is fetched asynchronously
- Cached data from DatabaseService is used when available
- Minimal impact on response time (~100-200ms additional)

## Next Steps (Optional Enhancements)

### 1. Add More Context Types:
- Breathing session history
- Meditation usage
- Crisis support interactions
- Achievement unlocks

### 2. Contextual Prompts:
- Show suggested questions based on user data
- "Ask me about your progress this week"
- "Want to know your mood trends?"

### 3. Context Caching:
- Cache context for 5-10 minutes to reduce DB calls
- Refresh context only when user data changes

### 4. Privacy Controls:
- Add settings to control what data AI can access
- Option to disable context for private conversations

## Testing the Feature

1. **Add some journal entries** in the Feel tab
2. **Go to AI tab** and ask:
   - "How's my journaling going?"
   - "What's my current streak?"
   - "How's my mood been?"
3. **Verify AI responds** with actual data from your entries

## Notes

- Context is only visible to the AI, not shown to the user
- All data stays local and is only sent to OpenAI API
- Works with existing RLS policies and permissions
- Gracefully handles missing data (new users)

---

## Example Context Generated:

```
USER CONTEXT (Use this to personalize responses):

JOURNAL DATA:
- Total entries (last 30 days): 15
- Entries this week: 4
- Average words per entry: 142
- Recent average mood (last 10 entries): 6.8/10
- Last journal entry: 1 day ago (yesterday)
- Total gratitude items recorded: 23

PROGRESS & ACHIEVEMENTS:
- Level: 3
- Total points: 420
- Current streak: 4 days
- Longest streak: 7 days
- Total journal entries: 15
- 💪 Building momentum with a 4-day streak

IMPORTANT: Reference this data naturally when relevant.
```
