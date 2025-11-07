import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

const allowedMoods = new Set([
  'depleted',
  'low',
  'steady',
  'thriving',
  'radiant',
]);

const allowedSlots = ['bed', 'desk', 'lighting', 'wall', 'floor', 'accent'] as const;
type DecorSlot = typeof allowedSlots[number];

interface DecorItemConfig {
  slot: DecorSlot;
  requiresPremium: boolean;
  unlockLevel: number;
  costCoins: number;
}

const decorCatalog: Record<string, DecorItemConfig> = {
  bed_basic: { slot: 'bed', requiresPremium: false, unlockLevel: 1, costCoins: 0 },
  desk_focus: { slot: 'desk', requiresPremium: false, unlockLevel: 2, costCoins: 120 },
  lamp_mellow: { slot: 'lighting', requiresPremium: false, unlockLevel: 2, costCoins: 90 },
  poster_motivation: { slot: 'wall', requiresPremium: false, unlockLevel: 3, costCoins: 60 },
  rug_grounded: { slot: 'floor', requiresPremium: false, unlockLevel: 4, costCoins: 140 },
  plant_companion: { slot: 'accent', requiresPremium: false, unlockLevel: 5, costCoins: 150 },
  lamp_sunrise: { slot: 'lighting', requiresPremium: true, unlockLevel: 6, costCoins: 0 },
};

const defaultOwnedItems = new Set<string>(['bed_basic']);
const MAX_BUFF_VALUE = 1.0;

const moodPriority: Record<string, number> = {
  depleted: 0,
  low: 1,
  steady: 2,
  thriving: 3,
  radiant: 4,
};

function sanitizeDisplayName(raw: unknown): string | null {
  if (typeof raw !== 'string') {
    return null;
  }
  const trimmed = raw.trim();
  if (!trimmed) {
    return null;
  }
  return trimmed.length > 32 ? trimmed.slice(0, 32) : trimmed;
}

function normalizeOwned(raw: unknown): Set<string> {
  const owned = new Set<string>(defaultOwnedItems);
  if (Array.isArray(raw)) {
    for (const value of raw) {
      if (typeof value === 'string') {
        owned.add(value);
      }
    }
  }
  return owned;
}

function sanitizeBuffSnapshot(raw: unknown): Record<string, number> {
  const result: Record<string, number> = {};
  if (!raw || typeof raw !== 'object') {
    return result;
  }
  for (const [key, value] of Object.entries(raw as Record<string, unknown>)) {
    if (typeof value !== 'number' || !Number.isFinite(value)) {
      continue;
    }
    const clamped = Math.max(0, Math.min(MAX_BUFF_VALUE, value));
    result[key] = Number(clamped.toFixed(4));
  }
  return result;
}

function areBuffSnapshotsEqual(a: Record<string, number>, b: Record<string, number>): boolean {
  const aKeys = Object.keys(a);
  const bKeys = Object.keys(b);
  if (aKeys.length !== bKeys.length) {
    return false;
  }
  for (const key of aKeys) {
    if (a[key] !== b[key]) {
      return false;
    }
  }
  return true;
}

function aggregateBuffMaps(buffMaps: Array<Record<string, number>>): Record<string, number> {
  const totals = new Map<string, { sum: number; samples: number }>();
  for (const map of buffMaps) {
    for (const [key, value] of Object.entries(map)) {
      const current = totals.get(key) ?? { sum: 0, samples: 0 };
      current.sum += value;
      current.samples += 1;
      totals.set(key, current);
    }
  }
  const aggregated: Record<string, number> = {};
  for (const [key, value] of totals.entries()) {
    if (value.samples <= 0) {
      continue;
    }
    aggregated[key] = Number((value.sum / value.samples).toFixed(4));
  }
  return aggregated;
}

