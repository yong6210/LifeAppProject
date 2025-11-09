import { ArrowLeft, User, Bell, Database, HelpCircle, ChevronRight, Heart, Smartphone, Crown, Mail, Shield, Info } from "lucide-react";
import { Button } from "./ui/button";
import { Switch } from "./ui/switch";
import { useState } from "react";
import { BackupScreen } from "./BackupScreen";
import { WearableScreen } from "./WearableScreen";
import { useLocalStorage } from "../hooks/useLocalStorage";
import { UserStats } from "../types/session";
import { initializeUserStats } from "../utils/stats";

interface SettingsTabProps {
  onNavigate: (tab: string) => void;
}

export function SettingsTab({ onNavigate }: SettingsTabProps) {
  const [showBackup, setShowBackup] = useState(false);
  const [showWearable, setShowWearable] = useState(false);
  const [isPremium] = useState(false);
  const [notifications, setNotifications] = useState(true);
  const [soundEnabled, setSoundEnabled] = useState(true);

  const [userStats] = useLocalStorage<UserStats>(
    "life-app-stats",
    initializeUserStats()
  );

  if (showBackup) {
    return <BackupScreen onBack={() => setShowBackup(false)} isPremium={isPremium} />;
  }

  if (showWearable) {
    return <WearableScreen onBack={() => setShowWearable(false)} />;
  }

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
          <h2 className="text-gray-900 font-semibold text-lg">Settings</h2>
          <p className="text-gray-500 text-sm">Manage your preferences</p>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-5 pb-24 space-y-6">
          {/* Account Section */}
          <div className="wellness-card p-5">
            <div className="flex items-center gap-4 mb-4">
              <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center shadow-md">
                <User size={24} className="text-white" strokeWidth={1.5} />
              </div>
              <div className="flex-1">
                <h3 className="text-gray-900 font-semibold text-base">Guest User</h3>
                <p className="text-gray-500 text-sm">Level {userStats.level} · {userStats.totalSessions} sessions</p>
              </div>
            </div>

            {!isPremium && (
              <button className="btn-primary w-full h-11 rounded-xl flex items-center justify-center gap-2">
                <Crown size={18} strokeWidth={1.5} />
                <span>Upgrade to Premium</span>
              </button>
            )}
          </div>

          {/* App Features */}
          <div>
            <h3 className="text-gray-900 font-semibold text-base mb-3 px-1">App Features</h3>
            <div className="wellness-card divide-y divide-gray-100">
              <button
                onClick={() => setShowWearable(true)}
                className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-green-100 flex items-center justify-center">
                    <Smartphone size={18} className="text-green-600" strokeWidth={1.5} />
                  </div>
                  <div className="text-left">
                    <div className="text-gray-900 font-medium text-sm">Wearable Integration</div>
                    <div className="text-gray-500 text-xs">Connect health devices</div>
                  </div>
                </div>
                <ChevronRight size={18} className="text-gray-400" strokeWidth={1.5} />
              </button>

              <button
                onClick={() => setShowBackup(true)}
                className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-blue-100 flex items-center justify-center">
                    <Database size={18} className="text-blue-600" strokeWidth={1.5} />
                  </div>
                  <div className="text-left">
                    <div className="text-gray-900 font-medium text-sm">Backup & Restore</div>
                    <div className="text-gray-500 text-xs">Save your data securely</div>
                  </div>
                </div>
                <ChevronRight size={18} className="text-gray-400" strokeWidth={1.5} />
              </button>
            </div>
          </div>

          {/* Preferences */}
          <div>
            <h3 className="text-gray-900 font-semibold text-base mb-3 px-1">Preferences</h3>
            <div className="wellness-card divide-y divide-gray-100">
              <div className="flex items-center justify-between p-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-purple-100 flex items-center justify-center">
                    <Bell size={18} className="text-purple-600" strokeWidth={1.5} />
                  </div>
                  <div>
                    <div className="text-gray-900 font-medium text-sm">Notifications</div>
                    <div className="text-gray-500 text-xs">Get reminders & updates</div>
                  </div>
                </div>
                <Switch checked={notifications} onCheckedChange={setNotifications} />
              </div>

              <div className="flex items-center justify-between p-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-indigo-100 flex items-center justify-center">
                    <Bell size={18} className="text-indigo-600" strokeWidth={1.5} />
                  </div>
                  <div>
                    <div className="text-gray-900 font-medium text-sm">Sound Effects</div>
                    <div className="text-gray-500 text-xs">Timer & completion sounds</div>
                  </div>
                </div>
                <Switch checked={soundEnabled} onCheckedChange={setSoundEnabled} />
              </div>
            </div>
          </div>

          {/* Support */}
          <div>
            <h3 className="text-gray-900 font-semibold text-base mb-3 px-1">Support</h3>
            <div className="wellness-card divide-y divide-gray-100">
              <button className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-amber-100 flex items-center justify-center">
                    <HelpCircle size={18} className="text-amber-600" strokeWidth={1.5} />
                  </div>
                  <div className="text-left">
                    <div className="text-gray-900 font-medium text-sm">Help Center</div>
                    <div className="text-gray-500 text-xs">FAQs and guides</div>
                  </div>
                </div>
                <ChevronRight size={18} className="text-gray-400" strokeWidth={1.5} />
              </button>

              <button className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-pink-100 flex items-center justify-center">
                    <Mail size={18} className="text-pink-600" strokeWidth={1.5} />
                  </div>
                  <div className="text-left">
                    <div className="text-gray-900 font-medium text-sm">Contact Support</div>
                    <div className="text-gray-500 text-xs">We're here to help</div>
                  </div>
                </div>
                <ChevronRight size={18} className="text-gray-400" strokeWidth={1.5} />
              </button>

              <button className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-rose-100 flex items-center justify-center">
                    <Heart size={18} className="text-rose-600" strokeWidth={1.5} />
                  </div>
                  <div className="text-left">
                    <div className="text-gray-900 font-medium text-sm">Rate Life App</div>
                    <div className="text-gray-500 text-xs">Share your experience</div>
                  </div>
                </div>
                <ChevronRight size={18} className="text-gray-400" strokeWidth={1.5} />
              </button>
            </div>
          </div>

          {/* Legal */}
          <div>
            <h3 className="text-gray-900 font-semibold text-base mb-3 px-1">Legal</h3>
            <div className="wellness-card divide-y divide-gray-100">
              <button className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-gray-100 flex items-center justify-center">
                    <Shield size={18} className="text-gray-600" strokeWidth={1.5} />
                  </div>
                  <div className="text-left">
                    <div className="text-gray-900 font-medium text-sm">Privacy Policy</div>
                  </div>
                </div>
                <ChevronRight size={18} className="text-gray-400" strokeWidth={1.5} />
              </button>

              <button className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-gray-100 flex items-center justify-center">
                    <Info size={18} className="text-gray-600" strokeWidth={1.5} />
                  </div>
                  <div className="text-left">
                    <div className="text-gray-900 font-medium text-sm">Terms of Service</div>
                  </div>
                </div>
                <ChevronRight size={18} className="text-gray-400" strokeWidth={1.5} />
              </button>
            </div>
          </div>

          {/* App Info */}
          <div className="text-center py-4">
            <p className="text-gray-400 text-sm">Life App v1.0.0</p>
            <p className="text-gray-400 text-xs mt-1">Your Wellness Companion</p>
          </div>
        </div>
      </div>
    </div>
  );
}
