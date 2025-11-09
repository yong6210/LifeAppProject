import { Play, Flame, Zap, Heart, TrendingUp } from "lucide-react";
import { useLocalStorage } from "../hooks/useLocalStorage";
import { UserStats, Session } from "../types/session";
import { initializeUserStats, addSession, getTodayStats, calculateXP } from "../utils/stats";
import { toast } from "sonner@2.0.3";
import { useState } from "react";
import { SessionJournal } from "./SessionJournal";

interface WorkoutPreset {
  id: string;
  name: string;
  description: string;
  duration: number;
  calories: number;
  intensity: number; // 1-5
  emoji: string;
}

const workouts: WorkoutPreset[] = [
  {
    id: "1",
    name: "Morning Energizer",
    description: "Wake up your body with dynamic stretches",
    duration: 10,
    calories: 50,
    intensity: 2,
    emoji: "☀️",
  },
  {
    id: "2",
    name: "Cardio Burst",
    description: "High-intensity interval training",
    duration: 15,
    calories: 120,
    intensity: 4,
    emoji: "⚡",
  },
  {
    id: "3",
    name: "Core Power",
    description: "Build strength from your center",
    duration: 20,
    calories: 100,
    intensity: 3,
    emoji: "💪",
  },
  {
    id: "4",
    name: "Full Energy",
    description: "Complete body transformation",
    duration: 30,
    calories: 200,
    intensity: 5,
    emoji: "🔥",
  },
];

