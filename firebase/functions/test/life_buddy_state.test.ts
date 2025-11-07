import * as admin from 'firebase-admin';
import * as functionsTest from 'firebase-functions-test';
import {
  applyLifeBuddyStateWrite,
  claimDailyQuest,
  unlockDecorItem,
  recordLifeBuddySanitizedEvent,
  __testHelpers,
} from '../src/index';

const fft = functionsTest({ projectId: 'demo-test', databaseURL: 'https://demo-test.firebaseio.com' });

jest.mock('firebase-admin', () => {
  const setMock = jest.fn();
  const runTransactionMock = jest.fn(async (fn: (tx: any) => Promise<any>) => {
    const tx = {
      get: jest.fn((ref: any) => ref.get()),
      set: setMock,
    };
    return fn(tx);
  });

  const docImplementations: Record<string, any> = {
    inventory: {
      get: jest.fn().mockResolvedValue({
        data: () => ({
          softCurrency: 120,
          claimedQuests: ['existing_quest'],
          owned: ['bed_basic'],
          isPremiumUser: false,
        }),
      }),
    },
    state: {
      get: jest.fn().mockResolvedValue({
        data: () => ({
          level: 6,
          experience: 150,
        }),
      }),
    },
  };

  const docMock = jest.fn((path?: string) => {
    if (path?.includes('decor_inventory')) {
      return docImplementations.inventory;
    }
    if (path?.includes('life_buddy_state')) {
      return docImplementations.state;
    }
    return {
      get: jest.fn().mockResolvedValue({ data: () => ({}) }),
    };
  });

  const firestoreInstance: any = {
    doc: docMock,
    runTransaction: runTransactionMock,
  };

  const firestoreFn: any = jest.fn(() => firestoreInstance);
  firestoreFn.FieldValue = { serverTimestamp: jest.fn(() => 'timestamp') };

  return {
    apps: [],
    initializeApp: jest.fn(),
    firestore: firestoreFn,
    credential: { applicationDefault: jest.fn() },
    FieldValue: { serverTimestamp: jest.fn(() => 'timestamp') },
    __mock: {
      setMock,
      runTransactionMock,
      docMock,
      implementations: docImplementations,
      resetDoc: () => {
        docMock.mockClear();
        docImplementations.inventory.get.mockClear();
        docImplementations.state.get.mockClear();
      },
    },
  };
});

describe('sanitizeLifeBuddyState', () => {
  it('sanitizes invalid payloads and enforces premium gates', () => {
    const owned = __testHelpers.normalizeOwned(['desk_focus']);
    const result = __testHelpers.sanitizeLifeBuddyState(
      {
        level: 10,
        experience: 55.6,
        mood: 'radiant',
        equippedSlots: {
          desk: 'desk_focus',
          lighting: 'lamp_sunrise', // premium only
          wall: 'unknown_item',
        },
      },
      { ownedItems: owned, isPremiumUser: false },
    );

    expect(result.changed).toBe(true);
    expect(result.data.level).toBe(10);
    expect(result.data.experience).toBeGreaterThan(55);
    expect(result.data.mood).toBe('radiant');
    expect(result.data.equippedSlots).toEqual({ desk: 'desk_focus' });
  });

  it('defaults to safe values when payload missing', () => {
    const owned = __testHelpers.normalizeOwned(undefined);
    const result = __testHelpers.sanitizeLifeBuddyState(
      {},
      { ownedItems: owned, isPremiumUser: false },
    );
    expect(result.data.level).toBe(1);
    expect(result.data.experience).toBe(0);
    expect(result.data.mood).toBe('steady');
    expect(result.data.equippedSlots).toEqual({});
  });
});

describe('party helper utilities', () => {
  it('sanitizes buff snapshots', () => {
    const snapshot = __testHelpers.sanitizeBuffSnapshot({
      focusXpMultiplier: 0.25678,
      sleepQualityBonus: 1.7,
      invalid: 'oops',
      negative: -0.4,
    });
    expect(snapshot.focusXpMultiplier).toBeCloseTo(0.2568);
    expect(snapshot.sleepQualityBonus).toBe(1);
    expect(snapshot.negative).toBe(0);
  });

  it('aggregates buff maps with averages', () => {
    const aggregated = __testHelpers.aggregateBuffMaps([
      { focusXpMultiplier: 0.2, restRecoveryMultiplier: 0.1 },
      { focusXpMultiplier: 0.6, sleepQualityBonus: 0.4 },
      { sleepQualityBonus: 0.2 },
    ]);
    expect(aggregated.focusXpMultiplier).toBeCloseTo(0.4);
    expect(aggregated.restRecoveryMultiplier).toBeCloseTo(0.1);
    expect(aggregated.sleepQualityBonus).toBeCloseTo(0.3);
  });

  it('picks the dominant mood with priority tie-breaker', () => {
    const pick = __testHelpers.pickAverageMood;
    expect(pick(['low', 'thriving', 'low'])).toBe('low');
    expect(pick(['low', 'thriving', 'thriving'])).toBe('thriving');
    expect(pick(['low', 'thriving'])).toBe('thriving');
    expect(pick(['unknown', ''])).toBe('steady');
  });
});

describe('claimDailyQuest', () => {
  const wrapped = fft.wrap(claimDailyQuest);

  afterEach(() => {
    jest.clearAllMocks();
    const adminAny = admin as any;
    adminAny.__mock.resetDoc();
  });

  it('awards coins and records quest', async () => {
    const result = await wrapped({ questId: 'daily_focus' }, { auth: { uid: 'user-123' } } as any);
    expect(result.ok).toBe(true);
    expect(result.reward.coins).toBeGreaterThan(0);
    expect(result.questId).toBe('daily_focus');
  });
});

