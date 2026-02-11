# Journal Evaluation System

## Overview
The journal evaluation system provides AI-powered daily insights based on user journal entries. Evaluations are automatically generated after each journal submission and stored in the database.

## How It Works

### 1. Journal Submission Flow
```
User writes journal entry
    ↓
GamifiedJournalEntryView submits entry
    ↓
Entry saved to database
    ↓
JournalAnalysisService.checkAndAnalyzeIfNeeded() called
    ↓
All today's entries analyzed via GPT-4o-mini
    ↓
Evaluation saved to database
    ↓
Notification sent: "EvaluationCompleted"
    ↓
User sees evaluation in EvaluationsModalView
```

### 2. Automatic Analysis Trigger
- **When**: After every journal submission
- **Where**: `GamifiedJournalEntryView.swift` line ~1341
- **Condition**: User must have at least 1 entry for the day
- **Updates**: If user submits more entries, evaluation is automatically updated

### 3. Database Storage
- **Table**: `journal_evaluations`
- **Schema**: See `JOURNAL_EVALUATIONS_SCHEMA.sql`
- **Key Fields**:
  - `user_id`: Links to user
  - `evaluation_date`: Date of the evaluation (one per day per user)
  - `maturity_score`: 1-10 emotional maturity score
  - `summary`: 2-3 sentence overview
  - `key_insights`: Array of specific observations
  - `emotional_themes`: Array of emotional patterns
  - `growth_areas`: Array of areas for development
  - `entry_count`: Number of entries analyzed
  - `analyzed_content`: Combined journal entries (for reference)

### 4. Evaluation Components

#### Maturity Score (1-10)
- **1-3**: Developing - Early emotional awareness
- **4-6**: Growing - Improving self-reflection
- **7-8**: Mature - Strong emotional intelligence
- **9-10**: Highly Mature - Exceptional self-awareness

#### Analysis Includes
- **Key Insights**: 3 specific observations about emotional state
- **Emotional Themes**: 3 recurring themes or patterns
- **Growth Areas**: 2 opportunities for personal development
- **Summary**: Concise overview of the day's emotional journey

### 5. User Experience

#### Empty State
- Shows when user has no evaluations yet
- Clear call-to-action to start journaling
- Explains that evaluation happens automatically

#### Evaluation List
- Displays all past evaluations
- Sorted by date (newest first)
- Shows maturity score, date, entry count
- Tap to view full details

#### Evaluation Details
- Full summary text
- All key insights
- Emotional themes as tags
- Growth areas with actionable suggestions

### 6. API Integration

#### OpenAI GPT-4o-mini
```swift
// Prompt sent to AI
func buildAnalysisPrompt(content: String, entryCount: Int) -> String {
    // Analyzes:
    // - Emotional self-awareness
    // - Problem-solving approaches
    // - Relationship dynamics
    // - Personal growth patterns
    // - Coping mechanisms
}
```

#### Response Format
```json
{
  "maturityScore": 6,
  "keyInsights": ["insight1", "insight2", "insight3"],
  "emotionalThemes": ["theme1", "theme2", "theme3"],
  "growthAreas": ["area1", "area2"],
  "summary": "A thoughtful summary of emotional state"
}
```

### 7. Key Files

| File | Purpose |
|------|---------|
| `JournalAnalysisService.swift` | Core evaluation logic and API calls |
| `EvaluationsModalView.swift` | UI for viewing evaluation history |
| `GamifiedJournalEntryView.swift` | Triggers evaluation after submission |
| `JOURNAL_EVALUATIONS_SCHEMA.sql` | Database schema |

### 8. Notifications

#### Local Notification
- Sent when evaluation completes
- Title: "Daily Reflection Complete ✨"
- Body: "Your journal analysis is ready. Discover insights about your emotional growth!"

#### In-App Banner
- Shows in EvaluationsModalView when new evaluation ready
- Auto-dismisses after 3 seconds
- Green success indicator

### 9. Error Handling

#### Database Failures
- Falls back to local storage using UserDefaults
- Retries with upsert if unique constraint violation
- Shows evaluation even if database save fails

#### API Failures
- Logs error details
- Sets `isAnalyzing = false` to reset UI
- Does not block journal submission

### 10. Performance Considerations

#### Rate Limiting
- One evaluation per day per user
- Only updates if entry count changes
- 1-second delay between historical analyses

#### Caching
- Local storage backup via UserDefaults
- Evaluations loaded from both database + local
- Database takes precedence on merge

### 11. Future Enhancements

- [ ] Weekly/monthly trend analysis
- [ ] Comparison with past evaluations
- [ ] Share evaluations with therapist
- [ ] Export evaluations as PDF
- [ ] Customizable insight categories
- [ ] Multi-language support
- [ ] Offline queue for pending analyses

## Testing

### Manual Testing
1. Submit a journal entry
2. Wait for "Evaluation Completed" notification
3. Open Evaluations view
4. Verify evaluation appears with correct data
5. Tap to view full details
6. Submit another entry and verify update

### Debug Mode
In DEBUG builds, the system can force analysis even with 0 entries (for testing).

## Troubleshooting

### Evaluation Not Appearing
- Check database permissions (RLS policies)
- Verify user is authenticated
- Check OpenAI API key is valid
- Look for errors in console logs

### Duplicate Evaluations
- Database enforces UNIQUE constraint on (user_id, evaluation_date)
- Upsert logic prevents duplicates

### Missing Notification
- Check notification permissions
- Verify NotificationCenter observers are active
- Check notification is scheduled correctly

## Support

For issues or questions, check:
- Console logs (filter for "📊" or "🎯")
- Database table `journal_evaluations`
- OpenAI API usage dashboard
