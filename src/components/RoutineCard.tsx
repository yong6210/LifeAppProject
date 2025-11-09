import { Timer, Activity, Moon, ChevronRight } from "lucide-react";

interface RoutineCardProps {
  type: "focus" | "move" | "sleep";
  title: string;
  description: string;
  todayMinutes: number;
  goalMinutes: number;
  onStart: () => void;
}

const routineConfig = {
  focus: {
    icon: Timer,
    color: "#2563EB",
    lightBg: "#EFF6FF",
    bgColor: "#DBEAFE",
  },
  move: {
    icon: Activity,
    color: "#10B981",
    lightBg: "#ECFDF5",
    bgColor: "#D1FAE5",
  },
  sleep: {
    icon: Moon,
    color: "#7C3AED",
    lightBg: "#F5F3FF",
    bgColor: "#EDE9FE",
  },
};

export function RoutineCard({
  type,
  title,
  description,
  todayMinutes,
  goalMinutes,
  onStart,
}: RoutineCardProps) {
  const config = routineConfig[type];
  const Icon = config.icon;
  const progress = Math.min((todayMinutes / goalMinutes) * 100, 100);
  const isCompleted = todayMinutes >= goalMinutes;

  return (
    <button
      onClick={onStart}
      className="wellness-card p-4 w-full text-left hover:shadow-md transition-all"
    >
      <div className="flex items-center gap-3 mb-3">
        <div 
          className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0"
          style={{ backgroundColor: config.bgColor }}
        >
          <Icon size={20} style={{ color: config.color }} strokeWidth={1.5} />
        </div>
        
        <div className="flex-1 min-w-0">
          <h3 className="text-gray-900 font-semibold text-base mb-0.5">{title}</h3>
          <p className="text-gray-500 text-sm">{description}</p>
        </div>

        <ChevronRight size={20} className="text-gray-400 flex-shrink-0" strokeWidth={1.5} />
      </div>

      {/* Progress */}
      <div className="space-y-2">
        <div className="flex justify-between items-center text-sm">
          <span className="text-gray-600 font-medium">
            {todayMinutes} / {goalMinutes} {type === "sleep" ? "hours" : "min"}
          </span>
          <span className="font-semibold" style={{ color: config.color }}>
            {Math.round(progress)}%
          </span>
        </div>
        
        <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
          <div
            className="h-full rounded-full transition-all duration-500"
            style={{ 
              width: `${progress}%`,
              backgroundColor: config.color
            }}
          />
        </div>
        
        {isCompleted && (
          <div className="text-xs text-green-600 font-medium">✓ Goal completed</div>
        )}
      </div>
    </button>
  );
}