function pickAverageMood(moods: string[]): string {
  if (!moods.length) {
    return 'steady';
  }
  const counts = new Map<string, number>();
  for (const mood of moods) {
    if (!allowedMoods.has(mood)) {
      continue;
    }
    counts.set(mood, (counts.get(mood) ?? 0) + 1);
  }
  if (!counts.size) {
    return 'steady';
  }

  let bestMood = 'steady';
  let bestCount = -1;
  let bestPriority = -1;
  for (const [mood, count] of counts.entries()) {
    const priority = moodPriority[mood] ?? 0;
    if (count > bestCount || (count === bestCount && priority > bestPriority)) {
      bestMood = mood;
      bestCount = count;
      bestPriority = priority;
    }
  }
  return bestMood;
}

function sanitizeLifeBuddyState(
  raw: FirebaseFirestore.DocumentData,
  options: { ownedItems: Set<string>; isPremiumUser: boolean },
): { changed: boolean; data: { level: number; experience: number; mood: string; equippedSlots: Record<string, string> } } {
  const sanitizedLevel = Number.isFinite(raw.level)
    ? Math.max(1, Math.floor(raw.level as number))
    : 1;
  const sanitizedExperience = Number.isFinite(raw.experience)
    ? Math.max(0, Number(raw.experience))
    : 0;
  const mood = typeof raw.mood === 'string' && allowedMoods.has(raw.mood)
    ? raw.mood
    : 'steady';

  const existingSlots: Record<string, string> = {};
  if (raw.equippedSlots && typeof raw.equippedSlots === 'object') {
    Object.entries(raw.equippedSlots as Record<string, unknown>).forEach(([key, value]) => {
      if (typeof value === 'string') {
        existingSlots[key] = value;
      }
    });
  }

  const sanitizedSlots: Record<string, string> = {};
  for (const slot of allowedSlots) {
    const equippedId = existingSlots[slot];
    if (typeof equippedId !== 'string') {
      continue;
    }
    const item = decorCatalog[equippedId];
    if (!item) {
      continue;
    }
    if (item.slot !== slot) {
      continue;
    }
    if (item.unlockLevel > sanitizedLevel) {
      continue;
    }
    if (item.requiresPremium && !options.isPremiumUser) {
      continue;
    }
    if (!options.ownedItems.has(equippedId)) {
      continue;
    }
    sanitizedSlots[slot] = equippedId;
  }

  const changed =
    sanitizedLevel !== raw.level ||
    sanitizedExperience !== raw.experience ||
    mood !== raw.mood ||
    !areSlotMapsEqual(existingSlots, sanitizedSlots);

  return {
    changed,
    data: {
      level: sanitizedLevel,
      experience: sanitizedExperience,
      mood,
      equippedSlots: sanitizedSlots,
    },
  };
}

function areSlotMapsEqual(a: Record<string, string>, b: Record<string, string>): boolean {
  const aKeys = Object.keys(a);
  const bKeys = Object.keys(b);
  if (aKeys.length !== bKeys.length) {
    return false;
  }
  for (const key of aKeys) {
    if (a[key] !== b[key]) {
      return false;
    }
  }
  return true;
}

export async function applyLifeBuddyStateWrite({
  beforeData,
  afterData,
  inventory,
  stateRef,
  serverTimestamp,
}: {
  beforeData: FirebaseFirestore.DocumentData | null;
  afterData: FirebaseFirestore.DocumentData;
  inventory: FirebaseFirestore.DocumentData;
  stateRef: {
    set: (
      data: FirebaseFirestore.DocumentData,
      options: FirebaseFirestore.SetOptions,
    ) => Promise<unknown>;
  };
  serverTimestamp: () => FirebaseFirestore.FieldValue;
}): Promise<{ changed: boolean; sanitized: ReturnType<typeof sanitizeLifeBuddyState>['data'] }> {
  const ownedItems = normalizeOwned(inventory.owned);
  const isPremiumUser = Boolean(inventory.isPremiumUser);
  const sanitized = sanitizeLifeBuddyState(afterData, { ownedItems, isPremiumUser });

  if (!sanitized.changed) {
    return { changed: false, sanitized: sanitized.data };
  }

  await stateRef.set(
    {
      ...sanitized.data,
      updatedAt: serverTimestamp(),
    },
    { merge: true },
  );

  return { changed: true, sanitized: sanitized.data };
}

