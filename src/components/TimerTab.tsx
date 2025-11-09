import { useState, useEffect } from "react";
import { Play, Pause, RotateCcw, Zap, Sparkles, Brain } from "lucide-react";
import { CircularProgress } from "./CircularProgress";
import { SessionJournal } from "./SessionJournal";
import { useLocalStorage } from "../hooks/useLocalStorage";
import { UserStats, Session } from "../types/session";
import { initializeUserStats, addSession, calculateXP } from "../utils/stats";
import { toast } from "sonner@2.0.3";

interface TimerPreset {
  id: string;
  name: string;
  duration: number;
  emoji: string;
}

const presets: TimerPreset[] = [
  { id: "1", name: "Focus Boost", duration: 25, emoji: "⚡" },
  { id: "2", name: "Quick Reset", duration: 5, emoji: "🌊" },
  { id: "3", name: "Deep Dive", duration: 52, emoji: "🧠" },
  { id: "4", name: "Power Hour", duration: 60, emoji: "🚀" },
];

export function TimerTab() {
  const [selectedPreset, setSelectedPreset] = useState(presets[0]);
  const [isRunning, setIsRunning] = useState(false);
  const [timeRemaining, setTimeRemaining] = useState(selectedPreset.duration * 60);
  const [showJournal, setShowJournal] = useState(false);
  const [completedSession, setCompletedSession] = useState<Session | null>(null);

  const [userStats, setUserStats] = useLocalStorage<UserStats>(
    "life-app-stats",
    initializeUserStats()
  );

  const totalSeconds = selectedPreset.duration * 60;
  const progress = ((totalSeconds - timeRemaining) / totalSeconds) * 100;

  useEffect(() => {
    setTimeRemaining(selectedPreset.duration * 60);
    setIsRunning(false);
  }, [selectedPreset]);

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isRunning && timeRemaining > 0) {
      interval = setInterval(() => {
        setTimeRemaining((prev) => {
          if (prev <= 1) {
            setIsRunning(false);
            handleComplete();
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isRunning, timeRemaining]);

  const handleComplete = () => {
    const xpEarned = calculateXP(selectedPreset.duration, "focus");

    const session: Session = {
      id: Date.now().toString(),
      type: "focus",
      presetName: selectedPreset.name,
      duration: selectedPreset.duration,
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

      toast.success("Focus session complete! 🎯", {
        description: `Your mind is getting sharper every day.`,
      });
    }
    setShowJournal(false);
    setCompletedSession(null);
  };

  const handleReset = () => {
    setTimeRemaining(selectedPreset.duration * 60);
    setIsRunning(false);
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, "0")}`;
  };

  return (
    <>
      <div className="h-full flex flex-col relative overflow-hidden" style={{ background: 'var(--focus-bg)' }}>
        {/* Animated Background */}
        <div className="absolute inset-0 opacity-30">
          <div className="absolute top-0 left-1/4 w-64 h-64 rounded-full bg-gradient-to-br from-indigo-400 to-purple-400 blur-3xl animate-pulse" />
          <div className="absolute bottom-0 right-1/4 w-64 h-64 rounded-full bg-gradient-to-br from-cyan-400 to-blue-400 blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />
        </div>

        {/* Header */}
        <div className="relative z-10 px-5 py-6 text-center">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/80 backdrop-blur-sm border border-indigo-200 shadow-lg mb-4">
            <Brain size={18} className="text-indigo-600" strokeWidth={2} />
            <span className="font-semibold text-indigo-900">Neural Focus</span>
            <Sparkles size={14} className="text-indigo-400" strokeWidth={2} />
          </div>
          <h2 className="text-3xl font-bold mb-2" style={{ 
            background: 'var(--focus-gradient)', 
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text'
          }}>
            {selectedPreset.name}
          </h2>
          <p className="text-indigo-600 font-medium">{selectedPreset.duration} min session</p>
        </div>

        {/* Content */}
        <div className="relative z-10 flex-1 overflow-y-auto">
          <div className="p-5 pb-24">
            {/* Circular Timer with Glow */}
            <div className="flex justify-center mb-10">
              <div className="relative">
                {/* Outer Glow */}
                <div className="absolute inset-0 blur-2xl opacity-50 animate-pulse" style={{ 
                  background: 'var(--focus-gradient)',
                  borderRadius: '50%',
                  transform: 'scale(1.1)'
                }} />
                
                <div className="relative">
                  <CircularProgress
                    percentage={progress}
                    size={260}
                    strokeWidth={14}
                    accentColor="#4F46E5"
                  />
                  <div className="absolute inset-0 flex flex-col items-center justify-center">
                    <div className="text-6xl mb-3 animate-pulse">{selectedPreset.emoji}</div>
                    <div className="text-indigo-900 text-6xl mb-2 tabular-nums font-bold tracking-tight">
                      {formatTime(timeRemaining)}
                    </div>
                    <div className="text-indigo-600 text-sm font-semibold">
                      {isRunning ? "⚡ Focus Mode Active" : "Ready to focus"}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Controls */}
            <div className="flex justify-center items-center gap-4 mb-10">
              <button
                onClick={handleReset}
                className="w-14 h-14 rounded-2xl bg-white/80 backdrop-blur-sm border-2 border-indigo-200 hover:border-indigo-400 flex items-center justify-center transition-all shadow-lg hover:shadow-xl"
              >
                <RotateCcw size={20} className="text-indigo-600" strokeWidth={2.5} />
              </button>

              <button
                onClick={() => setIsRunning(!isRunning)}
                className="focus-btn w-20 h-20 rounded-[2rem] flex items-center justify-center relative"
              >
                {/* Inner Glow */}
                <div className="absolute inset-2 rounded-[1.5rem] bg-white/20 blur-sm" />
                {isRunning ? (
                  <Pause size={36} fill="white" className="text-white relative z-10" strokeWidth={2} />
                ) : (
                  <Play size={36} fill="white" className="text-white ml-1 relative z-10" strokeWidth={2} />
                )}
              </button>

              <button
                onClick={() => showJournal && setShowJournal(true)}
                className="w-14 h-14 rounded-2xl bg-white/80 backdrop-blur-sm border-2 border-indigo-200 hover:border-indigo-400 flex items-center justify-center transition-all shadow-lg hover:shadow-xl"
              >
                <Zap size={20} className="text-indigo-600" strokeWidth={2.5} />
              </button>
            </div>

            {/* Preset Grid */}
            <div className="grid grid-cols-2 gap-3 mb-6">
              {presets.map((preset) => {
                const isSelected = preset.id === selectedPreset.id;
                return (
                  <button
                    key={preset.id}
                    onClick={() => !isRunning && setSelectedPreset(preset)}
                    disabled={isRunning}
                    className={`focus-card p-5 text-left transition-all ${
                      isRunning ? "opacity-50 cursor-not-allowed" : ""
                    } ${isSelected ? "ring-2 ring-indigo-500 shadow-xl" : "shadow-lg"}`}
                  >
                    <div className="text-3xl mb-3">{preset.emoji}</div>
                    <div className="text-indigo-900 font-bold text-base mb-1">{preset.name}</div>
                    <div className="text-indigo-600 text-sm font-medium">{preset.duration} minutes</div>
                  </button>
                );
              })}
            </div>

            {/* Focus Tips */}
            <div className="focus-card p-5 shadow-xl">
              <div className="flex items-start gap-3">
                <div className="text-3xl">🧠</div>
                <div className="flex-1">
                  <h4 className="text-indigo-900 font-bold text-base mb-2">
                    Neural Boost Active
                  </h4>
                  <p className="text-indigo-700 text-sm leading-relaxed">
                    Your brain works best in focused bursts. Eliminate distractions and let your mind enter the flow state. Deep work creates neural pathways that make you smarter!
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
