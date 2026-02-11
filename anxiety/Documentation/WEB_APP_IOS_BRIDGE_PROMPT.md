# iOS Bridge Implementation for Zenya Web App

## Overview
We need to implement a JavaScript bridge that allows the Zenya web app (when embedded in the iOS app's WKWebView) to communicate with the native iOS app. This will enable users who purchase via the web to seamlessly open the native code redemption modal.

## Objective
When a user completes a purchase on the web app (while viewing it inside the iOS app), they should be able to click a button that:
1. **If in iOS app**: Opens the native activation code modal
2. **If in regular browser**: Redirects to the `/recover` page

## Implementation Tasks

### 1. Create iOS Bridge Utility (`lib/ios-bridge.ts`)

```typescript
// lib/ios-bridge.ts

/**
 * Detects if the web app is running inside the iOS WKWebView
 * by checking for the webkit.messageHandlers.openRedeemModal object
 */
export function isInIOSApp(): boolean {
  if (typeof window === 'undefined') return false;
  
  return (
    window.webkit?.messageHandlers?.openRedeemModal !== undefined
  );
}

/**
 * Sends a message to the iOS app to open the native redeem modal
 * @param options Optional parameters like prefill code
 * @returns true if message was sent successfully, false otherwise
 */
export function openRedeemModalInIOS(options?: { code?: string }): boolean {
  if (!isInIOSApp()) {
    console.log('Not in iOS app, skipping bridge call');
    return false;
  }
  
  try {
    console.log('🌉 Sending message to iOS app to open redeem modal', options);
    
    window.webkit.messageHandlers.openRedeemModal.postMessage({
      action: 'openRedeemModal',
      code: options?.code || null,
      timestamp: new Date().toISOString()
    });
    
    console.log('✅ Message sent to iOS app successfully');
    return true;
  } catch (error) {
    console.error('❌ Failed to send message to iOS app:', error);
    return false;
  }
}

// TypeScript global type declarations
declare global {
  interface Window {
    webkit?: {
      messageHandlers?: {
        openRedeemModal?: {
          postMessage: (message: any) => void;
        };
      };
    };
  }
}
```

### 2. Create Reusable Button Component (`components/RedeemCodeButton.tsx`)

```typescript
// components/RedeemCodeButton.tsx
'use client';

import { useRouter } from 'next/navigation';
import { isInIOSApp, openRedeemModalInIOS } from '@/lib/ios-bridge';

interface RedeemCodeButtonProps {
  children?: React.ReactNode;
  className?: string;
  code?: string; // Optional: prefill code if available
}

export default function RedeemCodeButton({
  children = 'Redeem Your Code',
  className = '',
  code
}: RedeemCodeButtonProps) {
  const router = useRouter();
  
  const handleClick = () => {
    console.log('Redeem button clicked');
    
    // Try to open in native iOS app first
    const sentToIOS = openRedeemModalInIOS({ code });
    
    // If not in iOS app or message failed, fallback to web page
    if (!sentToIOS) {
      console.log('Falling back to web /recover page');
      router.push('/recover');
    }
  };
  
  return (
    <button
      onClick={handleClick}
      className={className}
    >
      {children}
    </button>
  );
}
```

### 3. Usage Example

Add this button to your payment success page, pricing page, or anywhere users need to redeem codes:

```typescript
// Example: app/success/page.tsx or app/pricing/page.tsx

import RedeemCodeButton from '@/components/RedeemCodeButton';

export default function SuccessPage() {
  return (
    <div>
      <h1>Payment Successful! 🎉</h1>
      <p>Thank you for your purchase.</p>
      
      {/* The smart button that detects iOS app */}
      <RedeemCodeButton className="btn btn-primary">
        Redeem Your Activation Code
      </RedeemCodeButton>
      
      {/* Or with a prefilled code if you have it */}
      <RedeemCodeButton 
        code="ABCD1234"
        className="btn btn-primary"
      >
        Enter Your Code
      </RedeemCodeButton>
    </div>
  );
}
```

### 4. Alternative: Inline Usage (No Component)

If you prefer not to create a component, you can use the utility directly:

```typescript
import { isInIOSApp, openRedeemModalInIOS } from '@/lib/ios-bridge';
import { useRouter } from 'next/navigation';

function MyComponent() {
  const router = useRouter();
  
  const handleRedeemClick = () => {
    const sentToIOS = openRedeemModalInIOS();
    if (!sentToIOS) {
      router.push('/recover');
    }
  };
  
  return (
    <button onClick={handleRedeemClick}>
      Redeem Code
    </button>
  );
}
```

## Testing

### Test in iOS App:
1. Build and run the iOS app
2. Navigate to a page with the "Purchase on Web" button
3. Complete a purchase or navigate to a page with the redeem button
4. Click the redeem button
5. **Expected**: Native iOS activation modal should appear

### Test in Browser:
1. Open the web app in Safari/Chrome (not in the iOS app)
2. Navigate to the same page
3. Click the redeem button
4. **Expected**: Should redirect to `/recover` page

### Debug Logging:
- Check browser console for logs: "🌉 Sending message to iOS app..."
- Check Xcode console for logs: "🌉 iOS Bridge: Received message from web..."

## Important Notes

1. **The iOS app is already configured** to receive these messages via `WKScriptMessageHandler`
2. **The message handler name is**: `openRedeemModal` (must match exactly)
3. **Message format**: `{ action: 'openRedeemModal', code: string | null, timestamp: string }`
4. **Fallback is built-in**: If not in iOS app, automatically redirects to `/recover`
5. **Works with any framework**: Next.js, React, Vue, vanilla JavaScript

## File Structure

After implementation, your web app should have:

```
web-app/
├── lib/
│   └── ios-bridge.ts          # Bridge utility functions
├── components/
│   └── RedeemCodeButton.tsx   # Reusable button component (optional)
└── app/
    ├── success/page.tsx       # Use the button here
    ├── pricing/page.tsx       # Or here
    └── recover/page.tsx       # Existing fallback page
```

## Questions?

If you encounter any issues:
1. Check that `window.webkit.messageHandlers.openRedeemModal` exists (console.log it)
2. Verify the message format matches what iOS expects
3. Check Xcode console for iOS-side errors
4. Ensure the web app is being loaded in the iOS WKWebView (not Safari externally)

---

**That's it!** Implement the above code and the bridge will work seamlessly. The iOS side is already configured and ready to receive messages.
