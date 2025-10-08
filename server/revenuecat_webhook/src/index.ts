import crypto from 'node:crypto';
import express from 'express';
import bodyParser from 'body-parser';
import admin from 'firebase-admin';

const sharedSecret = process.env.REVENUECAT_WEBHOOK_SECRET;
if (!sharedSecret) {
  console.warn('[revenuecat-webhook] Missing REVENUECAT_WEBHOOK_SECRET env var');
}

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

const app = express();

app.use(
  bodyParser.json({
    verify: (req: express.Request & { rawBody?: Buffer }, _res, buf) => {
      req.rawBody = Buffer.from(buf);
    },
  }),
);

function verifySignature(rawBody: Buffer | undefined, signature: string | undefined): boolean {
  if (!sharedSecret || !rawBody || !signature) return false;
  const expected = crypto
    .createHmac('sha1', sharedSecret)
    .update(rawBody)
    .digest('hex');
  // RevenueCat prefixes signature with `sha1=`
  const normalized = signature.replace(/^sha1=/, '').toLowerCase();
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(normalized));
}

app.post('/hooks/revenuecat', async (req, res) => {
  const signature = req.header('X-Webhook-Signature');
  const rawBody = (req as express.Request & { rawBody?: Buffer }).rawBody;

  if (!verifySignature(rawBody, signature)) {
    return res.status(401).json({ ok: false, error: 'invalid_signature' });
  }

  const event = req.body as Record<string, unknown>;
  const eventId = (event['event_id'] ?? event['id'] ?? crypto.randomUUID()) as string;

  try {
    await firestore
      .collection('revenuecat_webhooks')
      .doc(eventId)
      .set({
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        raw: event,
        processed: false,
      }, { merge: true });

    res.json({ ok: true });
  } catch (error) {
    console.error('[revenuecat-webhook] Failed to persist event', error);
    res.status(500).json({ ok: false, error: 'persist_failed' });
  }
});

const port = process.env.PORT ?? 5001;
app.listen(port, () => {
  console.log(`[revenuecat-webhook] listening on port ${port}`);
});
