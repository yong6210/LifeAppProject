import { useState } from "react";
import { CloudUpload, CloudDownload, Clock, Check, AlertCircle, ArrowLeft, Shield, Crown } from "lucide-react";
import { Button } from "./ui/button";
import { Switch } from "./ui/switch";
import { toast } from "sonner@2.0.3";

interface BackupScreenProps {
  onBack: () => void;
  isPremium?: boolean;
}

interface BackupHistory {
  id: string;
  timestamp: Date;
  status: "success" | "warning" | "error";
  size: string;
}

export function BackupScreen({ onBack, isPremium = false }: BackupScreenProps) {
  const [autoBackupEnabled, setAutoBackupEnabled] = useState(isPremium);
  const [isBackingUp, setIsBackingUp] = useState(false);
  const [isRestoring, setIsRestoring] = useState(false);

  const lastBackup = new Date(Date.now() - 2 * 60 * 60 * 1000); // 2 hours ago

  const backupHistory: BackupHistory[] = [
    { id: "1", timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000), status: "success", size: "2.4 MB" },
    { id: "2", timestamp: new Date(Date.now() - 26 * 60 * 60 * 1000), status: "success", size: "2.3 MB" },
    { id: "3", timestamp: new Date(Date.now() - 50 * 60 * 60 * 1000), status: "warning", size: "2.1 MB" },
    { id: "4", timestamp: new Date(Date.now() - 74 * 60 * 60 * 1000), status: "success", size: "2.0 MB" },
  ];

  const handleBackup = async () => {
    setIsBackingUp(true);
    // Simulate backup
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsBackingUp(false);
    toast.success("Backup completed", {
      description: "Your data has been safely backed up",
    });
  };

  const handleRestore = async () => {
    setIsRestoring(true);
    // Simulate restore
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsRestoring(false);
    toast.success("Restore completed", {
      description: "Your data has been restored successfully",
    });
  };

  const formatRelativeTime = (date: Date) => {
    const hours = Math.floor((Date.now() - date.getTime()) / (1000 * 60 * 60));
    if (hours < 1) return "Just now";
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
  };

  return (
    <div className="h-full flex flex-col bg-[#FAFAFA]">
      {/* Header */}
      <div className="px-5 py-4 bg-white border-b border-gray-200 flex items-center gap-3">
        <Button
          variant="ghost"
          size="icon"
          className="text-gray-600 hover:text-gray-900 hover:bg-gray-100"
          onClick={onBack}
        >
          <ArrowLeft size={20} strokeWidth={1.5} />
        </Button>
        <div>
          <h2 className="text-gray-900 font-semibold text-lg">Backup & Restore</h2>
          <p className="text-gray-500 text-sm">Keep your data safe</p>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-5 pb-24 space-y-6">
          {/* Last Backup Status */}
          <div className="wellness-card p-5">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 rounded-xl bg-green-100 flex items-center justify-center">
                <Check size={22} className="text-green-600" strokeWidth={1.5} />
              </div>
              <div className="flex-1">
                <div className="text-gray-900 font-semibold text-base">Last Backup</div>
                <div className="text-gray-500 text-sm">{formatRelativeTime(lastBackup)}</div>
              </div>
            </div>
          </div>

          {/* Auto Backup Toggle */}
          <div className="wellness-card p-5">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-blue-100 flex items-center justify-center">
                  <Shield size={18} className="text-blue-600" strokeWidth={1.5} />
                </div>
                <div>
                  <div className="text-gray-900 font-medium text-sm">Auto Backup</div>
                  <div className="text-gray-500 text-xs">Daily automatic backups</div>
                </div>
              </div>
              <Switch 
                checked={autoBackupEnabled} 
                onCheckedChange={isPremium ? setAutoBackupEnabled : undefined}
                disabled={!isPremium}
              />
            </div>
            {!isPremium && (
              <div className="mt-3 pt-3 border-t border-gray-100">
                <button className="text-blue-600 text-xs font-semibold flex items-center gap-1">
                  <Crown size={14} strokeWidth={1.5} />
                  Upgrade to enable auto-backup
                </button>
              </div>
            )}
          </div>

          {/* Backup Actions */}
          <div className="space-y-3">
            <button
              onClick={handleBackup}
              disabled={isBackingUp}
              className="wellness-card p-5 w-full hover:shadow-md transition-all disabled:opacity-50"
            >
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center">
                  <CloudUpload size={22} className="text-blue-600" strokeWidth={1.5} />
                </div>
                <div className="flex-1 text-left">
                  <div className="text-gray-900 font-semibold text-base">
                    {isBackingUp ? "Backing up..." : "Backup Now"}
                  </div>
                  <div className="text-gray-500 text-sm">Save your data to cloud</div>
                </div>
              </div>
            </button>

            <button
              onClick={handleRestore}
              disabled={isRestoring}
              className="wellness-card p-5 w-full hover:shadow-md transition-all disabled:opacity-50"
            >
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-purple-100 flex items-center justify-center">
                  <CloudDownload size={22} className="text-purple-600" strokeWidth={1.5} />
                </div>
                <div className="flex-1 text-left">
                  <div className="text-gray-900 font-semibold text-base">
                    {isRestoring ? "Restoring..." : "Restore Data"}
                  </div>
                  <div className="text-gray-500 text-sm">Recover from backup</div>
                </div>
              </div>
            </button>
          </div>

          {/* Backup History */}
          <div>
            <h3 className="text-gray-900 font-semibold text-base mb-3 px-1">Backup History</h3>
            <div className="wellness-card divide-y divide-gray-100">
              {backupHistory.map((backup) => {
                const StatusIcon = backup.status === "success" ? Check : AlertCircle;
                const statusColor = backup.status === "success" ? "#10B981" : "#F59E0B";
                const statusBg = backup.status === "success" ? "#D1FAE5" : "#FEF3C7";

                return (
                  <div key={backup.id} className="p-4 flex items-center gap-3">
                    <div 
                      className="w-10 h-10 rounded-lg flex items-center justify-center"
                      style={{ backgroundColor: statusBg }}
                    >
                      <StatusIcon size={18} style={{ color: statusColor }} strokeWidth={1.5} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-gray-900 font-medium text-sm">
                        {backup.timestamp.toLocaleDateString('en-US', { 
                          month: 'short', 
                          day: 'numeric',
                          year: 'numeric'
                        })}
                      </div>
                      <div className="text-gray-500 text-xs">
                        {backup.timestamp.toLocaleTimeString('en-US', { 
                          hour: 'numeric', 
                          minute: '2-digit'
                        })} · {backup.size}
                      </div>
                    </div>
                    <div className="text-gray-400 text-xs">
                      {formatRelativeTime(backup.timestamp)}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Info */}
          <div className="wellness-card p-5 bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-100">
            <h4 className="text-gray-900 font-semibold text-sm mb-2">🔒 Your Data is Safe</h4>
            <p className="text-gray-700 text-sm leading-relaxed">
              All backups are encrypted end-to-end and stored securely in the cloud. Your privacy is our priority.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