export function WorkoutTab() {
  const [showJournal, setShowJournal] = useState(false);
  const [completedSession, setCompletedSession] = useState<Session | null>(null);

  const [userStats, setUserStats] = useLocalStorage<UserStats>(
    "life-app-stats",
    initializeUserStats()
  );

  const todayStats = getTodayStats(userStats);

  const handleStartWorkout = (workout: WorkoutPreset) => {
    const xpEarned = calculateXP(workout.duration, "workout");

    const session: Session = {
      id: Date.now().toString(),
      type: "workout",
      presetName: workout.name,
      duration: workout.duration,
      completedAt: new Date(),
      xpEarned,
    };

    setCompletedSession(session);
    setShowJournal(true);
  };

  const handleJournalComplete = (notes: string, mood: string, effectiveness: number) => {
    if (completedSession) {
      const sessionWithJournal = {
        ...completedSession,
        notes,
        mood,
        effectiveness,
      };

      const newStats = addSession(userStats, sessionWithJournal);
      setUserStats(newStats);

      toast.success("Workout crushed! 💪", {
        description: `Energy flowing! You're unstoppable.`,
      });
    }
    setShowJournal(false);
    setCompletedSession(null);
  };

  const progressPercent = Math.min((todayStats.workoutMinutes / 30) * 100, 100);

  return (
    <>
      <div className="h-full flex flex-col relative overflow-hidden" style={{ background: 'var(--move-bg)' }}>
        {/* Animated Background */}
        <div className="absolute inset-0 opacity-20">
          <div className="absolute top-1/4 left-0 w-96 h-96 rounded-full bg-gradient-to-br from-orange-400 to-yellow-400 blur-3xl animate-pulse" />
          <div className="absolute bottom-1/4 right-0 w-96 h-96 rounded-full bg-gradient-to-br from-amber-400 to-orange-400 blur-3xl animate-pulse" style={{ animationDelay: '0.5s' }} />
        </div>

        {/* Header */}
        <div className="relative z-10 px-5 py-6 text-center">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/80 backdrop-blur-sm border border-orange-200 shadow-lg mb-4">
            <Flame size={18} className="text-orange-600" strokeWidth={2} />
            <span className="font-semibold text-orange-900">Energy Flow</span>
            <Zap size={14} className="text-orange-400" strokeWidth={2} />
          </div>
          <h2 className="text-3xl font-bold mb-2" style={{ 
            background: 'var(--move-gradient)', 
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text'
          }}>
            Movement
          </h2>
          <p className="text-orange-600 font-medium">Feel the energy ⚡</p>
        </div>

        {/* Content */}
        <div className="relative z-10 flex-1 overflow-y-auto">
          <div className="p-5 pb-24">
            {/* Today's Energy Bar */}
            <div className="move-card p-6 mb-6 shadow-xl">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="text-4xl animate-bounce">{progressPercent >= 100 ? "🎉" : "🔥"}</div>
                  <div>
                    <h3 className="text-orange-900 font-bold text-lg">Energy Bank</h3>
                    <p className="text-orange-600 text-sm font-medium">
                      {todayStats.workoutMinutes} / 30 min
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-3xl font-bold text-orange-600">{Math.round(progressPercent)}%</div>
                </div>
              </div>
              
              {/* Animated Progress Bar */}
              <div className="h-4 bg-white/50 rounded-full overflow-hidden relative">
                <div
                  className="h-full rounded-full transition-all duration-1000 relative overflow-hidden"
                  style={{ 
                    width: `${progressPercent}%`,
                    background: 'var(--move-gradient)'
                  }}
                >
                  <div className="absolute inset-0 bg-white/30 animate-pulse" />
                </div>
              </div>
            </div>

            {/* Workout Grid */}
            <div className="space-y-4 mb-6">
              {workouts.map((workout) => {
                const intensityDots = Array(workout.intensity).fill('🔥').join('');
                
                return (
                  <div key={workout.id} className="move-card shadow-lg">
                    <div className="p-5">
                      <div className="flex items-start gap-4 mb-4">
                        <div className="text-5xl">{workout.emoji}</div>
                        <div className="flex-1">
                          <h4 className="text-orange-900 font-bold text-xl mb-1">{workout.name}</h4>
                          <p className="text-orange-700 text-sm mb-3">{workout.description}</p>

                          {/* Stats Row */}
                          <div className="flex items-center gap-4 text-sm mb-3">
                            <div className="badge-move flex items-center gap-1.5">
                              <Heart size={14} strokeWidth={2} />
                              <span>{workout.calories} cal</span>
                            </div>
                            <div className="badge-move">
                              {workout.duration} min
                            </div>
                            <div className="text-orange-600 font-medium">
                              {intensityDots}
                            </div>
                          </div>

                          {/* Intensity Bar */}
                          <div className="flex gap-1 mb-3">
                            {Array(5).fill(0).map((_, i) => (
                              <div 
                                key={i} 
                                className={`h-1.5 flex-1 rounded-full ${
                                  i < workout.intensity 
                                    ? 'bg-gradient-to-r from-orange-400 to-yellow-400' 
                                    : 'bg-orange-200'
                                }`}
                              />
                            ))}
                          </div>
                        </div>
                      </div>

                      <button
                        onClick={() => handleStartWorkout(workout)}
                        className="move-btn w-full h-14 rounded-2xl flex items-center justify-center gap-2"
                      >
                        <Play size={20} fill="white" strokeWidth={2} />
                        <span className="text-lg">Start Workout</span>
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Energy Tip */}
            <div className="move-card p-5 shadow-xl">
              <div className="flex items-start gap-3">
                <div className="text-4xl">⚡</div>
                <div className="flex-1">
                  <h4 className="text-orange-900 font-bold text-base mb-2">
                    Energy Surge!
                  </h4>
                  <p className="text-orange-700 text-sm leading-relaxed">
                    Movement releases endorphins and boosts your metabolism for hours! Even 10 minutes of exercise can increase your energy levels by 20%. Let's move! 🚀
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Session Journal Modal */}
      {showJournal && completedSession && (
        <SessionJournal
          isOpen={showJournal}
          onClose={() => setShowJournal(false)}
          session={completedSession}
          onSave={handleJournalComplete}
        />
      )}
    </>
  );
}
