import 'package:life_app/features/life_buddy/life_buddy_models.dart';

// TODO: Load the decor catalog from a repository and localize all user-facing
// copy instead of relying on this inline sample data.
// The MVP keeps English names, descriptions, and pricing constants in code, so
// it ignores localization settings and never reflects updated values from the
// database or remote config.
/// Sample decor catalog used for the Life Buddy MVP.
const List<DecorItem> kDecorCatalog = [
  DecorItem(
    id: 'bed_basic',
    slot: DecorSlot.bed,
    name: 'Calming Cotton Sheets',
    description: 'Simple sheets that make winding down easier.',
    costCoins: 0,
    unlockLevel: 1,
    buffs: [DecorBuff(type: LifeBuffType.sleepQualityBonus, value: 0.02)],
  ),
  DecorItem(
    id: 'desk_focus',
    slot: DecorSlot.desk,
    name: 'Focus Desk',
    description: 'Decluttered workspace that keeps you on task.',
    costCoins: 120,
    unlockLevel: 2,
    buffs: [DecorBuff(type: LifeBuffType.focusXpMultiplier, value: 0.05)],
  ),
  DecorItem(
    id: 'lamp_mellow',
    slot: DecorSlot.lighting,
    name: 'Mellow Lamp',
    description: 'Warm lighting that helps you relax before sleep.',
    costCoins: 90,
    unlockLevel: 2,
    buffs: [DecorBuff(type: LifeBuffType.sleepQualityBonus, value: 0.03)],
  ),
  DecorItem(
    id: 'poster_motivation',
    slot: DecorSlot.wall,
    name: 'Motivation Poster',
    description: 'A daily reminder to keep your streak alive.',
    costCoins: 60,
    unlockLevel: 3,
    buffs: [DecorBuff(type: LifeBuffType.focusXpMultiplier, value: 0.03)],
  ),
  DecorItem(
    id: 'rug_grounded',
    slot: DecorSlot.floor,
    name: 'Grounding Rug',
    description: 'Soft rug that encourages mindful breaks.',
    costCoins: 140,
    unlockLevel: 4,
    buffs: [DecorBuff(type: LifeBuffType.restRecoveryMultiplier, value: 0.04)],
  ),
  DecorItem(
    id: 'plant_companion',
    slot: DecorSlot.accent,
    name: 'Leafy Companion',
    description: 'A plant friend that keeps your buddy cheerful.',
    costCoins: 150,
    unlockLevel: 5,
    requiresPremium: false,
    buffs: [
      DecorBuff(type: LifeBuffType.restRecoveryMultiplier, value: 0.03),
      DecorBuff(type: LifeBuffType.sleepQualityBonus, value: 0.02),
    ],
  ),
  DecorItem(
    id: 'lamp_sunrise',
    slot: DecorSlot.lighting,
    name: 'Sunrise Simulator',
    description: 'Premium light that boosts wake-up freshness.',
    costCoins: 0,
    unlockLevel: 6,
    requiresPremium: true,
    buffs: [DecorBuff(type: LifeBuffType.sleepQualityBonus, value: 0.06)],
  ),
];
