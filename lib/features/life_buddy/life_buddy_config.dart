import 'package:life_app/features/life_buddy/life_buddy_models.dart';

/// Sample decor catalog used for the Life Buddy MVP.
// TODO(life-buddy-data): Replace static catalog with repository-backed items.
// 현재는 장식 데이터가 코드에 고정되어 있어 DB/원격 설정의 최신 내용과 동기화되지 않습니다.
// TODO(l10n): Move decor item copy into localized resources before launch.
// 아이템 이름과 설명이 영문으로 하드코딩되어 다국어 번역을 적용할 수 없습니다.
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
