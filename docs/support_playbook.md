# Customer Support Playbook (v1.0)

## 1. Contact Channels
- **In-app Help**: `Settings ▸ Help & Support` opens our support form (Zendesk integration pending). Until launch, direct users to `support@lifeapp.sh`.
- **App Store Links**: Provide the support email and privacy policy URL in both store listings.
- **Response Targets**:
  - Tier 1 (login/backup issues): respond within 1 business day.
  - Tier 2 (billing/refunds/escalations): acknowledge within 12 hours, resolve within 3 business days.

## 2. Triage Workflow
1. **Gather context**: device, OS, app version/build hash, account email/UID, reproduction steps.
2. **Classify**:
   - `Access` – login/authentication, anonymous upgrade, account deletion.
   - `Backup` – backup/restore errors, encrypted file issues.
   - `Sync` – light sync delays, daily totals mismatch.
   - `Billing` – purchases, refunds, entitlement mismatch.
   - `Feedback` – feature requests/usability questions.
3. **Log** ticket in support tracker (Notion table initially; migrate to Zendesk/Jira post-launch).

## 3. FAQ Snippets
- **How do I export or restore my data?**
  1. Go to `Account ▸ Backup & Restore`.
  2. Choose Google Drive (Android) or iCloud Drive (iOS).
  3. Tap `One-tap backup`. A timestamp appears when complete.
  4. To restore, tap `Restore`, pick the `.lifeapp.backup` file, and confirm.
- **Why is my timer alarm quiet or late?** Ensure notification and exact alarm permissions are granted (Android: Settings ▸ Apps ▸ Life App ▸ Alarms & reminders). Confirm `Timer accuracy` card shows skew within ±60s; export CSV to include with the ticket.
- **I changed devices—how do I get Premium back?** Sign in with the same account, then tap `Account ▸ Restore purchases`. RevenueCat should unlock entitlement automatically; include purchase receipt if it fails.
- **Request a refund**: For Apple, direct users to <https://reportaproblem.apple.com>. For Google Play, link to <https://support.google.com/googleplay/answer/2479637> and note the 48-hour window.

## 4. Troubleshooting Guides
### Backup / Restore failures
- Check network/drive availability; ask for the backup CSV exported via the diagnostics card.
- If AES decryption fails, confirm the user is restoring on the same account/device family. Collect backup manifest (`manifest.json`) for analysis.

### Light sync mismatch
- Verify the user is online and signed in.
- Ask for timestamp from Home ▸ “Last sync”.
- Trigger manual refresh: `Settings ▸ Sync ▸ Refresh now` (hidden debug toggle).
- If still failing, capture Firestore UID and investigate server logs.

### Billing discrepancies
- Ask for platform (iOS/Android), marketplace order ID, and screenshot of purchase receipt.
- Trigger `Account ▸ Restore purchases` to refresh RevenueCat customer info.
- If entitlement is absent, check `revenuecat_webhooks/{eventId}` for matching transaction and reconcile manually.

## 5. Escalation Ladder
1. **Level 1 (Support lead)** – resolves FAQ/known issues.
2. **Level 2 (Engineering on-call)** – handles crashes, data inconsistencies, subscription reconciliation.
3. **Level 3 (Founder/PM)** – policy/compliance questions, large refunds, PR-sensitive incidents.

Maintain the ladder in the on-call calendar; include Slack handles and phone numbers (stored in the private ops vault).

## 6. Metrics & Reporting
- Weekly: tickets opened/closed, average response time, churn-related inquiries.
- Monthly: top 5 categories, backup success complaints, subscription refund rate.
- Feed critical insights into the product backlog grooming session.

## 7. Templates
- **Acknowledgement**
  > Hi {name}, thanks for reaching out! We’re reviewing your report about {issue}. We’ll follow up within {SLA window}. Meanwhile, please confirm your app version by opening Account ▸ About.

- **Resolution**
  > We’ve updated your subscription status—please restart the app or visit Account ▸ Restore purchases. Let us know if you still see the issue.

Store editable templates in the shared “Support Macros” Notion page.