export async function recordLifeBuddySanitizedEvent({
  eventsCollection,
  beforeData,
  sanitizedData,
  serverTimestamp,
}: {
  eventsCollection: {
    add: (data: FirebaseFirestore.DocumentData) => Promise<unknown>;
  };
  beforeData: FirebaseFirestore.DocumentData | null;
  sanitizedData: ReturnType<typeof sanitizeLifeBuddyState>['data'];
  serverTimestamp: () => FirebaseFirestore.FieldValue;
}): Promise<void> {
  await eventsCollection.add({
    type: 'state_sanitized',
    timestamp: serverTimestamp(),
    before: {
      level: beforeData?.level ?? null,
      experience: beforeData?.experience ?? null,
      mood: beforeData?.mood ?? null,
      equippedSlots: beforeData?.equippedSlots ?? {},
    },
    after: sanitizedData,
  });
}

export const onLifeBuddyStateWrite = functions.firestore
  .document('users/{userId}/life_buddy_state/state')
  .onWrite(async (change, context) => {
    if (!change.after.exists) {
      return null;
    }

    const userId = context.params.userId as string;
    const after = change.after.data();
    if (!after) {
      return null;
    }

    const inventorySnap = await admin.firestore()
      .doc(`users/${userId}/decor_inventory/state`)
      .get();
    const inventory = inventorySnap.data() ?? {};
    const beforeData = change.before.data() ?? null;
    const serverTimestamp = () => admin.firestore.FieldValue.serverTimestamp();

    const result = await applyLifeBuddyStateWrite({
      beforeData,
      afterData: after,
      inventory,
      stateRef: change.after.ref,
      serverTimestamp,
    });

    if (!result.changed) {
      return null;
    }

    functions.logger.info('Sanitizing life_buddy_state write', {
      userId,
      before: beforeData,
      after,
      sanitized: result.sanitized,
    });

    const parentDoc = change.after.ref.parent.parent;
    if (parentDoc) {
      try {
        await recordLifeBuddySanitizedEvent({
          eventsCollection: parentDoc.collection('life_buddy_events'),
          beforeData,
          sanitizedData: result.sanitized,
          serverTimestamp,
        });
      } catch (eventError) {
        functions.logger.warn('Failed to record life_buddy_state event', {
          userId,
          error: (eventError as Error).message,
        });
      }
    }

    return null;
  });

export const claimDailyQuest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const questId = typeof data?.questId === 'string' && data.questId.length > 0
    ? data.questId
    : 'daily_focus';
  const uid = context.auth.uid;

  const inventoryRef = admin.firestore().doc(`users/${uid}/decor_inventory/state`);
  const rewardCoins = 20;

  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(inventoryRef);
    const doc = snap.data() ?? {};
    const claimed: string[] = Array.isArray(doc.claimedQuests) ? doc.claimedQuests : [];
    if (claimed.includes(questId)) {
      throw new functions.https.HttpsError('failed-precondition', 'Quest already claimed');
    }

    const newClaimed = [...claimed, questId];
    const currentCoins = Number.isFinite(doc.softCurrency) ? Number(doc.softCurrency) : 0;
    tx.set(
      inventoryRef,
      {
        softCurrency: currentCoins + rewardCoins,
        claimedQuests: newClaimed,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  return {
    ok: true,
    reward: { coins: rewardCoins },
    questId,
  };
});

