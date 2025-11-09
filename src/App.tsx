import { useState } from "react";
import { Home, Timer, Activity, Moon, User } from "lucide-react";
import { DashboardTab } from "./components/DashboardTab";
import { TimerTab } from "./components/TimerTab";
import { WorkoutTab } from "./components/WorkoutTab";
import { SleepTab } from "./components/SleepTab";
import { StatsTab } from "./components/StatsTab";
import { SettingsTab } from "./components/SettingsTab";
import { OnboardingFlow } from "./components/OnboardingFlow";
import { useLocalStorage } from "./hooks/useLocalStorage";
import { UserStats } from "./types/session";
import { initializeUserStats } from "./utils/stats";
import { Toaster } from "./components/ui/sonner";
import "./styles/globals.css";
import { motion } from "motion/react";

type TabType = "home" | "timer" | "workout" | "sleep" | "stats" | "settings";

function App() {
  const [activeTab, setActiveTab] = useState<TabType>("home");
  const [hasCompletedOnboarding, setHasCompletedOnboarding] = useLocalStorage(
    "life-app-onboarding-completed",
    false
  );
  const [userStats] = useLocalStorage<UserStats>(
    "life-app-stats",
    initializeUserStats()
  );

  const tabs = [
    { id: "home" as TabType, icon: Home, label: "Home", color: "#98989D" },
    { id: "timer" as TabType, icon: Timer, label: "Focus", color: "#0A84FF" },
    { id: "workout" as TabType, icon: Activity, label: "Move", color: "#FF9F0A" },
    { id: "sleep" as TabType, icon: Moon, label: "Rest", color: "#BF5AF2" },
  ];

  const renderTabContent = () => {
    switch (activeTab) {
      case "home":
        return <DashboardTab onNavigate={setActiveTab} />;
      case "timer":
        return <TimerTab />;
      case "workout":
        return <WorkoutTab />;
      case "sleep":
        return <SleepTab />;
      case "stats":
        return <StatsTab onNavigate={setActiveTab} />;
      case "settings":
        return <SettingsTab onNavigate={setActiveTab} />;
      default:
        return <DashboardTab onNavigate={setActiveTab} />;
    }
  };

  return (
    <>
      {/* Onboarding Flow */}
      <OnboardingFlow
        isOpen={!hasCompletedOnboarding}
        onComplete={() => setHasCompletedOnboarding(true)}
      />

      <div className="h-screen w-full max-w-[430px] mx-auto relative bg-[#F2F2F7] overflow-hidden">
        {/* Main Content */}
        <div className="h-[calc(100vh-83px)] overflow-hidden">
          {renderTabContent()}
        </div>

        {/* iOS-style Tab Bar */}
        <div className="absolute bottom-0 left-0 right-0 bg-white/80 backdrop-blur-xl border-t border-black/10">
          <div className="flex items-center justify-around h-[83px] px-2 max-w-[430px] mx-auto pb-[20px] pt-[8px]">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;

              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className="flex flex-col items-center justify-center gap-[2px] ios-ease active:scale-95"
                >
                  <Icon
                    size={24}
                    strokeWidth={2}
                    style={{
                      color: isActive ? tab.color : "#8E8E93",
                    }}
                  />
                  <span
                    className="ios-caption2"
                    style={{
                      color: isActive ? tab.color : "#8E8E93",
                    }}
                  >
                    {tab.label}
                  </span>
                </button>
              );
            })}

            {/* Profile Tab */}
            <button
              onClick={() => setActiveTab("settings")}
              className="flex flex-col items-center justify-center gap-[2px] ios-ease active:scale-95"
            >
              <User
                size={24}
                strokeWidth={2}
                style={{
                  color: activeTab === "settings" ? "#8E8E93" : "#8E8E93",
                }}
              />
              <span
                className="ios-caption2"
                style={{
                  color: activeTab === "settings" ? "#8E8E93" : "#8E8E93",
                }}
              >
                Profile
              </span>
            </button>
          </div>
        </div>

        {/* Toast Notifications */}
        <Toaster
          position="top-center"
          toastOptions={{
            style: {
              background: "white",
              color: "#000000",
              border: "1px solid rgba(0,0,0,0.1)",
              borderRadius: "12px",
              fontWeight: "500",
              fontSize: "15px",
              boxShadow: "0 4px 16px rgba(0, 0, 0, 0.12)",
            },
          }}
        />
      </div>
    </>
  );
}

export default App;