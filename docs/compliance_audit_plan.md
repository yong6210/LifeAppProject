# Compliance & Dependency Audit Plan (v1.0)

## Objectives
- Regularly review privacy, security, and policy obligations (Apple/Google, GDPR-like requirements).
- Ensure dependencies stay updated with security fixes.

## Cadence
- **Quarterly** (Jan, Apr, Jul, Oct) compliance and dependency review.
- **Monthly** dependency spot-check for critical packages (Firebase, RevenueCat).

## Compliance Checklist (Quarterly)
1. **Privacy Policy & Data Deletion**
   - Confirm privacy policy matches current data flows.
   - Verify in-app account deletion still functioning (manual test).
   - Review data retention logs (backup exports) for anomalies.
2. **Store Policies**
   - Apple App Store: review latest App Review Guidelines (esp. account deletion, sign-in).
   - Google Play: confirm Data Safety form matches app behavior.
3. **Security**
   - Audit encryption key handling (Keychain/Keystore).
   - Ensure AES backup encryption code paths unchanged; run unit tests.
4. **Third-party Services**
   - Review Firebase, RevenueCat DPAs and SLA updates.
   - Verify webhook endpoints (server/revenuecat_webhook) are secured.

Document findings in `docs/compliance/audit_<YYYY-MM>.md` (template TBD).

## Dependency Audit
- Generate dependency report:
  - Flutter packages: `flutter pub outdated`.
  - Node backend (webhook): `npm outdated`.
- Evaluate upgrades:
  - Security patches → immediate.
  - Minor updates → schedule monthly.
- Track actions in Notion “Dependency Upkeep” board.

## Roles
- **Compliance Owner (PM/Ops)**: Run quarterly checklist, update documentation, coordinate policy updates.
- **Engineering**: Execute dependency upgrades, run regression tests, update changelog.

## Tools & Notifications
- Subscribe to Firebase, RevenueCat release notes.
- Use GitHub Dependabot for server packages (enable in `server/`).
- Create calendar reminders for quarterly reviews.

Adjust cadence as regulatory requirements evolve.
