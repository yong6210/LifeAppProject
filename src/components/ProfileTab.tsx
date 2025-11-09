import { useState } from "react";
import { Button } from "./ui/button";
import { 
  User, 
  Crown, 
  Flame, 
  Trophy, 
  Target, 
  Clock, 
  Star,
  ChevronRight,
  Bell,
  Palette,
  Shield,
  HelpCircle,
  LogOut,
  Sparkles,
  Award,
  Zap
} from "lucide-react";
import { useLocalStorage } from "../hooks/useLocalStorage";
import { UserStats } from "../types/session";
import { initializeUserStats, getXPProgress } from "../utils/stats";
import { Progress } from "./ui/progress";
import { motion } from "motion/react";

export function ProfileTab() {
  const [userStats] = useLocalStorage<UserStats>(
    "life-app-stats",
    initializeUserStats()
  );
  const [showAllAchievements, setShowAllAchievements] = useState(false);

  const xpProgress = getXPProgress(userStats.xp, userStats.level);
  const unlockedAchievements = userStats.achievements.filter(a => a.unlocked);
  const totalHours = Math.floor(userStats.totalMinutes / 60);

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="px-6 py-5 border-b border-white/10">
        <h2 className="text-white text-xl">Profile</h2>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="px-6 pb-24">
          {/* Profile Card */}
          <div className="mt-6 mb-8">
            <div className="glass-panel-solid rounded-3xl p-6 bg-gradient-to-br from-[#5C4DFF]/20 via-transparent to-[#1EB980]/20 border-[#5C4DFF]/30 relative overflow-hidden">
              <div className="absolute top-0 right-0 w-32 h-32 bg-[#5C4DFF]/10 rounded-full blur-3xl" />
              <div className="absolute bottom-0 left-0 w-32 h-32 bg-[#1EB980]/10 rounded-full blur-3xl" />
              
              <div className="relative">
                {/* Avatar & Level */}
                <div className="flex items-center gap-4 mb-6">
                  <div className="w-20 h-20 rounded-full bg-gradient-to-br from-[#5C4DFF] to-[#1EB980] flex items-center justify-center shadow-lg shadow-[#5C4DFF]/30 relative">
                    <User size={32} className="text-white" />
                    <div className="absolute -bottom-1 -right-1 w-8 h-8 bg-gradient-to-br from-[#FBBF24] to-[#F59E0B] rounded-full flex items-center justify-center border-2 border-[#111729]">
                      <span className="text-xs text-black">{userStats.level}</span>
                    </div>
                  </div>
                  <div className="flex-1">
                    <h3 className="text-white text-xl mb-1">Life User</h3>
                    <div className="flex items-center gap-2 text-white/60 text-sm">
                      <Crown size={14} className="text-[#FBBF24]" />
                      <span>Level {userStats.level}</span>
                    </div>
                  </div>
                </div>

                {/* XP Progress */}
                <div className="mb-4">
                  <div className="flex justify-between text-sm mb-2">
                    <span className="text-white/70">Level {userStats.level}</span>
                    <span className="text-white flex items-center gap-1">
                      <Sparkles size={14} className="text-[#FBBF24]" />
                      {userStats.xp.toLocaleString()} XP
                    </span>
                  </div>
                  <Progress value={xpProgress.percentage} className="h-2.5 bg-white/10" />
                  <div className="text-white/50 text-xs mt-1.5">
                    {xpProgress.current.toLocaleString()} / {xpProgress.needed.toLocaleString()} XP to Level {userStats.level + 1}
                  </div>
                </div>

                {/* Quick Stats */}
                <div className="grid grid-cols-3 gap-3">
                  <div className="glass-panel rounded-xl p-3 text-center">
                    <div className="flex justify-center mb-1.5">
                      <div className="w-8 h-8 rounded-lg bg-[#5B8CFF]/20 flex items-center justify-center">
                        <Flame size={16} className="text-[#5B8CFF]" />
                      </div>
                    </div>
                    <div className="text-white text-lg mb-0.5">{userStats.currentStreak}</div>
                    <div className="text-white/50 text-xs">Day Streak</div>
                  </div>
                  <div className="glass-panel rounded-xl p-3 text-center">
                    <div className="flex justify-center mb-1.5">
                      <div className="w-8 h-8 rounded-lg bg-[#34D399]/20 flex items-center justify-center">
                        <Target size={16} className="text-[#34D399]" />
                      </div>
                    </div>
                    <div className="text-white text-lg mb-0.5">{userStats.totalSessions}</div>
                    <div className="text-white/50 text-xs">Sessions</div>
                  </div>
                  <div className="glass-panel rounded-xl p-3 text-center">
                    <div className="flex justify-center mb-1.5">
                      <div className="w-8 h-8 rounded-lg bg-[#38BDF8]/20 flex items-center justify-center">
                        <Clock size={16} className="text-[#38BDF8]" />
                      </div>
                    </div>
                    <div className="text-white text-lg mb-0.5">{totalHours}h</div>
                    <div className="text-white/50 text-xs">Total Time</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Achievements */}
          <div className="mb-8">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-white flex items-center gap-2">
                <Trophy size={18} />
                Achievements
              </h3>
              <span className="text-white/60 text-sm">
                {unlockedAchievements.length} / {userStats.achievements.length}
              </span>
            </div>

            <div className="grid grid-cols-4 gap-3 mb-4">
              {(showAllAchievements ? userStats.achievements : userStats.achievements.slice(0, 8)).map((achievement) => (
                <motion.div
                  key={achievement.id}
                  whileHover={{ scale: achievement.unlocked ? 1.05 : 1 }}
                  className={`glass-panel rounded-2xl p-4 flex flex-col items-center justify-center aspect-square transition-all ${
                    achievement.unlocked ? "bg-gradient-to-br from-white/10 to-white/5 border-white/20" : "opacity-40"
                  }`}
                >
                  <div className="text-3xl mb-2">{achievement.icon}</div>
                  {achievement.unlocked && (
                    <div className="w-5 h-5 rounded-full bg-emerald-500 flex items-center justify-center">
                      <span className="text-xs">✓</span>
                    </div>
                  )}
                </motion.div>
              ))}
            </div>

            {!showAllAchievements && userStats.achievements.length > 8 && (
              <Button
                variant="ghost"
                onClick={() => setShowAllAchievements(true)}
                className="w-full text-white/60 hover:text-white hover:bg-white/5 rounded-xl"
              >
                View All Achievements
                <ChevronRight size={16} className="ml-2" />
              </Button>
            )}

            {showAllAchievements && (
              <Button
                variant="ghost"
                onClick={() => setShowAllAchievements(false)}
                className="w-full text-white/60 hover:text-white hover:bg-white/5 rounded-xl"
              >
                Show Less
              </Button>
            )}
          </div>

          {/* Recent Achievements */}
          {unlockedAchievements.length > 0 && (
            <div className="mb-8">
              <h3 className="text-white mb-4 flex items-center gap-2">
                <Award size={18} />
                Recent Unlocks
              </h3>
              <div className="space-y-3">
                {unlockedAchievements.slice(0, 3).map((achievement) => (
                  <div key={achievement.id} className="glass-panel rounded-2xl p-4">
                    <div className="flex items-center gap-3">
                      <div className="text-3xl">{achievement.icon}</div>
                      <div className="flex-1">
                        <div className="text-white text-sm mb-0.5">{achievement.name}</div>
                        <div className="text-white/50 text-xs">{achievement.description}</div>
                      </div>
                      <div className="text-emerald-400">
                        <Star size={18} fill="currentColor" />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Streak Freeze */}
          {userStats.streakFreezes > 0 && (
            <div className="mb-8">
              <div className="glass-panel-solid rounded-2xl p-5 bg-gradient-to-br from-cyan-500/10 to-transparent border-cyan-500/20">
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-12 h-12 rounded-2xl bg-cyan-500/20 flex items-center justify-center">
                    <Shield size={24} className="text-cyan-400" />
                  </div>
                  <div className="flex-1">
                    <div className="text-white mb-1">Streak Freeze</div>
                    <div className="text-white/60 text-sm">Protect your streak if you miss a day</div>
                  </div>
                  <div className="text-right">
                    <div className="text-cyan-400 text-2xl">{userStats.streakFreezes}</div>
                    <div className="text-white/50 text-xs">Available</div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Settings Section */}
          <div className="mb-8">
            <h3 className="text-white mb-4">Settings</h3>
            <div className="space-y-2">
              <Button
                variant="ghost"
                className="w-full justify-between text-white hover:bg-white/5 rounded-xl h-14 px-4"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center">
                    <Bell size={18} className="text-white/60" />
                  </div>
                  <span>Notifications</span>
                </div>
                <ChevronRight size={18} className="text-white/40" />
              </Button>

              <Button
                variant="ghost"
                className="w-full justify-between text-white hover:bg-white/5 rounded-xl h-14 px-4"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center">
                    <Palette size={18} className="text-white/60" />
                  </div>
                  <span>Appearance</span>
                </div>
                <ChevronRight size={18} className="text-white/40" />
              </Button>

              <Button
                variant="ghost"
                className="w-full justify-between text-white hover:bg-white/5 rounded-xl h-14 px-4"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center">
                    <Zap size={18} className="text-white/60" />
                  </div>
                  <div className="text-left">
                    <div>Premium</div>
                    <div className="text-xs text-white/50">Unlock all features</div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-[#FBBF24] bg-[#FBBF24]/10 px-2 py-1 rounded-full">
                    7 days free
                  </span>
                  <ChevronRight size={18} className="text-white/40" />
                </div>
              </Button>

              <Button
                variant="ghost"
                className="w-full justify-between text-white hover:bg-white/5 rounded-xl h-14 px-4"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center">
                    <HelpCircle size={18} className="text-white/60" />
                  </div>
                  <span>Help & Support</span>
                </div>
                <ChevronRight size={18} className="text-white/40" />
              </Button>
            </div>
          </div>

          {/* About Section */}
          <div className="mb-8">
            <h3 className="text-white mb-4">About</h3>
            <div className="glass-panel rounded-2xl p-5">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#5C4DFF] to-[#1EB980] flex items-center justify-center">
                  <Sparkles size={24} className="text-white" />
                </div>
                <div>
                  <div className="text-white">Life App</div>
                  <div className="text-white/50 text-sm">Version 1.0.0</div>
                </div>
              </div>
              <div className="text-white/60 text-sm leading-relaxed">
                Build better habits with focus, workout, and sleep routines. Track your progress and level up your lifestyle.
              </div>
            </div>
          </div>

          {/* Logout */}
          <Button
            variant="ghost"
            className="w-full text-red-400 hover:bg-red-500/10 hover:text-red-400 rounded-xl h-12"
          >
            <LogOut size={18} className="mr-2" />
            Sign Out
          </Button>
        </div>
      </div>
    </div>
  );
}