describe('unlockDecorItem', () => {
  const wrapped = fft.wrap(unlockDecorItem);

  beforeEach(() => {
    const adminAny = admin as any;
    adminAny.__mock.resetDoc();
    adminAny.__mock.implementations.inventory.get.mockImplementation(async () => ({
      data: () => ({
        softCurrency: 200,
        owned: ['bed_basic'],
        isPremiumUser: true,
      }),
    }));
    adminAny.__mock.implementations.state.get.mockImplementation(async () => ({
      data: () => ({
        level: 10,
      }),
    }));
  });

  afterEach(() => {
    const adminAny = admin as any;
    adminAny.__mock.resetDoc();
  });

  it('deducts coins and adds decor to owned list', async () => {
    const adminAny = admin as any;
    const setMock = adminAny.__mock.setMock;
    setMock.mockClear();

    const result = await wrapped(
      { decorId: 'desk_focus' },
      { auth: { uid: 'user-999' } } as any,
    );

    expect(result.ok).toBe(true);
    expect(result.decorId).toBe('desk_focus');
    expect(setMock).toHaveBeenCalled();
    const payload = setMock.mock.calls[0][1];
    expect(payload.owned).toContain('desk_focus');
    expect(payload.softCurrency).toBeLessThan(200);
  });

  it('rejects when coins are insufficient', async () => {
    const adminAny = admin as any;
    adminAny.__mock.implementations.inventory.get.mockImplementation(async () => ({
      data: () => ({
        softCurrency: 10,
        owned: ['bed_basic'],
        isPremiumUser: false,
      }),
    }));

    await expect(
      wrapped({ decorId: 'desk_focus' }, { auth: { uid: 'user-321' } } as any),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('rejects premium decor for non-premium user', async () => {
    const adminAny = admin as any;
    adminAny.__mock.implementations.inventory.get.mockImplementation(async () => ({
      data: () => ({
        softCurrency: 500,
        owned: ['bed_basic'],
        isPremiumUser: false,
      }),
    }));

    await expect(
      wrapped({ decorId: 'lamp_sunrise' }, { auth: { uid: 'user-444' } } as any),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });
});

describe('applyLifeBuddyStateWrite', () => {
  it('sanitizes invalid payloads and persists updates', async () => {
    const setMock = jest.fn().mockResolvedValue(undefined);
    const result = await applyLifeBuddyStateWrite({
      beforeData: {
        level: 5,
        experience: 20,
        mood: 'radiant',
        equippedSlots: { desk: 'desk_focus' },
      },
      afterData: {
        level: -3,
        experience: -40,
        mood: 'unknown',
        equippedSlots: {
          desk: 'desk_focus',
          lighting: 'lamp_sunrise',
        },
      },
      inventory: {
        owned: ['desk_focus', 'lamp_sunrise'],
        isPremiumUser: false,
      },
      stateRef: { set: setMock } as any,
      serverTimestamp: () => 'ts' as any,
    });

    expect(setMock).toHaveBeenCalledTimes(1);
    expect(setMock.mock.calls[0][0]).toEqual({
      level: 1,
      experience: 0,
      mood: 'steady',
      equippedSlots: {},
      updatedAt: 'ts',
    });
    expect(setMock.mock.calls[0][1]).toEqual({ merge: true });
    expect(result.changed).toBe(true);
    expect(result.sanitized).toEqual({
      level: 1,
      experience: 0,
      mood: 'steady',
      equippedSlots: {},
    });
  });

  it('short-circuits when no sanitization needed', async () => {
    const setMock = jest.fn();
    const result = await applyLifeBuddyStateWrite({
      beforeData: {
        level: 6,
        experience: 90,
        mood: 'radiant',
        equippedSlots: { desk: 'desk_focus' },
      },
      afterData: {
        level: 6,
        experience: 90,
        mood: 'radiant',
        equippedSlots: { desk: 'desk_focus' },
      },
      inventory: { owned: ['desk_focus'], isPremiumUser: true },
      stateRef: { set: setMock } as any,
      serverTimestamp: () => 'ts' as any,
    });

    expect(result.changed).toBe(false);
    expect(setMock).not.toHaveBeenCalled();
  });
});

describe('recordLifeBuddySanitizedEvent', () => {
  it('writes sanitized event payload with before snapshot', async () => {
    const addMock = jest.fn().mockResolvedValue(undefined);

    await recordLifeBuddySanitizedEvent({
      eventsCollection: { add: addMock } as any,
      beforeData: {
        level: 5,
        experience: 30,
        mood: 'radiant',
        equippedSlots: { desk: 'desk_focus' },
      },
      sanitizedData: {
        level: 2,
        experience: 45,
        mood: 'steady',
        equippedSlots: { desk: 'desk_focus' },
      },
      serverTimestamp: () => 'ts' as any,
    });

    expect(addMock).toHaveBeenCalledWith({
      type: 'state_sanitized',
      timestamp: 'ts',
      before: {
        level: 5,
        experience: 30,
        mood: 'radiant',
        equippedSlots: { desk: 'desk_focus' },
      },
      after: {
        level: 2,
        experience: 45,
        mood: 'steady',
        equippedSlots: { desk: 'desk_focus' },
      },
    });
  });
});
