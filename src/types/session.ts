export type RoutineType = "focus" | "workout" | "sleep";

export interface Session {
  id: string;
  type: RoutineType;
  presetName: string;
  duration: number; // in minutes
  completedAt: Date;
  notes?: string;
  xpEarned: number;
}

export interface DailyStats {
  date: string; // YYYY-MM-DD
  focusMinutes: number;
  workoutMinutes: number;
  sleepMinutes: number;
  sessions: Session[];
  xpEarned: number;
  goalsCompleted: number;
}

export interface Achievement {
  id: string;
  name: string;
  description: string;
  icon: string;
  category: "streak" | "sessions" | "time" | "milestone";
  requirement: number;
  unlocked: boolean;
  unlockedAt?: Date;
}

export interface DailyGoal {
  id: string;
  type: RoutineType;
  target: number; // in minutes
  current: number;
  xpReward: number;
  completed: boolean;
}

export interface UserStats {
  currentStreak: number;
  longestStreak: number;
  totalSessions: number;
  totalMinutes: number;
  dailyStats: { [date: string]: DailyStats };
  level: number;
  xp: number;
  achievements: Achievement[];
  streakFreezes: number;
  lastStreakFreezeUsed?: string;
}