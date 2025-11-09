import { UserStats, DailyStats, Session, RoutineType } from "../types/session";
import { ALL_ACHIEVEMENTS } from "../data/achievements";

export function getTodayString(): string {
  const today = new Date();
  return today.toISOString().split("T")[0];
}

export function getDateString(date: Date): string {
  return date.toISOString().split("T")[0];
}

export function initializeUserStats(): UserStats {
  return {
    currentStreak: 0,
    longestStreak: 0,
    totalSessions: 0,
    totalMinutes: 0,
    dailyStats: {},
    level: 1,
    xp: 0,
    achievements: [...ALL_ACHIEVEMENTS],
    streakFreezes: 2, // Start with 2 streak freezes
  };
}

export function calculateXP(duration: number, type: RoutineType): number {
  // Base XP: 10 XP per minute
  let xp = duration * 10;
  
  // Bonus XP for longer sessions
  if (duration >= 25) xp += 100; // Bonus for 25+ min
  if (duration >= 60) xp += 300; // Bonus for 1+ hour
  
  return xp;
}

export function calculateLevel(totalXP: number): number {
  // Level formula: Level = floor(sqrt(XP / 100))
  // Level 1 = 0 XP
  // Level 2 = 100 XP
  // Level 3 = 400 XP
  // Level 4 = 900 XP
  // Level 5 = 1600 XP
  // etc.
  return Math.floor(Math.sqrt(totalXP / 100)) + 1;
}

export function getXPForNextLevel(currentLevel: number): number {
  // XP needed for next level
  return currentLevel * currentLevel * 100;
}

export function getXPProgress(currentXP: number, currentLevel: number): {
  current: number;
  needed: number;
  percentage: number;
} {
  const currentLevelXP = (currentLevel - 1) * (currentLevel - 1) * 100;
  const nextLevelXP = currentLevel * currentLevel * 100;
  const neededXP = nextLevelXP - currentLevelXP;
  const currentProgress = currentXP - currentLevelXP;
  
  return {
    current: currentProgress,
    needed: neededXP,
    percentage: (currentProgress / neededXP) * 100,
  };
}

export function checkAchievements(stats: UserStats): {
  newlyUnlocked: string[];
  updatedAchievements: typeof stats.achievements;
} {
  const newlyUnlocked: string[] = [];
  const updatedAchievements = stats.achievements.map(achievement => {
    if (achievement.unlocked) return achievement;
    
    let shouldUnlock = false;
    
    switch (achievement.category) {
      case "streak":
        shouldUnlock = stats.currentStreak >= achievement.requirement;
        break;
      case "sessions":
        shouldUnlock = stats.totalSessions >= achievement.requirement;
        break;
      case "time":
        shouldUnlock = stats.totalMinutes >= achievement.requirement;
        break;
      case "milestone":
        if (achievement.id === "first_session") {
          shouldUnlock = stats.totalSessions >= 1;
        } else if (achievement.id.startsWith("level_")) {
          shouldUnlock = stats.level >= achievement.requirement;
        }
        break;
    }
    
    if (shouldUnlock) {
      newlyUnlocked.push(achievement.id);
      return {
        ...achievement,
        unlocked: true,
        unlockedAt: new Date(),
      };
    }
    
    return achievement;
  });
  
  return { newlyUnlocked, updatedAchievements };
}

export function addSession(
  stats: UserStats,
  session: Session
): UserStats {
  const dateKey = getDateString(session.completedAt);
  const dailyStats = stats.dailyStats[dateKey] || {
    date: dateKey,
    focusMinutes: 0,
    workoutMinutes: 0,
    sleepMinutes: 0,
    sessions: [],
    xpEarned: 0,
    goalsCompleted: 0,
  };

  // Calculate XP for this session
  const xpEarned = calculateXP(session.duration, session.type);
  const sessionWithXP = { ...session, xpEarned };

  // Update daily stats
  if (session.type === "focus") {
    dailyStats.focusMinutes += session.duration;
  } else if (session.type === "workout") {
    dailyStats.workoutMinutes += session.duration;
  } else if (session.type === "sleep") {
    dailyStats.sleepMinutes += session.duration;
  }

  dailyStats.sessions.push(sessionWithXP);
  dailyStats.xpEarned += xpEarned;

  const newTotalXP = stats.xp + xpEarned;
  const newLevel = calculateLevel(newTotalXP);

  const newStats: UserStats = {
    ...stats,
    totalSessions: stats.totalSessions + 1,
    totalMinutes: stats.totalMinutes + session.duration,
    xp: newTotalXP,
    level: newLevel,
    dailyStats: {
      ...stats.dailyStats,
      [dateKey]: dailyStats,
    },
  };

  // Update streak
  newStats.currentStreak = calculateCurrentStreak(newStats);
  newStats.longestStreak = Math.max(
    newStats.longestStreak,
    newStats.currentStreak
  );

  // Check for achievement unlocks
  const { newlyUnlocked, updatedAchievements } = checkAchievements(newStats);
  newStats.achievements = updatedAchievements;

  return newStats;
}

