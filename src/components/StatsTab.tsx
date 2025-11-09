import { ArrowLeft, TrendingUp, Clock, Activity, Moon, Flame, Target, Award, Calendar } from "lucide-react";
import { Button } from "./ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./ui/tabs";
import { BarChart, Bar, XAxis, YAxis, ResponsiveContainer, LineChart, Line, Tooltip } from "recharts";
import { useLocalStorage } from "../hooks/useLocalStorage";
import { UserStats } from "../types/session";
import { initializeUserStats, getTodayStats, getWeekData, getMonthData, getRecentSessions } from "../utils/stats";

interface StatsTabProps {
  onNavigate: (tab: string) => void;
}

export function StatsTab({ onNavigate }: StatsTabProps) {
  const [userStats] = useLocalStorage<UserStats>(
    "life-app-stats",
    initializeUserStats()
  );

  const todayStats = getTodayStats(userStats);
  const weekData = getWeekData(userStats);
  const monthData = getMonthData(userStats);
  const recentSessions = getRecentSessions(userStats, 10);

  // Calculate weekly totals
  const weeklyFocus = weekData.reduce((sum, day) => sum + day.focus, 0);
  const weeklyWorkout = weekData.reduce((sum, day) => sum + day.workout, 0);
  const weeklySleep = weekData.reduce((sum, day) => sum + day.sleep, 0);
  const weeklyTotal = weeklyFocus + weeklyWorkout + weeklySleep;

  // Calculate averages
  const avgDailyMinutes = Math.round(userStats.totalMinutes / Math.max(userStats.totalSessions, 1));

  return (
    <div className="h-full flex flex-col bg-[#FAFAFA]">
      {/* Header */}
      <div className="px-5 py-4 bg-white border-b border-gray-200 flex items-center gap-3">
        <Button
          variant="ghost"
          size="icon"
          className="text-gray-600 hover:text-gray-900 hover:bg-gray-100"
          onClick={() => onNavigate("home")}
        >
          <ArrowLeft size={20} strokeWidth={1.5} />
        </Button>
        <div>
          <h2 className="text-gray-900 font-semibold text-lg">Analytics</h2>
          <p className="text-gray-500 text-sm">Track your wellness journey</p>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-5 pb-24 space-y-6">
          {/* Key Metrics */}
          <div>
            <h3 className="text-gray-900 font-semibold text-base mb-3">Key Metrics</h3>
            <div className="grid grid-cols-3 gap-3">
              <div className="wellness-card p-4">
                <div className="w-10 h-10 rounded-lg bg-orange-100 flex items-center justify-center mb-3">
                  <Flame size={18} className="text-orange-600" strokeWidth={1.5} />
                </div>
                <div className="text-gray-900 font-semibold text-2xl mb-0.5">{userStats.currentStreak}</div>
                <div className="text-gray-500 text-xs">Day Streak</div>
              </div>

              <div className="wellness-card p-4">
                <div className="w-10 h-10 rounded-lg bg-green-100 flex items-center justify-center mb-3">
                  <Target size={18} className="text-green-600" strokeWidth={1.5} />
                </div>
                <div className="text-gray-900 font-semibold text-2xl mb-0.5">{userStats.totalSessions}</div>
                <div className="text-gray-500 text-xs">Sessions</div>
              </div>

              <div className="wellness-card p-4">
                <div className="w-10 h-10 rounded-lg bg-blue-100 flex items-center justify-center mb-3">
                  <Award size={18} className="text-blue-600" strokeWidth={1.5} />
                </div>
                <div className="text-gray-900 font-semibold text-2xl mb-0.5">{avgDailyMinutes}</div>
                <div className="text-gray-500 text-xs">Avg Min</div>
              </div>
            </div>
          </div>

          {/* Chart Tabs */}
          <Tabs defaultValue="week">
            <TabsList className="grid w-full grid-cols-3 bg-gray-100 p-1 rounded-lg">
              <TabsTrigger 
                value="day" 
                className="rounded-md text-gray-600 data-[state=active]:text-gray-900 data-[state=active]:bg-white"
              >
                Today
              </TabsTrigger>
              <TabsTrigger 
                value="week" 
                className="rounded-md text-gray-600 data-[state=active]:text-gray-900 data-[state=active]:bg-white"
              >
                Week
              </TabsTrigger>
              <TabsTrigger 
                value="month" 
                className="rounded-md text-gray-600 data-[state=active]:text-gray-900 data-[state=active]:bg-white"
              >
                Month
              </TabsTrigger>
            </TabsList>

            <TabsContent value="day" className="mt-4">
              {/* Today's Breakdown */}
              <div className="wellness-card p-5 mb-4">
                <h4 className="text-gray-900 font-semibold text-base mb-4">Today's Activity</h4>
                
                <div className="space-y-4">
                  {[
                    { label: "Focus", value: todayStats.focusMinutes, icon: Clock, color: "#2563EB", bg: "#DBEAFE" },
                    { label: "Movement", value: todayStats.workoutMinutes, icon: Activity, color: "#10B981", bg: "#D1FAE5" },
                    { label: "Sleep", value: todayStats.sleepMinutes, icon: Moon, color: "#7C3AED", bg: "#EDE9FE" },
                  ].map((item) => {
                    const Icon = item.icon;
                    return (
                      <div key={item.label} className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-lg flex items-center justify-center" style={{ backgroundColor: item.bg }}>
                            <Icon size={18} style={{ color: item.color }} strokeWidth={1.5} />
                          </div>
                          <span className="text-gray-700 font-medium text-sm">{item.label}</span>
                        </div>
                        <div className="text-right">
                          <span className="text-gray-900 font-semibold text-lg">{item.value}</span>
                          <span className="text-gray-500 text-sm ml-1">min</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Recent Sessions */}
              <div className="wellness-card p-5">
                <h4 className="text-gray-900 font-semibold text-base mb-4">Recent Sessions</h4>
                {recentSessions.length > 0 ? (
                  <div className="space-y-2">
                    {recentSessions.slice(0, 5).map((session) => {
                      const Icon = session.type === "focus" ? Clock : session.type === "workout" ? Activity : Moon;
                      const color = session.type === "focus" ? "#2563EB" : session.type === "workout" ? "#10B981" : "#7C3AED";
                      const bg = session.type === "focus" ? "#DBEAFE" : session.type === "workout" ? "#D1FAE5" : "#EDE9FE";
                      const time = new Date(session.completedAt).toLocaleTimeString("en-US", { 
                        hour: "numeric", 
                        minute: "2-digit",
                        hour12: true 
                      });
                      
                      return (
                        <div 
                          key={session.id}
                          className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
                        >
                          <div className="w-9 h-9 rounded-lg flex items-center justify-center" style={{ backgroundColor: bg }}>
                            <Icon size={16} style={{ color }} strokeWidth={1.5} />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="text-gray-900 font-medium text-sm truncate">{session.presetName}</div>
                            <div className="text-gray-500 text-xs">{session.duration} min</div>
                          </div>
                          <div className="text-gray-500 text-xs whitespace-nowrap">{time}</div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div className="text-center py-8 text-gray-400">
                    <Calendar size={32} className="mx-auto mb-2 opacity-40" strokeWidth={1.5} />
                    <p className="text-sm">No sessions yet today</p>
                  </div>
                )}
              </div>
            </TabsContent>

            <TabsContent value="week" className="mt-4">
              <div className="wellness-card p-5 mb-4">
                <h4 className="text-gray-900 font-semibold text-base mb-6">Weekly Progress</h4>
                <ResponsiveContainer width="100%" height={200}>
                  <LineChart data={weekData}>
                    <XAxis 
                      dataKey="day" 
                      stroke="#E5E7EB" 
                      tick={{ fill: '#6B7280', fontSize: 12 }}
                      tickLine={false}
                    />
                    <YAxis 
                      stroke="#E5E7EB" 
                      tick={{ fill: '#6B7280', fontSize: 12 }}
                      tickLine={false}
                    />
                    <Tooltip 
                      contentStyle={{ 
                        backgroundColor: '#ffffff',
                        border: '1px solid #E5E7EB',
                        borderRadius: '0.5rem',
                        fontSize: '14px'
                      }}
                    />
                    <Line 
                      type="monotone" 
                      dataKey="focus" 
                      stroke="#2563EB" 
                      strokeWidth={2}
                      dot={{ fill: '#2563EB', r: 4 }}
                      activeDot={{ r: 6 }}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div className="wellness-card p-4">
                  <div className="w-9 h-9 rounded-lg bg-blue-100 flex items-center justify-center mb-2">
                    <Clock size={16} className="text-blue-600" strokeWidth={1.5} />
                  </div>
                  <div className="text-gray-900 font-semibold text-lg">{weeklyFocus}</div>
                  <div className="text-gray-500 text-xs">Focus min</div>
                </div>
                <div className="wellness-card p-4">
                  <div className="w-9 h-9 rounded-lg bg-green-100 flex items-center justify-center mb-2">
                    <Activity size={16} className="text-green-600" strokeWidth={1.5} />
                  </div>
                  <div className="text-gray-900 font-semibold text-lg">{weeklyWorkout}</div>
                  <div className="text-gray-500 text-xs">Move min</div>
                </div>
                <div className="wellness-card p-4">
                  <div className="w-9 h-9 rounded-lg bg-purple-100 flex items-center justify-center mb-2">
                    <Moon size={16} className="text-purple-600" strokeWidth={1.5} />
                  </div>
                  <div className="text-gray-900 font-semibold text-lg">
                    {Math.floor(weeklySleep / 60)}h
                  </div>
                  <div className="text-gray-500 text-xs">Sleep</div>
                </div>
              </div>
            </TabsContent>

            <TabsContent value="month" className="mt-4">
              <div className="wellness-card p-5 mb-4">
                <h4 className="text-gray-900 font-semibold text-base mb-6">Monthly Overview</h4>
                <ResponsiveContainer width="100%" height={200}>
                  <BarChart data={monthData}>
                    <XAxis 
                      dataKey="week" 
                      stroke="#E5E7EB"
                      tick={{ fill: '#6B7280', fontSize: 12 }}
                      tickLine={false}
                    />
                    <YAxis 
                      stroke="#E5E7EB"
                      tick={{ fill: '#6B7280', fontSize: 12 }}
                      tickLine={false}
                    />
                    <Tooltip 
                      contentStyle={{ 
                        backgroundColor: '#ffffff',
                        border: '1px solid #E5E7EB',
                        borderRadius: '0.5rem',
                        fontSize: '14px'
                      }}
                    />
                    <Bar 
                      dataKey="total" 
                      fill="#2563EB" 
                      radius={[8, 8, 0, 0]}
                    />
                  </BarChart>
                </ResponsiveContainer>
              </div>

              <div className="wellness-card p-5">
                <h4 className="text-gray-900 font-semibold text-base mb-4">All-Time Stats</h4>
                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600 text-sm">Total Active Time</span>
                    <span className="text-gray-900 font-semibold">{Math.floor(userStats.totalMinutes / 60)}h {userStats.totalMinutes % 60}m</span>
                  </div>
                  <div className="wellness-divider" />
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600 text-sm">Total Sessions</span>
                    <span className="text-gray-900 font-semibold">{userStats.totalSessions}</span>
                  </div>
                  <div className="wellness-divider" />
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600 text-sm">Longest Streak</span>
                    <span className="text-gray-900 font-semibold">{userStats.longestStreak} days</span>
                  </div>
                </div>
              </div>
            </TabsContent>
          </Tabs>

          {/* Insights */}
          <div className="wellness-card p-5 bg-gradient-to-br from-purple-50 to-pink-50 border-purple-100">
            <h4 className="text-gray-900 font-semibold text-base mb-2">💡 Weekly Insight</h4>
            <p className="text-gray-700 text-sm leading-relaxed">
              {weeklyTotal > 0 
                ? `You've been active for ${weeklyTotal} minutes this week! ${weeklyFocus > weeklyWorkout ? "Your focus sessions are strong" : "Great job staying active"}. Keep it up!`
                : "Start your first session this week to build a healthy routine."}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