export const unlockDecorItem = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const decorId = typeof data?.decorId === 'string' ? data.decorId.trim() : '';
  if (!decorId) {
    throw new functions.https.HttpsError('invalid-argument', 'decorId is required');
  }

  const decor = decorCatalog[decorId];
  if (!decor) {
    throw new functions.https.HttpsError('not-found', 'Decor item not found');
  }

  const uid = context.auth.uid;
  const inventoryRef = admin.firestore().doc(`users/${uid}/decor_inventory/state`);
  const stateRef = admin.firestore().doc(`users/${uid}/life_buddy_state/state`);
  const serverTimestamp = admin.firestore.FieldValue.serverTimestamp;

  const writeResult = await admin.firestore().runTransaction(async (tx) => {
    const [inventorySnap, stateSnap] = await Promise.all([
      tx.get(inventoryRef),
      tx.get(stateRef),
    ]);

    const inventoryDoc = inventorySnap.data() ?? {};
    const stateDoc = stateSnap.data() ?? {};

    const owned: Set<string> = normalizeOwned(inventoryDoc.owned);
    if (owned.has(decorId)) {
      throw new functions.https.HttpsError('failed-precondition', 'Decor already owned');
    }

    const playerLevel = Number.isFinite(stateDoc.level) ? Math.max(1, Number(stateDoc.level)) : 1;
    if (playerLevel < decor.unlockLevel) {
      throw new functions.https.HttpsError('failed-precondition', 'Level requirement not met');
    }

    const isPremiumUser = Boolean(inventoryDoc.isPremiumUser);
    if (decor.requiresPremium && !isPremiumUser) {
      throw new functions.https.HttpsError('permission-denied', 'Premium membership required');
    }

    let remainingCoins = Number.isFinite(inventoryDoc.softCurrency)
      ? Number(inventoryDoc.softCurrency)
      : 0;

    if (!decor.requiresPremium) {
      if (remainingCoins < decor.costCoins) {
        throw new functions.https.HttpsError('failed-precondition', 'Not enough coins');
      }
      remainingCoins -= decor.costCoins;
    }

    owned.add(decorId);
    const ownedArray = Array.from(owned);

    tx.set(
      inventoryRef,
      {
        owned: ownedArray,
        softCurrency: remainingCoins,
        updatedAt: serverTimestamp(),
        lastUnlock: {
          decorId,
          costCoins: decor.costCoins,
          requiresPremium: decor.requiresPremium,
          purchasedAt: serverTimestamp(),
        },
      },
      { merge: true },
    );

    return {
      owned: ownedArray,
      softCurrency: remainingCoins,
      wasPremium: decor.requiresPremium,
      level: playerLevel,
    };
  });

  try {
    await inventoryRef.parent?.parent
      ?.collection('life_buddy_events')
      .add({
        type: 'decor_unlocked',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          decorId,
          costCoins: decor.costCoins,
          requiresPremium: decor.requiresPremium,
        },
      });
  } catch (error) {
    functions.logger.warn('Failed to append decor_unlocked event', {
      userId: uid,
      decorId,
      error: (error as Error).message,
    });
  }

  return {
    ok: true,
    decorId,
    remainingCoins: writeResult.softCurrency,
    requiresPremium: decor.requiresPremium,
  };
});