function calculateCurrentStreak(stats: UserStats): number {
  const dates = Object.keys(stats.dailyStats).sort().reverse();
  if (dates.length === 0) return 0;

  let streak = 0;
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  for (let i = 0; i < dates.length; i++) {
    const expectedDate = new Date(today);
    expectedDate.setDate(expectedDate.getDate() - i);
    const expectedDateString = getDateString(expectedDate);

    if (dates[i] === expectedDateString) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}

export function getTodayStats(stats: UserStats): DailyStats {
  const today = getTodayString();
  return (
    stats.dailyStats[today] || {
      date: today,
      focusMinutes: 0,
      workoutMinutes: 0,
      sleepMinutes: 0,
      sessions: [],
      xpEarned: 0,
      goalsCompleted: 0,
    }
  );
}

export function getWeekData(stats: UserStats) {
  const weekData = [];
  const today = new Date();
  
  for (let i = 6; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    const dateKey = getDateString(date);
    const dayStats = stats.dailyStats[dateKey];
    
    const dayName = date.toLocaleDateString("en-US", { weekday: "short" });
    
    weekData.push({
      day: dayName,
      focus: dayStats?.focusMinutes || 0,
      workout: dayStats?.workoutMinutes || 0,
      sleep: dayStats?.sleepMinutes || 0,
    });
  }
  
  return weekData;
}

export function getMonthData(stats: UserStats) {
  const monthData = [];
  const today = new Date();
  
  for (let i = 3; i >= 0; i--) {
    const startDate = new Date(today);
    startDate.setDate(startDate.getDate() - (i + 1) * 7);
    const endDate = new Date(today);
    endDate.setDate(endDate.getDate() - i * 7);
    
    let total = 0;
    
    for (let d = new Date(startDate); d <= endDate; d.setDate(d.getDate() + 1)) {
      const dateKey = getDateString(d);
      const dayStats = stats.dailyStats[dateKey];
      if (dayStats) {
        total += dayStats.focusMinutes + dayStats.workoutMinutes + dayStats.sleepMinutes;
      }
    }
    
    monthData.push({
      week: `W${4 - i}`,
      total,
    });
  }
  
  return monthData;
}

export function getRecentSessions(stats: UserStats, limit: number = 10): Session[] {
  const allSessions: Session[] = [];
  
  Object.values(stats.dailyStats).forEach((daily) => {
    allSessions.push(...daily.sessions);
  });
  
  return allSessions
    .sort((a, b) => new Date(b.completedAt).getTime() - new Date(a.completedAt).getTime())
    .slice(0, limit);
}

export function getDailyGoals(stats: UserStats): any[] {
  const today = getTodayStats(stats);
  
  return [
    {
      id: "focus_goal",
      type: "focus" as RoutineType,
      target: 25,
      current: today.focusMinutes,
      xpReward: 100,
      completed: today.focusMinutes >= 25,
      icon: "🎯",
      name: "Deep Focus",
      description: "Complete 25 min of focus time",
    },
    {
      id: "workout_goal",
      type: "workout" as RoutineType,
      target: 15,
      current: today.workoutMinutes,
      xpReward: 75,
      completed: today.workoutMinutes >= 15,
      icon: "💪",
      name: "Stay Active",
      description: "Complete 15 min of workout",
    },
    {
      id: "sleep_goal",
      type: "sleep" as RoutineType,
      target: 420, // 7 hours
      current: today.sleepMinutes,
      xpReward: 150,
      completed: today.sleepMinutes >= 420,
      icon: "😴",
      name: "Rest Well",
      description: "Get 7 hours of sleep",
    },
  ];
}