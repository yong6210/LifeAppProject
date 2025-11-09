import { ArrowLeft, Smartphone, Watch, Heart, Activity, Moon, Check, AlertCircle, ChevronRight } from "lucide-react";
import { Button } from "./ui/button";
import { Switch } from "./ui/switch";
import { useState } from "react";
import { toast } from "sonner@2.0.3";

interface WearableScreenProps {
  onBack: () => void;
}

interface Device {
  id: string;
  name: string;
  type: "apple" | "google";
  connected: boolean;
  lastSync?: Date;
  icon: any;
}

const availableDevices: Device[] = [
  {
    id: "apple-watch",
    name: "Apple Watch",
    type: "apple",
    connected: false,
    icon: Watch,
  },
  {
    id: "apple-health",
    name: "Apple Health",
    type: "apple",
    connected: true,
    lastSync: new Date(Date.now() - 30 * 60 * 1000),
    icon: Heart,
  },
  {
    id: "google-fit",
    name: "Google Fit",
    type: "google",
    connected: false,
    icon: Activity,
  },
];

export function WearableScreen({ onBack }: WearableScreenProps) {
  const [devices, setDevices] = useState(availableDevices);
  const [syncHeartRate, setSyncHeartRate] = useState(true);
  const [syncSleep, setSyncSleep] = useState(true);
  const [syncActivity, setSyncActivity] = useState(true);

  const handleToggleDevice = async (deviceId: string) => {
    const device = devices.find(d => d.id === deviceId);
    if (!device) return;

    if (!device.connected) {
      // Simulate connection
      toast.success(`Connecting to ${device.name}...`, {
        description: "This may take a few moments",
      });
      
      setTimeout(() => {
        setDevices(prev => prev.map(d => 
          d.id === deviceId 
            ? { ...d, connected: true, lastSync: new Date() }
            : d
        ));
        toast.success(`${device.name} connected`, {
          description: "Your health data will now sync automatically",
        });
      }, 2000);
    } else {
      setDevices(prev => prev.map(d => 
        d.id === deviceId 
          ? { ...d, connected: false, lastSync: undefined }
          : d
      ));
      toast.success(`${device.name} disconnected`);
    }
  };

  const formatLastSync = (date?: Date) => {
    if (!date) return "Never";
    const minutes = Math.floor((Date.now() - date.getTime()) / (1000 * 60));
    if (minutes < 1) return "Just now";
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    return `${hours}h ago`;
  };

  const connectedDevices = devices.filter(d => d.connected);

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
          <h2 className="text-gray-900 font-semibold text-lg">Wearable Devices</h2>
          <p className="text-gray-500 text-sm">Connect your health trackers</p>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-5 pb-24 space-y-6">
          {/* Status Overview */}
          {connectedDevices.length > 0 && (
            <div className="wellness-card p-5 bg-gradient-to-br from-green-50 to-emerald-50 border-green-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-green-200 flex items-center justify-center">
                  <Check size={18} className="text-green-700" strokeWidth={1.5} />
                </div>
                <div className="flex-1">
                  <div className="text-gray-900 font-semibold text-base">
                    {connectedDevices.length} Device{connectedDevices.length > 1 ? 's' : ''} Connected
                  </div>
                  <div className="text-gray-600 text-sm">Health data syncing automatically</div>
                </div>
              </div>
            </div>
          )}

          {/* Available Devices */}
          <div>
            <h3 className="text-gray-900 font-semibold text-base mb-3 px-1">Available Devices</h3>
            <div className="wellness-card divide-y divide-gray-100">
              {devices.map((device) => {
                const Icon = device.icon;
                return (
                  <div key={device.id} className="p-4">
                    <div className="flex items-center gap-3 mb-3">
                      <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                        device.connected ? "bg-green-100" : "bg-gray-100"
                      }`}>
                        <Icon 
                          size={22} 
                          className={device.connected ? "text-green-600" : "text-gray-500"} 
                          strokeWidth={1.5} 
                        />
                      </div>
                      <div className="flex-1">
                        <div className="text-gray-900 font-semibold text-base">{device.name}</div>
                        <div className="text-gray-500 text-sm">
                          {device.connected 
                            ? `Last sync: ${formatLastSync(device.lastSync)}`
                            : "Not connected"
                          }
                        </div>
                      </div>
                      <Switch
                        checked={device.connected}
                        onCheckedChange={() => handleToggleDevice(device.id)}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Data Sync Preferences */}
          {connectedDevices.length > 0 && (
            <div>
              <h3 className="text-gray-900 font-semibold text-base mb-3 px-1">Sync Preferences</h3>
              <div className="wellness-card divide-y divide-gray-100">
                <div className="flex items-center justify-between p-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-red-100 flex items-center justify-center">
                      <Heart size={18} className="text-red-600" strokeWidth={1.5} />
                    </div>
                    <div>
                      <div className="text-gray-900 font-medium text-sm">Heart Rate & HRV</div>
                      <div className="text-gray-500 text-xs">Track heart health metrics</div>
                    </div>
                  </div>
                  <Switch checked={syncHeartRate} onCheckedChange={setSyncHeartRate} />
                </div>

                <div className="flex items-center justify-between p-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-purple-100 flex items-center justify-center">
                      <Moon size={18} className="text-purple-600" strokeWidth={1.5} />
                    </div>
                    <div>
                      <div className="text-gray-900 font-medium text-sm">Sleep Data</div>
                      <div className="text-gray-500 text-xs">Import sleep stages & quality</div>
                    </div>
                  </div>
                  <Switch checked={syncSleep} onCheckedChange={setSyncSleep} />
                </div>

                <div className="flex items-center justify-between p-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-blue-100 flex items-center justify-center">
                      <Activity size={18} className="text-blue-600" strokeWidth={1.5} />
                    </div>
                    <div>
                      <div className="text-gray-900 font-medium text-sm">Activity & Steps</div>
                      <div className="text-gray-500 text-xs">Daily movement tracking</div>
                    </div>
                  </div>
                  <Switch checked={syncActivity} onCheckedChange={setSyncActivity} />
                </div>
              </div>
            </div>
          )}

          {/* Privacy Notice */}
          <div className="wellness-card p-5 bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-100">
            <h4 className="text-gray-900 font-semibold text-sm mb-2">🔒 Privacy & Permissions</h4>
            <p className="text-gray-700 text-sm leading-relaxed mb-3">
              We only access the health data you explicitly permit. All data is encrypted and never shared with third parties.
            </p>
            <button className="text-blue-600 text-xs font-semibold flex items-center gap-1">
              Learn more about our privacy policy
              <ChevronRight size={14} strokeWidth={1.5} />
            </button>
          </div>

          {/* Benefits */}
          <div className="wellness-card p-5">
            <h4 className="text-gray-900 font-semibold text-base mb-3">Why Connect Devices?</h4>
            <ul className="space-y-2 text-sm text-gray-700">
              <li className="flex items-start gap-2">
                <Check size={16} className="text-green-600 mt-0.5 flex-shrink-0" strokeWidth={1.5} />
                <span>Automatic tracking of your wellness metrics</span>
              </li>
              <li className="flex items-start gap-2">
                <Check size={16} className="text-green-600 mt-0.5 flex-shrink-0" strokeWidth={1.5} />
                <span>Personalized insights based on your data</span>
              </li>
              <li className="flex items-start gap-2">
                <Check size={16} className="text-green-600 mt-0.5 flex-shrink-0" strokeWidth={1.5} />
                <span>Better sleep and recovery recommendations</span>
              </li>
              <li className="flex items-start gap-2">
                <Check size={16} className="text-green-600 mt-0.5 flex-shrink-0" strokeWidth={1.5} />
                <span>Comprehensive health dashboard in one place</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
