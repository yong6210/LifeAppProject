# RevenueCat Webhook Receiver

> Minimal Express + Firebase Admin service that ingests RevenueCat webhook
> events and stores them in Firestore for later processing.

## Features

- Verifies `X-Webhook-Signature` using the shared secret from the RevenueCat
  dashboard.
- Persists raw events under `revenuecat_webhooks/{eventId}` with a `processed`
  flag so background workers can pick them up.
- Ships as a TypeScript project; run locally with `npm run dev` or deploy to
  Cloud Run / Cloud Functions.

## Environment Variables

| Name                         | Description                                             |
| ---------------------------- | ------------------------------------------------------- |
| `REVENUECAT_WEBHOOK_SECRET`  | Shared webhook secret (from RevenueCat dashboard).      |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to a service account JSON with Firestore access. |

## Local Development

```bash
cd server/revenuecat_webhook
npm install
export REVENUECAT_WEBHOOK_SECRET="super-secret"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/sa.json"
npm run dev
```

The service listens on <http://localhost:5001/hooks/revenuecat>. You can replay
an event using curl:

```bash
payload='{"event_id":"demo","type":"INITIAL_PURCHASE"}'
signature="sha1=$(printf "%s" "$payload" | openssl dgst -sha1 -hmac "$REVENUECAT_WEBHOOK_SECRET" | cut -d' ' -f2)"
curl \
  -X POST http://localhost:5001/hooks/revenuecat \
  -H "X-Webhook-Signature: $signature" \
  -H "Content-Type: application/json" \
  -d "$payload"
```

## Processing Events

Downstream workers can watch the `revenuecat_webhooks` collection for
unprocessed documents (`processed == false`), reconcile entitlements, and then
mark them as handled.

## Deployment Notes

- **Cloud Run**: Build with `npm run build`, create a container, and set the
  required env variables.
- **Firebase Functions**: Wrap the Express app inside a function handler
  (`functions.https.onRequest(app)`) and deploy via `firebase deploy`.

Remember to configure the webhook endpoint URL inside RevenueCat once the
service is accessible from the internet.
