"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.__testHelpers = exports.unlockDecorItem = exports.claimDailyQuest = exports.onLifeBuddyStateWrite = void 0;
exports.applyLifeBuddyStateWrite = applyLifeBuddyStateWrite;
exports.recordLifeBuddySanitizedEvent = recordLifeBuddySanitizedEvent;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
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
const allowedSlots = ['bed', 'desk', 'lighting', 'wall', 'floor', 'accent'];
const decorCatalog = {
    bed_basic: { slot: 'bed', requiresPremium: false, unlockLevel: 1, costCoins: 0 },
    desk_focus: { slot: 'desk', requiresPremium: false, unlockLevel: 2, costCoins: 120 },
    lamp_mellow: { slot: 'lighting', requiresPremium: false, unlockLevel: 2, costCoins: 90 },
    poster_motivation: { slot: 'wall', requiresPremium: false, unlockLevel: 3, costCoins: 60 },
    rug_grounded: { slot: 'floor', requiresPremium: false, unlockLevel: 4, costCoins: 140 },
    plant_companion: { slot: 'accent', requiresPremium: false, unlockLevel: 5, costCoins: 150 },
    lamp_sunrise: { slot: 'lighting', requiresPremium: true, unlockLevel: 6, costCoins: 0 },
};
const defaultOwnedItems = new Set(['bed_basic']);
function normalizeOwned(raw) {
    const owned = new Set(defaultOwnedItems);
    if (Array.isArray(raw)) {
        for (const value of raw) {
            if (typeof value === 'string') {
                owned.add(value);
            }
        }
    }
    return owned;
}
function sanitizeLifeBuddyState(raw, options) {
    const sanitizedLevel = Number.isFinite(raw.level)
        ? Math.max(1, Math.floor(raw.level))
        : 1;
    const sanitizedExperience = Number.isFinite(raw.experience)
        ? Math.max(0, Number(raw.experience))
        : 0;
    const mood = typeof raw.mood === 'string' && allowedMoods.has(raw.mood)
        ? raw.mood
        : 'steady';
    const existingSlots = {};
    if (raw.equippedSlots && typeof raw.equippedSlots === 'object') {
        Object.entries(raw.equippedSlots).forEach(([key, value]) => {
            if (typeof value === 'string') {
                existingSlots[key] = value;
            }
        });
    }
    const sanitizedSlots = {};
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
    const changed = sanitizedLevel !== raw.level ||
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
function areSlotMapsEqual(a, b) {
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
async function applyLifeBuddyStateWrite({ beforeData, afterData, inventory, stateRef, serverTimestamp, }) {
    const ownedItems = normalizeOwned(inventory.owned);
    const isPremiumUser = Boolean(inventory.isPremiumUser);
    const sanitized = sanitizeLifeBuddyState(afterData, { ownedItems, isPremiumUser });
    if (!sanitized.changed) {
        return { changed: false, sanitized: sanitized.data };
    }
    await stateRef.set({
        ...sanitized.data,
        updatedAt: serverTimestamp(),
    }, { merge: true });
    return { changed: true, sanitized: sanitized.data };
}
async function recordLifeBuddySanitizedEvent({ eventsCollection, beforeData, sanitizedData, serverTimestamp, }) {
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
exports.onLifeBuddyStateWrite = functions.firestore
    .document('users/{userId}/life_buddy_state/state')
    .onWrite(async (change, context) => {
    if (!change.after.exists) {
        return null;
    }
    const userId = context.params.userId;
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
        }
        catch (eventError) {
            functions.logger.warn('Failed to record life_buddy_state event', {
                userId,
                error: eventError.message,
            });
        }
    }
    return null;
});
exports.claimDailyQuest = functions.https.onCall(async (data, context) => {
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
        const claimed = Array.isArray(doc.claimedQuests) ? doc.claimedQuests : [];
        if (claimed.includes(questId)) {
            throw new functions.https.HttpsError('failed-precondition', 'Quest already claimed');
        }
        const newClaimed = [...claimed, questId];
        const currentCoins = Number.isFinite(doc.softCurrency) ? Number(doc.softCurrency) : 0;
        tx.set(inventoryRef, {
            softCurrency: currentCoins + rewardCoins,
            claimedQuests: newClaimed,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    });
    return {
        ok: true,
        reward: { coins: rewardCoins },
        questId,
    };
});
exports.unlockDecorItem = functions.https.onCall(async (data, context) => {
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
        const owned = normalizeOwned(inventoryDoc.owned);
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
        tx.set(inventoryRef, {
            owned: ownedArray,
            softCurrency: remainingCoins,
            updatedAt: serverTimestamp(),
            lastUnlock: {
                decorId,
                costCoins: decor.costCoins,
                requiresPremium: decor.requiresPremium,
                purchasedAt: serverTimestamp(),
            },
        }, { merge: true });
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
    }
    catch (error) {
        functions.logger.warn('Failed to append decor_unlocked event', {
            userId: uid,
            decorId,
            error: error.message,
        });
    }
    return {
        ok: true,
        decorId,
        remainingCoins: writeResult.softCurrency,
        requiresPremium: decor.requiresPremium,
    };
});
exports.__testHelpers = {
    normalizeOwned,
    sanitizeLifeBuddyState,
    decorCatalog,
    allowedSlots,
};
//# sourceMappingURL=index.js.map