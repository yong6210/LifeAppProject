import { Timer, Activity, Moon } from "lucide-react";

interface DailyStatsCardProps {
  focusMinutes: number;
  workoutMinutes: number;
  sleepMinutes: number;
  totalMinutes: number;
  isPremium: boolean;
}

export function DailyStatsCard({
  focusMinutes,
  workoutMinutes,
  sleepMinutes,
  totalMinutes,
}: DailyStatsCardProps) {
  const stats = [
    {
      label: "Focus",
      value: focusMinutes,
      icon: Timer,
      color: "#2563EB",
      bgColor: "#DBEAFE",
    },
    {
      label: "Movement",
      value: workoutMinutes,
      icon: Activity,
      color: "#10B981",
      bgColor: "#D1FAE5",
    },
    {
      label: "Sleep",
      value: sleepMinutes,
      icon: Moon,
      color: "#7C3AED",
      bgColor: "#EDE9FE",
    },
  ];

  return (
    <div className="wellness-card p-5">
      <div className="space-y-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          const percentage = totalMinutes > 0 ? (stat.value / totalMinutes) * 100 : 0;

          return (
            <div key={stat.label}>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2.5">
                  <div
                    className="w-9 h-9 rounded-lg flex items-center justify-center"
                    style={{ backgroundColor: stat.bgColor }}
                  >
                    <Icon size={16} style={{ color: stat.color }} strokeWidth={1.5} />
                  </div>
                  <span className="text-gray-700 font-medium text-sm">{stat.label}</span>
                </div>
                <div className="text-right">
                  <span className="text-gray-900 font-semibold">{stat.value}</span>
                  <span className="text-gray-500 text-sm ml-1">min</span>
                </div>
              </div>

              <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{ 
                    width: `${percentage}%`,
                    backgroundColor: stat.color
                  }}
                />
              </div>
            </div>
          );
        })}
      </div>

      {totalMinutes === 0 && (
        <div className="text-center py-6 border-t border-gray-200 mt-5">
          <div className="text-4xl mb-2">📊</div>
          <p className="text-gray-500 text-sm">No activity recorded yet</p>
          <p className="text-gray-400 text-xs mt-1">Start a session to see your progress</p>
        </div>
      )}
    </div>
  );
}
