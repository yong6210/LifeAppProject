# RevenueCat Webhook Integration Plan

## Objective

Capture subscription lifecycle events (purchase, renewal, cancellation, billing
issues) from RevenueCat and mirror the state into Firestore so the app can
react quickly and analytics dashboards stay in sync.

## Architecture

1. **Webhook receiver** (see `server/revenuecat_webhook/`)
   - Validates signatures with `REVENUECAT_WEBHOOK_SECRET`.
   - Persists raw payloads to `revenuecat_webhooks/{eventId}` with
     `processed=false`.
2. **Processor worker** (future)
   - Cloud Function or Cloud Run job subscribed to Firestore document writes.
   - Parses the payload, updates `users/{uid}/subscription_status` document,
     triggers analytics events, then sets `processed=true`.
3. **Analytics export**
   - Optional BigQuery sink that mirrors the collection for longer retention.

## Firestore Schema

```
revenuecat_webhooks/{eventId}
  receivedAt: Timestamp
  raw: Map
  processed: bool
  lastError: string | null
```

## Security Rules

Only the backend service account should write to the collection. Add the
following rule snippet to `firebase/firestore.rules`:

```firestore
match /revenuecat_webhooks/{eventId} {
  allow read: if false; // never readable from clients
  allow write: if request.auth.uid == null && request.auth.token.admin == true;
}
```

Deploy the webhook receiver using the service account with the `admin` custom
claim or use the default Firebase Admin SDK with the service account key.

## Deployment Checklist

1. Create a dedicated service account (`revenuecat-webhook@project.iam.gserviceaccount.com`).
2. Grant Firestore `roles/datastore.user` and Cloud Logging writer.
3. Set `REVENUECAT_WEBHOOK_SECRET` env variable from the RevenueCat dashboard.
4. Deploy `server/revenuecat_webhook` to Cloud Run (recommended) and place it
   behind HTTPS.
5. Configure the webhook endpoint in RevenueCat → *Project Settings → Webhooks*.
6. Monitor logs (`gcloud logs tail`) to ensure events arrive and persist.
7. Implement the processor worker to update user entitlements.

## Future Enhancements

- Auto-resume failed events by checking `processed=false` with exponential backoff.
- Forward summarized metrics to BigQuery / Looker dashboards.
- Trigger Slack notifications for churn / billing grace periods using the same stream.
