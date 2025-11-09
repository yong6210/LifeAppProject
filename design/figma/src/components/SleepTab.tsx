import { Moon, Volume2, Cloud, Waves, Wind, Sparkles, Stars } from "lucide-react";
import { Slider } from "./ui/slider";
import { useState } from "react";
import { useLocalStorage } from "../hooks/useLocalStorage";
import { UserStats, Session } from "../types/session";
import { initializeUserStats, addSession, getTodayStats, calculateXP } from "../utils/stats";
import { toast } from "sonner@2.0.3";

interface SoundPreset {
  id: string;
  name: string;
  icon: any;
  emoji: string;
  description: string;
}

const soundPresets: SoundPreset[] = [
  {
    id: "rain",
    name: "Rain",
    icon: Cloud,
    emoji: "🌧️",
    description: "Gentle rainfall",
  },
  {
    id: "ocean",
    name: "Ocean",
    icon: Waves,
    emoji: "🌊",
    description: "Peaceful waves",
  },
  {
    id: "wind",
    name: "Wind",
    icon: Wind,
    emoji: "🍃",
    description: "Soft breeze",
  },
  {
    id: "cosmic",
    name: "Cosmic",
    icon: Stars,
    emoji: "✨",
    description: "Space ambience",
  },
];

export function SleepTab() {
  const [selectedSound, setSelectedSound] = useState(soundPresets[0]);
  const [volume, setVolume] = useState([60]);
  const [isPlaying, setIsPlaying] = useState(false);
  const [duration, setDuration] = useState(30);

  const [userStats, setUserStats] = useLocalStorage<UserStats>(
    "life-app-stats",
    initializeUserStats()
  );

  const todayStats = getTodayStats(userStats);

  const handleStartSleep = () => {
    setIsPlaying(!isPlaying);
    
    if (!isPlaying) {
      toast.success("Sleep mode activated 🌙", {
        description: `Drift into peaceful dreams with ${selectedSound.name}`,
      });
    }
  };

  const handleLogSleep = () => {
    const xpEarned = calculateXP(duration, "sleep");

    const session: Session = {
      id: Date.now().toString(),
      type: "sleep",
      presetName: `${selectedSound.name} - ${duration}min`,
      duration: duration,
      completedAt: new Date(),
      xpEarned,
    };

    const newStats = addSession(userStats, session);
    setUserStats(newStats);

    toast.success("Rest logged! 💤", {
      description: `Sweet dreams! Recovery is progress.`,
    });

    setIsPlaying(false);
  };

  const sleepHours = Math.floor(todayStats.sleepMinutes / 60);
  const sleepMins = todayStats.sleepMinutes % 60;
  const sleepPercent = Math.min((todayStats.sleepMinutes / 480) * 100, 100);

  return (
    <div className="h-full flex flex-col relative overflow-hidden" style={{ background: 'var(--sleep-bg)' }}>
      {/* Animated Starfield Background */}
      <div className="absolute inset-0 opacity-20">
        <div className="absolute top-1/4 left-1/4 w-72 h-72 rounded-full bg-gradient-to-br from-purple-400 to-pink-400 blur-3xl animate-pulse" />
        <div className="absolute bottom-1/4 right-1/4 w-72 h-72 rounded-full bg-gradient-to-br from-fuchsia-400 to-purple-400 blur-3xl animate-pulse" style={{ animationDelay: '1.5s' }} />
        {/* Stars */}
        {[...Array(20)].map((_, i) => (
          <div
            key={i}
            className="absolute w-1 h-1 bg-white rounded-full animate-pulse"
            style={{
              top: `${Math.random() * 100}%`,
              left: `${Math.random() * 100}%`,
              animationDelay: `${Math.random() * 3}s`,
              opacity: Math.random() * 0.7 + 0.3
            }}
          />
        ))}
      </div>

      {/* Header */}
      <div className="relative z-10 px-5 py-6 text-center">
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/80 backdrop-blur-sm border border-purple-200 shadow-lg mb-4">
          <Moon size={18} className="text-purple-600" strokeWidth={2} />
          <span className="font-semibold text-purple-900">Cosmic Dreams</span>
          <Sparkles size={14} className="text-purple-400" strokeWidth={2} />
        </div>
        <h2 className="text-3xl font-bold mb-2" style={{ 
          background: 'var(--sleep-gradient)', 
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
          backgroundClip: 'text'
        }}>
          Rest & Recharge
        </h2>
        <p className="text-purple-600 font-medium">Journey to the stars ✨</p>
      </div>

      {/* Content */}
      <div className="relative z-10 flex-1 overflow-y-auto">
        <div className="p-5 pb-24">
          {/* Sleep Progress */}
          <div className="sleep-card p-6 mb-6 shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="text-4xl">{sleepPercent >= 100 ? "🌟" : "🌙"}</div>
                <div>
                  <h3 className="text-purple-900 font-bold text-lg">Dream Bank</h3>
                  <p className="text-purple-600 text-sm font-medium">
                    {sleepHours}h {sleepMins}m / 8h
                  </p>
                </div>
              </div>
              <div className="text-right">
                <div className="text-3xl font-bold text-purple-600">{Math.round(sleepPercent)}%</div>
              </div>
            </div>
            
            {/* Animated Progress */}
            <div className="h-4 bg-white/50 rounded-full overflow-hidden relative">
              <div
                className="h-full rounded-full transition-all duration-1000 relative"
                style={{ 
                  width: `${sleepPercent}%`,
                  background: 'var(--sleep-gradient)'
                }}
              >
                <div className="absolute inset-0">
                  {[...Array(3)].map((_, i) => (
                    <div
                      key={i}
                      className="absolute h-full w-8 bg-white/40 blur-sm animate-pulse"
                      style={{
                        left: `${i * 33}%`,
                        animationDelay: `${i * 0.5}s`
                      }}
                    />
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Duration Selector */}
          <div className="sleep-card p-5 mb-6 shadow-lg">
            <h3 className="text-purple-900 font-bold text-base mb-4 flex items-center gap-2">
              <Moon size={18} strokeWidth={2} />
              Dream Duration
            </h3>
            <div className="grid grid-cols-4 gap-2">
              {[10, 20, 30, 60].map((mins) => (
                <button
                  key={mins}
                  onClick={() => setDuration(mins)}
                  className={`h-12 rounded-xl font-bold transition-all ${
                    duration === mins
                      ? "sleep-btn text-white shadow-lg"
                      : "bg-white/70 border-2 border-purple-200 text-purple-700 hover:border-purple-400"
                  }`}
                >
                  {mins}m
                </button>
              ))}
            </div>
          </div>

          {/* Sound Selection */}
          <div className="mb-6">
            <h3 className="text-purple-900 font-bold text-base mb-4 flex items-center gap-2 px-1">
              <Volume2 size={18} strokeWidth={2} />
              Ambient Sounds
            </h3>
            <div className="grid grid-cols-2 gap-3">
              {soundPresets.map((sound) => {
                const Icon = sound.icon;
                const isSelected = selectedSound.id === sound.id;

                return (
                  <button
                    key={sound.id}
                    onClick={() => setSelectedSound(sound)}
                    className={`sleep-card p-5 text-left transition-all shadow-lg ${
                      isSelected ? "ring-2 ring-purple-500 shadow-2xl scale-105" : ""
                    }`}
                  >
                    <div className="text-4xl mb-3">{sound.emoji}</div>
                    <div className="text-purple-900 font-bold text-base mb-1">{sound.name}</div>
                    <div className="text-purple-600 text-xs font-medium">{sound.description}</div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Volume Control */}
          <div className="sleep-card p-5 mb-6 shadow-lg">
            <div className="flex items-center justify-between mb-4">
              <h4 className="text-purple-900 font-bold text-base flex items-center gap-2">
                <Volume2 size={18} strokeWidth={2} />
                Volume
              </h4>
              <div className="flex items-center gap-2">
                <span className="text-purple-700 font-bold text-base tabular-nums">{volume[0]}%</span>
              </div>
            </div>
            <Slider
              value={volume}
              onValueChange={setVolume}
              max={100}
              step={1}
              className="w-full"
            />
            <div className="flex justify-between mt-2 text-xs text-purple-500 font-medium">
              <span>Whisper</span>
              <span>Perfect</span>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="space-y-3 mb-6">
            <button
              onClick={handleStartSleep}
              className={`w-full h-14 rounded-2xl font-bold text-lg flex items-center justify-center gap-2 transition-all shadow-xl ${
                isPlaying 
                  ? "bg-gradient-to-r from-gray-600 to-gray-700 text-white" 
                  : "sleep-btn"
              }`}
            >
              {isPlaying ? "Stop Session" : "Begin Dream Journey"}
            </button>

            {isPlaying && (
              <button
                onClick={handleLogSleep}
                className="w-full h-12 rounded-xl bg-white/80 backdrop-blur-sm border-2 border-purple-300 text-purple-900 font-bold hover:bg-white transition-all"
              >
                Log Sleep Now
              </button>
            )}
          </div>

          {/* Sleep Wisdom */}
          <div className="sleep-card p-5 shadow-xl">
            <div className="flex items-start gap-3">
              <div className="text-4xl">🌟</div>
              <div className="flex-1">
                <h4 className="text-purple-900 font-bold text-base mb-2">
                  Sleep Science
                </h4>
                <p className="text-purple-700 text-sm leading-relaxed mb-3">
                  Quality sleep is when your body repairs muscles, consolidates memories, and balances hormones. The cosmic sounds help your brain enter deeper sleep stages naturally. ✨
                </p>
                <div className="space-y-1 text-xs text-purple-600 font-medium">
                  <div>🌙 Cool, dark room = better sleep</div>
                  <div>✨ No screens 1 hour before bed</div>
                  <div>🌟 Consistent sleep schedule helps</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
