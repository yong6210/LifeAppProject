import { Settings, ChevronRight, TrendingUp, Sparkles, Brain, Dumbbell, Moon, Award, Flame, Heart, Zap, CheckCircle2, ArrowUpRight } from "lucide-react";
import { useLocalStorage } from "../hooks/useLocalStorage";
import { UserStats } from "../types/session";
import { initializeUserStats, getTodayStats } from "../utils/stats";

interface DashboardTabProps {
  onNavigate: (tab: string) => void;
}

export function DashboardTab({ onNavigate }: DashboardTabProps) {
  const [userStats] = useLocalStorage<UserStats>(
    "life-app-stats",
    initializeUserStats()
  );

  const todayStats = getTodayStats(userStats);

  const now = new Date();
  const hour = now.getHours();
  const greeting = hour < 12 ? "Good Morning" : hour < 18 ? "Good Afternoon" : "Good Evening";
  
  // Calculate progress (0-100%)
  const focusProgress = Math.min((todayStats.focusMinutes / 25) * 100, 100);
  const moveProgress = Math.min((todayStats.workoutMinutes / 30) * 100, 100);
  const sleepProgress = Math.min((todayStats.sleepMinutes / 480) * 100, 100);
  
  const completedGoals = [focusProgress >= 100, moveProgress >= 100, sleepProgress >= 100].filter(Boolean).length;
  const totalProgress = Math.round((focusProgress + moveProgress + sleepProgress) / 3);

  return (
    <div 
      className="h-full overflow-y-auto relative"
      style={{
        background: 'linear-gradient(180deg, #0a0e14 0%, #0F1419 40%, #141b2d 100%)'
      }}
    >
      
      {/* Ambient glow */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div 
          className="absolute top-0 left-0 right-0 h-96 opacity-25"
          style={{
            background: 'radial-gradient(ellipse at top, rgba(78, 205, 196, 0.3), transparent 60%)'
          }}
        />
      </div>

      {/* Content */}
      <div className="relative z-10 px-5">
        
        {/* Compact Header */}
        <div className="pt-12 pb-5 flex items-center justify-between">
          <div>
            <h1 className="text-[28px] leading-tight text-white font-bold tracking-tight mb-1">
              {greeting}
            </h1>
            <div className="flex items-center gap-1.5">
              <div 
                className="w-4 h-4 rounded-full flex items-center justify-center"
                style={{
                  background: 'linear-gradient(135deg, #52C9A5 0%, #4ECDC4 100%)',
                  boxShadow: '0 0 10px rgba(82, 201, 165, 0.4)'
                }}
              >
                <Heart size={9} className="text-white" strokeWidth={3} fill="white" />
              </div>
              <span className="text-[12px] text-white/50">Life Buddy</span>
            </div>
          </div>
          <button 
            onClick={() => onNavigate("settings")}
            className="w-10 h-10 rounded-xl bg-white/[0.08] backdrop-blur-xl flex items-center justify-center ios-ease active:scale-90 border border-white/10"
          >
            <Settings size={18} className="text-white/70" strokeWidth={2} />
          </button>
        </div>

        {/* Compact Progress Hero */}
        <div 
          className="rounded-[24px] p-5 mb-5 relative overflow-hidden"
          style={{
            background: 'linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, rgba(255, 255, 255, 0.04) 100%)',
            backdropFilter: 'blur(40px)',
            border: '1px solid rgba(255, 255, 255, 0.15)',
            boxShadow: '0 16px 40px rgba(0, 0, 0, 0.3)'
          }}
        >
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center gap-1.5 mb-2">
                <Zap size={14} className="text-[#52C9A5]" strokeWidth={2.5} fill="#52C9A5" />
                <span className="text-[11px] text-white/50 font-semibold uppercase tracking-wide">Today</span>
              </div>
              <div className="flex items-baseline gap-1.5 mb-2">
                <div 
                  className="text-[48px] leading-none font-bold tabular-nums tracking-tighter"
                  style={{
                    background: 'linear-gradient(135deg, #ffffff 0%, #e0e0e0 100%)',
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent'
                  }}
                >
                  {totalProgress}
                </div>
                <div className="text-[20px] text-white/40 font-bold mb-2">%</div>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 rounded-full" style={{ 
                  background: focusProgress >= 100 ? '#4ECDC4' : 'rgba(78, 205, 196, 0.3)',
                  boxShadow: focusProgress >= 100 ? '0 0 8px rgba(78, 205, 196, 0.6)' : 'none'
                }} />
                <div className="w-2 h-2 rounded-full" style={{ 
                  background: moveProgress >= 100 ? '#FF6B6B' : 'rgba(255, 107, 107, 0.3)',
                  boxShadow: moveProgress >= 100 ? '0 0 8px rgba(255, 107, 107, 0.6)' : 'none'
                }} />
                <div className="w-2 h-2 rounded-full" style={{ 
                  background: sleepProgress >= 100 ? '#B06FF9' : 'rgba(176, 111, 249, 0.3)',
                  boxShadow: sleepProgress >= 100 ? '0 0 8px rgba(176, 111, 249, 0.6)' : 'none'
                }} />
              </div>
            </div>

            {/* Stats Mini Grid */}
            <div className="flex flex-col gap-2">
              <div className="flex items-center gap-2">
                <div className="text-right">
                  <div className="text-[20px] text-white font-bold tabular-nums leading-none">{userStats.currentStreak}</div>
                  <div className="text-[10px] text-white/40 uppercase tracking-wide">streak</div>
                </div>
                <Flame size={20} className="text-[#FF6B6B]" strokeWidth={2} />
              </div>
              <div className="flex items-center gap-2">
                <div className="text-right">
                  <div className="text-[20px] text-white font-bold tabular-nums leading-none">{userStats.level}</div>
                  <div className="text-[10px] text-white/40 uppercase tracking-wide">level</div>
                </div>
                <Award size={20} className="text-[#A8E063]" strokeWidth={2} />
              </div>
            </div>
          </div>
        </div>

        {/* Activities Grid - 2 column top, 1 bottom */}
        <div className="grid grid-cols-2 gap-3 mb-3">
          
          {/* Focus */}
          <button
            onClick={() => onNavigate("timer")}
            className="rounded-[20px] p-4 relative overflow-hidden ios-ease active:scale-[0.96]"
            style={{
              background: 'linear-gradient(135deg, rgba(78, 205, 196, 0.18) 0%, rgba(78, 205, 196, 0.06) 100%)',
              border: '1px solid rgba(78, 205, 196, 0.35)',
              boxShadow: focusProgress >= 100 
                ? '0 8px 32px rgba(78, 205, 196, 0.25)' 
                : '0 8px 24px rgba(0, 0, 0, 0.2)'
            }}
          >
            {focusProgress >= 100 && (
              <div 
                className="absolute inset-0"
                style={{
                  background: 'radial-gradient(circle at 50% 0%, rgba(78, 205, 196, 0.2), transparent 60%)'
                }}
              />
            )}

            <div className="relative z-10">
              <div className="flex items-center justify-between mb-3">
                <div 
                  className="w-12 h-12 rounded-[16px] flex items-center justify-center"
                  style={{
                    background: 'linear-gradient(135deg, #4ECDC4 0%, #6fd9d1 100%)',
                    boxShadow: '0 6px 16px rgba(78, 205, 196, 0.4)'
                  }}
                >
                  {focusProgress >= 100 ? (
                    <CheckCircle2 size={22} className="text-white" strokeWidth={2.5} />
                  ) : (
                    <Brain size={22} className="text-white" strokeWidth={2} />
                  )}
                </div>
                <ArrowUpRight size={16} className="text-white/30" strokeWidth={2.5} />
              </div>
              
              <div className="text-[16px] text-white font-bold mb-1.5">Focus</div>
              <div className="flex items-baseline gap-1">
                <span className="text-[24px] text-white font-bold tabular-nums leading-none">
                  {todayStats.focusMinutes}
                </span>
                <span className="text-[13px] text-white/50">/ 25</span>
              </div>
              
              {/* Progress bar */}
              <div className="h-1.5 bg-white/10 rounded-full overflow-hidden mt-3">
                <div 
                  className="h-full rounded-full transition-all duration-1000"
                  style={{ 
                    width: `${focusProgress}%`,
                    background: 'linear-gradient(90deg, #4ECDC4 0%, #6fd9d1 100%)'
                  }}
                />
              </div>
            </div>
          </button>

          {/* Move */}
          <button
            onClick={() => onNavigate("workout")}
            className="rounded-[20px] p-4 relative overflow-hidden ios-ease active:scale-[0.96]"
            style={{
              background: 'linear-gradient(135deg, rgba(255, 107, 107, 0.18) 0%, rgba(255, 107, 107, 0.06) 100%)',
              border: '1px solid rgba(255, 107, 107, 0.35)',
              boxShadow: moveProgress >= 100 
                ? '0 8px 32px rgba(255, 107, 107, 0.25)' 
                : '0 8px 24px rgba(0, 0, 0, 0.2)'
            }}
          >
            {moveProgress >= 100 && (
              <div 
                className="absolute inset-0"
                style={{
                  background: 'radial-gradient(circle at 50% 0%, rgba(255, 107, 107, 0.2), transparent 60%)'
                }}
              />
            )}

            <div className="relative z-10">
              <div className="flex items-center justify-between mb-3">
                <div 
                  className="w-12 h-12 rounded-[16px] flex items-center justify-center"
                  style={{
                    background: 'linear-gradient(135deg, #FF6B6B 0%, #ff8585 100%)',
                    boxShadow: '0 6px 16px rgba(255, 107, 107, 0.4)'
                  }}
                >
                  {moveProgress >= 100 ? (
                    <CheckCircle2 size={22} className="text-white" strokeWidth={2.5} />
                  ) : (
                    <Dumbbell size={22} className="text-white" strokeWidth={2} />
                  )}
                </div>
                <ArrowUpRight size={16} className="text-white/30" strokeWidth={2.5} />
              </div>
              
              <div className="text-[16px] text-white font-bold mb-1.5">Move</div>
              <div className="flex items-baseline gap-1">
                <span className="text-[24px] text-white font-bold tabular-nums leading-none">
                  {todayStats.workoutMinutes}
                </span>
                <span className="text-[13px] text-white/50">/ 30</span>
              </div>
              
              <div className="h-1.5 bg-white/10 rounded-full overflow-hidden mt-3">
                <div 
                  className="h-full rounded-full transition-all duration-1000"
                  style={{ 
                    width: `${moveProgress}%`,
                    background: 'linear-gradient(90deg, #FF6B6B 0%, #ff8585 100%)'
                  }}
                />
              </div>
            </div>
          </button>
        </div>

        {/* Rest - Full Width */}
        <button
          onClick={() => onNavigate("sleep")}
          className="w-full rounded-[20px] p-4 mb-5 relative overflow-hidden ios-ease active:scale-[0.97]"
          style={{
            background: 'linear-gradient(135deg, rgba(176, 111, 249, 0.18) 0%, rgba(176, 111, 249, 0.06) 100%)',
            border: '1px solid rgba(176, 111, 249, 0.35)',
            boxShadow: sleepProgress >= 100 
              ? '0 8px 32px rgba(176, 111, 249, 0.25)' 
              : '0 8px 24px rgba(0, 0, 0, 0.2)'
          }}
        >
          {sleepProgress >= 100 && (
            <div 
              className="absolute inset-0"
              style={{
                background: 'radial-gradient(circle at 50% 0%, rgba(176, 111, 249, 0.2), transparent 60%)'
              }}
            />
          )}

          <div className="relative z-10 flex items-center gap-4">
            <div 
              className="w-14 h-14 rounded-[18px] flex items-center justify-center flex-shrink-0"
              style={{
                background: 'linear-gradient(135deg, #B06FF9 0%, #c18cfa 100%)',
                boxShadow: '0 6px 16px rgba(176, 111, 249, 0.4)'
              }}
            >
              {sleepProgress >= 100 ? (
                <CheckCircle2 size={24} className="text-white" strokeWidth={2.5} />
              ) : (
                <Moon size={24} className="text-white" strokeWidth={2} />
              )}
            </div>

            <div className="flex-1 text-left">
              <div className="text-[18px] text-white font-bold mb-1">Rest & Recovery</div>
              <div className="flex items-baseline gap-1.5">
                <span className="text-[26px] text-white font-bold tabular-nums leading-none">
                  {Math.floor(todayStats.sleepMinutes / 60)}
                </span>
                <span className="text-[14px] text-white/50">/ 8 hours</span>
              </div>
            </div>

            <div className="flex flex-col items-end gap-2">
              <div className="text-[24px] text-white/60 font-bold tabular-nums">
                {Math.round(sleepProgress)}%
              </div>
              <ArrowUpRight size={18} className="text-white/30" strokeWidth={2.5} />
            </div>
          </div>

          {/* Progress bar */}
          <div className="h-1.5 bg-white/10 rounded-full overflow-hidden mt-3">
            <div 
              className="h-full rounded-full transition-all duration-1000"
              style={{ 
                width: `${sleepProgress}%`,
                background: 'linear-gradient(90deg, #B06FF9 0%, #c18cfa 100%)'
              }}
            />
          </div>
        </button>

        {/* View Stats CTA */}
        <button
          onClick={() => onNavigate("stats")}
          className="w-full rounded-[20px] p-4 ios-ease active:scale-[0.97] flex items-center justify-between mb-5"
          style={{
            background: 'linear-gradient(135deg, rgba(82, 201, 165, 0.12) 0%, rgba(78, 205, 196, 0.06) 100%)',
            border: '1px solid rgba(82, 201, 165, 0.25)',
            boxShadow: '0 8px 24px rgba(82, 201, 165, 0.12)'
          }}
        >
          <div className="flex items-center gap-3">
            <div 
              className="w-11 h-11 rounded-[16px] flex items-center justify-center"
              style={{
                background: 'linear-gradient(135deg, #52C9A5 0%, #4ECDC4 100%)',
                boxShadow: '0 4px 16px rgba(82, 201, 165, 0.3)'
              }}
            >
              <TrendingUp size={20} className="text-white" strokeWidth={2} />
            </div>
            <div className="text-left">
              <div className="text-[15px] text-white font-bold">View Statistics</div>
              <div className="text-[12px] text-white/50">Insights & trends</div>
            </div>
          </div>
          <ChevronRight size={20} className="text-white/40" strokeWidth={2.5} />
        </button>

        <div className="h-24" />
      </div>
    </div>
  );
}
