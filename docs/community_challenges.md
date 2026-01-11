# Community Challenges Expansion

This document scopes the next iteration of Community Challenges:
user profiles + premium rewards.

## Profile Integration
Goal: replace `ownerId` stubs and member display names with real user profiles.

Proposed data model:
- `users/{uid}`: `displayName`, `avatarUrl`, `timezone`, `premiumTier`
- `challenges/{id}/members/{uid}`: `joinedAt`, `focusMinutes`, `restMinutes`
- `challenges/{id}` summary: `ownerId`, `memberIds`, `privacy`, `template`

Checklist:
- [ ] Create a `UserProfile` model and repository
- [ ] Update `ChallengeMember` to include `avatarUrl` and `premiumTier`
- [ ] Migrate Firestore writes to store member data in sub-collection
- [ ] Update challenge list UI to read profile snapshots
- [ ] Add security rules for read/write access
- [ ] Add indexing for `memberIds` + `ownerId` queries

## Premium Rewards
Goal: unlock benefits for completing challenges with premium status.

Reward concepts:
- Premium badge on challenge leaderboard
- Bonus streak multiplier (visual-only at first)
- Extra templates for premium users

Checklist:
- [ ] Define reward rules (premium tier + completion thresholds)
- [ ] Update `CommunityChallenge` UI to show rewards
- [ ] Integrate with `RevenueCatService` for tier checks
- [ ] Add server-side validation (Cloud Function or rules)
- [ ] Add analytics for reward unlocks

## Migration Notes
- Keep backward compatibility by reading legacy `members` arrays and writing
  to new sub-collections.
- Provide a one-time backfill job for existing challenges.
