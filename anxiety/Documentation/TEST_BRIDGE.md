# Testing the iOS Web Bridge

## What to Test

1. **Open the iOS app**
2. **Tap "Purchase on Web" or "Get Code"** 
3. **Navigate to the success page on the web**
4. **Tap "Already have the app? Redeem now"**

## Expected Behavior

You should see these debug logs in order:

```
🌉 iOS Bridge: Received message from web to open redeem modal
🌉 iOS Bridge: Message body: [...]
🌉 iOS Bridge: Prefill code: ZENYA-XXXX-XXXX
✅ iOS Bridge: About to show modal with prefill: ZENYA-XXXX-XXXX
🌉 ActivationCodeView: .task started, prefillCode = ZENYA-XXXX-XXXX
🌉 iOS Bridge: Prefilling code from 'ZENYA-XXXX-XXXX' to 'XXXXXXXX'
🌉 iOS Bridge: Code state updated to: XXXXXXXX
🌉 iOS Bridge: Waiting 0.8s before auto-submit...
🌉 iOS Bridge: Auto-submit check - code: XXXXXXXX, cleanCode: XXXXXXXX, isSubmitting: false
🌉 iOS Bridge: ✅ Auto-submitting prefilled code
```

## What Should Happen

1. ✅ Native modal opens with haptic feedback
2. ✅ Code appears in the input fields (8 characters, split into two segments)
3. ✅ After 0.8 seconds, code automatically submits
4. ✅ Beautiful loading animation appears
5. ✅ Subscription activates successfully

## If It Doesn't Work

Check the console for:
- Is `prefillCode` showing as `nil` when it should have a value?
- Are there any error messages?
- Does the auto-submit log appear?

Run the app again and paste the console output.
