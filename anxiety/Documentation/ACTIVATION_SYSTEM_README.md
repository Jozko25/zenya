# Activation Code System - Implementation Guide

## 📋 Overview

This system allows users to:
1. **Purchase on web** (Stripe payment)
2. **Receive activation code** (email + clipboard)
3. **Download app** from App Store
4. **Enter code** in app
5. **Unlock premium** features

---

## 🗄️ Database Setup

### Step 1: Run SQL Schema

1. Open Supabase Dashboard → SQL Editor
2. Run the file: `ACTIVATION_SYSTEM_SCHEMA.sql`
3. Verify tables created:
   - ✅ `activation_codes`
   - ✅ `web_purchases`
   - ✅ `recovery_attempts`

### Step 2: Verify Test Code

A test code is auto-created: `OASIS-TEST-CODE`
- Email: test@example.com
- Plan: annual
- Never expires (for testing)

---

## 🔧 Next Steps

### 1. Create Supabase Edge Functions

You'll need 3 Edge Functions:

**`generate-activation-code`** - Called by Stripe webhook
```bash
supabase functions new generate-activation-code
```

**`redeem-activation-code`** - Called by iOS app
```bash
supabase functions new redeem-activation-code
```

**`verify-payment-lookup`** - For code recovery
```bash
supabase functions new verify-payment-lookup
```

### 2. Set Up Stripe Webhook

1. Create Stripe account
2. Add webhook endpoint: `https://your-project.supabase.co/functions/v1/generate-activation-code`
3. Listen for: `checkout.session.completed`

### 3. Build Web Frontend

- Landing page
- Stripe Checkout integration
- Success page (shows code + auto-copy)

### 4. Update iOS App

- Create `ActivationCodeView.swift`
- Create `ActivationService.swift`
- Add clipboard detection
- Remove StoreKit code

---

## 🔐 Security Features

✅ **Rate Limiting** - 3 recovery attempts per hour per IP
✅ **Code Expiration** - Codes expire after 30 days if not redeemed
✅ **One-Time Use** - Each code can only be redeemed once
✅ **Payment Verification** - Last 4 + ZIP for recovery
✅ **Audit Logging** - All attempts tracked in `recovery_attempts`

---

## 📊 Useful Queries

### Check active subscriptions
```sql
SELECT * FROM active_subscriptions;
```

### Check unredeemed codes
```sql
SELECT * FROM unredeemed_codes;
```

### Revenue stats
```sql
SELECT * FROM revenue_stats;
```

### Recent purchases
```sql
SELECT * FROM web_purchases 
WHERE created_at > now() - INTERVAL '7 days'
ORDER BY created_at DESC;
```

---

## 🧪 Testing

### Test Code Redemption (Manual)

```sql
-- 1. Generate a test code
INSERT INTO activation_codes (
    code, email, plan_type, amount_paid, expires_at
) VALUES (
    'OASIS-TEST-ABCD',
    'test@test.com',
    'annual',
    59.99,
    now() + INTERVAL '365 days'
);

-- 2. Test redemption in app with code: OASIS-TEST-ABCD

-- 3. Verify it was redeemed
SELECT is_redeemed, redeemed_at 
FROM activation_codes 
WHERE code = 'OASIS-TEST-ABCD';
```

---

## 📧 Email Templates Needed

1. **Purchase Success** - Sent after payment
2. **Code Recovery** - Sent for lost codes
3. **Expiration Warning** - 7 days before expiry
4. **Subscription Expired** - When code expires

---

## 🚀 Deployment Checklist

- [ ] Database schema deployed to Supabase
- [ ] Edge Functions created and deployed
- [ ] Stripe webhook configured
- [ ] Web frontend deployed
- [ ] iOS app updated with activation screen
- [ ] Test end-to-end flow
- [ ] Monitor error logs

---

**Status:** Database schema ready ✅  
**Next:** Create Edge Functions