async function appendPartyActivity(partyId: string, data: {
  type: string;
  message: string;
  userId?: string;
  metadata?: Record<string, unknown>;
}): Promise<void> {
  try {
    await admin.firestore()
      .collection(`parties/${partyId}/activity_feed`)
      .add({
        ...data,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
  } catch (error) {
    functions.logger.warn('Failed to append party activity event', {
      partyId,
      type: data.type,
      error: (error as Error).message,
    });
  }
}

async function recomputePartyAggregates(partyId: string): Promise<void> {
  const firestore = admin.firestore();
  const membersSnap = await firestore
    .collection(`parties/${partyId}/members`)
    .get();
  const metadataRef = firestore.doc(`parties/${partyId}/metadata`);

  if (membersSnap.empty) {
    await metadataRef.set(
      {
        sharedBuffs: {},
        averageMood: 'steady',
        memberCount: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return;
  }

  const buffMaps: Array<Record<string, number>> = [];
  const moods: string[] = [];

  membersSnap.forEach((doc) => {
    const data = doc.data() ?? {};
    buffMaps.push(sanitizeBuffSnapshot(data.buffShare));
    if (typeof data.mood === 'string' && allowedMoods.has(data.mood)) {
      moods.push(data.mood);
    }
  });

  const aggregated = aggregateBuffMaps(buffMaps);
  const averageMood = pickAverageMood(moods);

  await metadataRef.set(
    {
      sharedBuffs: aggregated,
      averageMood,
      memberCount: membersSnap.size,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

export const joinParty = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const partyIdRaw = typeof data?.partyId === 'string' ? data.partyId.trim() : '';
  if (!partyIdRaw) {
    throw new functions.https.HttpsError('invalid-argument', 'partyId is required');
  }
  if (!/^[a-zA-Z0-9_-]{4,40}$/.test(partyIdRaw)) {
    throw new functions.https.HttpsError('invalid-argument', 'partyId must be 4-40 characters (alphanumeric, _, -)');
  }

  const requestedDisplayName = sanitizeDisplayName(data?.displayName);
  const partyId = partyIdRaw;
  const uid = context.auth.uid;
  const firestore = admin.firestore();

  const membershipRef = firestore.doc(`users/${uid}/party_membership/state`);
  const stateRef = firestore.doc(`users/${uid}/life_buddy_state/state`);
  const metadataRef = firestore.doc(`parties/${partyId}/metadata`);
  const memberRef = firestore.doc(`parties/${partyId}/members/${uid}`);

  const nowValue = admin.firestore.FieldValue.serverTimestamp();
  let joinedNewMember = false;
  let resultingRole = 'member';
  let resultingDisplayName: string | null = null;

  await firestore.runTransaction(async (tx) => {
    const membershipSnap = await tx.get(membershipRef);
    const metadataSnap = await tx.get(metadataRef);

    if (!metadataSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Party not found');
    }

    const metadata = metadataSnap.data() ?? {};
    const memberLimit = Number.isFinite(metadata.memberLimit) ? Number(metadata.memberLimit) : 10;
    let memberCount = Number.isFinite(metadata.memberCount) ? Number(metadata.memberCount) : 0;

    let existingPartyId: string | null = null;
    let existingRole = 'member';
    if (membershipSnap.exists) {
      const membershipData = membershipSnap.data() ?? {};
      if (typeof membershipData.partyId === 'string') {
        existingPartyId = membershipData.partyId;
      }
      if (typeof membershipData.role === 'string') {
        existingRole = membershipData.role;
      }
    }

    if (existingPartyId && existingPartyId !== partyId) {
      throw new functions.https.HttpsError('failed-precondition', '이미 다른 파티에 참여 중입니다.');
    }

    const memberSnap = await tx.get(memberRef);
    const stateSnap = await tx.get(stateRef);
    const stateData = stateSnap.data() ?? {};
    const stateDisplayName = sanitizeDisplayName(
      typeof stateData.displayName === 'string' ? stateData.displayName : stateData.nickname,
    );

    const buffShare = sanitizeBuffSnapshot(stateData.buffSnapshot);
    const level = Number.isFinite(stateData.level)
      ? Math.max(1, Math.floor(Number(stateData.level)))
      : 1;
    const mood = typeof stateData.mood === 'string' && allowedMoods.has(stateData.mood)
      ? stateData.mood
      : 'steady';

    const existingMemberDisplayName = sanitizeDisplayName(memberSnap.data()?.displayName);
    resultingDisplayName =
      requestedDisplayName ??
      sanitizeDisplayName(membershipSnap.data()?.displayName) ??
      existingMemberDisplayName ??
      stateDisplayName;

    if (!memberSnap.exists) {
      if (memberCount >= memberLimit) {
        throw new functions.https.HttpsError('resource-exhausted', '파티 정원이 가득 찼어요.');
      }
      memberCount += 1;
      joinedNewMember = true;
    }

    const membershipPayload: FirebaseFirestore.DocumentData = {
      partyId,
      role: existingPartyId ? existingRole : 'member',
      joinedAt: membershipSnap.data()?.joinedAt ?? nowValue,
      buffShare,
      lastHeartbeat: nowValue,
      displayName: resultingDisplayName,
    };

    resultingRole = membershipPayload.role;

    tx.set(
      membershipRef,
      membershipPayload,
      { merge: true },
    );

    tx.set(
      memberRef,
      {
        displayName: resultingDisplayName,
        mood,
        level,
        buffShare,
        role: resultingRole,
        lastSyncAt: nowValue,
      },
      { merge: true },
    );

    tx.set(
      metadataRef,
      {
        memberCount,
        updatedAt: nowValue,
      },
      { merge: true },
    );
  });

  try {
    await recomputePartyAggregates(partyId);
  } catch (error) {
    functions.logger.warn('Failed to recompute party aggregates after join', {
      partyId,
      userId: uid,
      error: (error as Error).message,
    });
  }

  if (joinedNewMember) {
    await appendPartyActivity(partyId, {
      type: 'member_joined',
      message: `${resultingDisplayName ?? '멤버'} 님이 파티에 합류했어요.`,
      userId: uid,
    });
  }

  return {
    ok: true,
    partyId,
    role: resultingRole,
    joined: joinedNewMember,
  };
});

export const leaveParty = functions.https.onCall(async (_data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Login required');
  }

  const uid = context.auth.uid;
  const firestore = admin.firestore();
  const membershipRef = firestore.doc(`users/${uid}/party_membership/state`);

  let partyId: string | null = null;
  let displayName: string | null = null;

  await firestore.runTransaction(async (tx) => {
    const membershipSnap = await tx.get(membershipRef);
    if (!membershipSnap.exists) {
      throw new functions.https.HttpsError('failed-precondition', '현재 참여 중인 파티가 없어요.');
    }

    const membershipData = membershipSnap.data() ?? {};
    if (typeof membershipData.partyId !== 'string' || !membershipData.partyId) {
      throw new functions.https.HttpsError('failed-precondition', '현재 참여 중인 파티가 없어요.');
    }

    partyId = membershipData.partyId;
    displayName = sanitizeDisplayName(membershipData.displayName);

    const memberRef = firestore.doc(`parties/${partyId}/members/${uid}`);
    const metadataRef = firestore.doc(`parties/${partyId}/metadata`);

    const [memberSnap, metadataSnap] = await Promise.all([
      tx.get(memberRef),
      tx.get(metadataRef),
    ]);

    const metadata = metadataSnap.data() ?? {};
    const memberCount = Number.isFinite(metadata.memberCount) ? Number(metadata.memberCount) : 0;
    const nextCount = Math.max(0, memberCount - 1);
    const nowValue = admin.firestore.FieldValue.serverTimestamp();

    tx.delete(memberRef);
    tx.delete(membershipRef);
    tx.set(
      metadataRef,
      {
        memberCount: nextCount,
        updatedAt: nowValue,
      },
      { merge: true },
    );

    if (!displayName) {
      displayName = sanitizeDisplayName(memberSnap.data()?.displayName);
    }
  });

  if (partyId) {
    try {
      await recomputePartyAggregates(partyId);
    } catch (error) {
      functions.logger.warn('Failed to recompute party aggregates after leave', {
        partyId,
        userId: uid,
        error: (error as Error).message,
      });
    }

    await appendPartyActivity(partyId, {
      type: 'member_left',
      message: `${displayName ?? '멤버'} 님이 파티를 떠났어요.`,
      userId: uid,
    });
  }

  return {
    ok: true,
    partyId,
  };
});

export const processPartyBuffUpdate = functions.firestore
  .document('users/{userId}/life_buddy_state/state')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId as string;
    const after = change.after.data();
    const before = change.before.data() ?? {};

    if (!after) {
      return null;
    }

    const membershipRef = admin.firestore().doc(`users/${userId}/party_membership/state`);
    const membershipSnap = await membershipRef.get();
    const membershipData = membershipSnap.data();
    const partyId = typeof membershipData?.partyId === 'string' ? membershipData.partyId : null;
    if (!partyId) {
      return null;
    }

    const buffShare = sanitizeBuffSnapshot(after.buffSnapshot);
    const prevBuff = sanitizeBuffSnapshot(before.buffSnapshot);
    const level = Number.isFinite(after.level) ? Math.max(1, Math.floor(Number(after.level))) : 1;
    const prevLevel = Number.isFinite(before.level) ? Math.max(1, Math.floor(Number(before.level))) : level;
    const mood = typeof after.mood === 'string' && allowedMoods.has(after.mood) ? after.mood : 'steady';
    const prevMood = typeof before.mood === 'string' && allowedMoods.has(before.mood) ? before.mood : 'steady';

    if (areBuffSnapshotsEqual(buffShare, prevBuff) && level === prevLevel && mood === prevMood) {
      return null;
    }

    const memberRef = admin.firestore().doc(`parties/${partyId}/members/${userId}`);
    const nowValue = admin.firestore.FieldValue.serverTimestamp();

    await admin.firestore().runTransaction(async (tx) => {
      const memberSnap = await tx.get(memberRef);
      const existing = memberSnap.data() ?? {};
      const role = typeof membershipData?.role === 'string'
        ? membershipData.role
        : typeof existing.role === 'string'
          ? existing.role
          : 'member';

      const effectiveDisplayName =
        sanitizeDisplayName(existing.displayName) ??
        sanitizeDisplayName(membershipData?.displayName) ??
        null;

      tx.set(
        memberRef,
        {
          displayName: effectiveDisplayName,
          buffShare,
          mood,
          level,
          role,
          lastSyncAt: nowValue,
        },
        { merge: true },
      );

      tx.set(
        membershipRef,
        {
          buffShare,
          lastHeartbeat: nowValue,
        },
        { merge: true },
      );
    });

    try {
      await recomputePartyAggregates(partyId);
    } catch (error) {
      functions.logger.warn('Failed to recompute party aggregates after buff sync', {
        partyId,
        userId,
        error: (error as Error).message,
      });
    }

    return null;
  });

export const recalcPartyWeeklySummary = functions.pubsub
  .schedule('0 6 * * 1')
  .onRun(async () => {
    const firestore = admin.firestore();
    const metadataSnapshots = await firestore
      .collectionGroup('metadata')
      .limit(100)
      .get();

    if (metadataSnapshots.empty) {
      return null;
    }

    await Promise.all(
      metadataSnapshots.docs.map(async (doc) => {
        const parent = doc.ref.parent.parent;
        if (!parent) {
          return;
        }
        const partyId = parent.id;
        try {
          await recomputePartyAggregates(partyId);
          await doc.ref.set(
            { lastWeeklyAggregation: admin.firestore.FieldValue.serverTimestamp() },
            { merge: true },
          );
        } catch (error) {
          functions.logger.warn('Weekly party aggregation failed', {
            partyId,
            error: (error as Error).message,
          });
        }
      }),
    );

    return null;
  });

export const __testHelpers = {
  normalizeOwned,
  sanitizeLifeBuddyState,
  sanitizeBuffSnapshot,
  aggregateBuffMaps,
  pickAverageMood,
  decorCatalog,
  allowedSlots,
};
