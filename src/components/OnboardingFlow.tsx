import { useState } from "react";
import { ChevronRight, Bell, Heart, Mic, Clock, Sparkles } from "lucide-react";
import { Button } from "./ui/button";
import { motion, AnimatePresence } from "motion/react";

interface OnboardingFlowProps {
  isOpen: boolean;
  onComplete: () => void;
}

const steps = [
  {
    id: "welcome",
    title: "Welcome to Life",
    description: "Your personal wellness companion for better focus, fitness, and sleep",
    icon: "✨",
    gradient: "from-[#7C3AED] to-[#10B981]",
  },
  {
    id: "focus",
    title: "Stay Focused",
    description: "Use Pomodoro timers and focus sessions to boost productivity",
    icon: "⏱️",
    gradient: "from-[#6B7FFF] to-[#4FC3F7]",
  },
  {
    id: "workout",
    title: "Move Your Body",
    description: "Quick workouts and exercises to keep you energized throughout the day",
    icon: "💪",
    gradient: "from-[#3FE0A0] to-[#10B981]",
  },
  {
    id: "sleep",
    title: "Sleep Better",
    description: "Calming sounds and sleep tracking to improve your rest quality",
    icon: "🌙",
    gradient: "from-[#4FC3F7] to-[#7C3AED]",
  },
];

const permissions = [
  {
    id: "notifications",
    icon: Bell,
    title: "Notifications",
    description: "Get reminders for focus sessions and sleep schedule",
    required: false,
  },
  {
    id: "health",
    icon: Heart,
    title: "Health Data",
    description: "Connect wearables for more accurate insights",
    required: false,
  },
  {
    id: "microphone",
    icon: Mic,
    title: "Microphone",
    description: "Analyze sleep sounds (recordings stay on your device)",
    required: false,
  },
];

export function OnboardingFlow({ isOpen, onComplete }: OnboardingFlowProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [isPermissionStep, setIsPermissionStep] = useState(false);
  const [grantedPermissions, setGrantedPermissions] = useState<string[]>([]);

  const isLastStep = currentStep === steps.length - 1;

  const handleNext = () => {
    if (isLastStep && !isPermissionStep) {
      setIsPermissionStep(true);
    } else if (isPermissionStep) {
      onComplete();
    } else {
      setCurrentStep(currentStep + 1);
    }
  };

  const handleSkip = () => {
    onComplete();
  };

  const togglePermission = (permissionId: string) => {
    if (grantedPermissions.includes(permissionId)) {
      setGrantedPermissions(grantedPermissions.filter(id => id !== permissionId));
    } else {
      setGrantedPermissions([...grantedPermissions, permissionId]);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 bg-gradient-to-br from-[#1e293b] via-[#334155] to-[#1e293b] z-50 flex items-center justify-center"
        >
          <div className="w-full max-w-md px-6">
            {!isPermissionStep ? (
              // Feature Steps
              <motion.div
                key={currentStep}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                className="text-center"
              >
                {/* Skip Button */}
                <div className="flex justify-end mb-8">
                  <Button
                    variant="ghost"
                    className="text-white/60 hover:text-white"
                    onClick={handleSkip}
                  >
                    Skip
                  </Button>
                </div>

                {/* Icon */}
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ delay: 0.2, type: "spring" }}
                  className={`w-32 h-32 mx-auto mb-8 rounded-3xl bg-gradient-to-br ${steps[currentStep].gradient} flex items-center justify-center shadow-2xl`}
                >
                  <span className="text-7xl">{steps[currentStep].icon}</span>
                </motion.div>

                {/* Content */}
                <h2 className="text-white text-3xl mb-4">
                  {steps[currentStep].title}
                </h2>
                <p className="text-white/70 text-lg leading-relaxed mb-12">
                  {steps[currentStep].description}
                </p>

                {/* Progress Dots */}
                <div className="flex justify-center gap-2 mb-8">
                  {steps.map((_, index) => (
                    <div
                      key={index}
                      className={`h-2 rounded-full transition-all ${
                        index === currentStep
                          ? "w-8 bg-gradient-to-r from-[#7C3AED] to-[#10B981]"
                          : "w-2 bg-white/20"
                      }`}
                    />
                  ))}
                </div>

                {/* Next Button */}
                <Button
                  className="w-full rounded-2xl h-14 text-lg bg-gradient-to-r from-[#7C3AED] to-[#10B981] text-white hover:opacity-90"
                  onClick={handleNext}
                >
                  {isLastStep ? "Continue" : "Next"}
                  <ChevronRight size={20} className="ml-2" />
                </Button>
              </motion.div>
            ) : (
              // Permission Step
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-center"
              >
                {/* Icon */}
                <div className="w-20 h-20 mx-auto mb-6 rounded-3xl bg-gradient-to-br from-[#6B7FFF]/20 to-[#4FC3F7]/20 flex items-center justify-center">
                  <Sparkles size={36} className="text-[#6B7FFF]" />
                </div>

                {/* Content */}
                <h2 className="text-white text-2xl mb-3">
                  Customize Your Experience
                </h2>
                <p className="text-white/70 mb-8">
                  Grant permissions to unlock the full potential of Life. You can change these anytime in settings.
                </p>

                {/* Permissions */}
                <div className="space-y-3 mb-8">
                  {permissions.map((permission) => {
                    const Icon = permission.icon;
                    const isGranted = grantedPermissions.includes(permission.id);
                    return (
                      <motion.button
                        key={permission.id}
                        whileTap={{ scale: 0.98 }}
                        onClick={() => togglePermission(permission.id)}
                        className={`w-full glass-panel rounded-2xl p-4 text-left transition-all ${
                          isGranted ? "ring-2 ring-[#10B981]" : ""
                        }`}
                      >
                        <div className="flex items-center gap-4">
                          <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                            isGranted ? "bg-[#10B981]/20" : "bg-white/10"
                          }`}>
                            <Icon size={20} className={isGranted ? "text-[#10B981]" : "text-white/60"} />
                          </div>
                          <div className="flex-1">
                            <div className="text-white mb-1 flex items-center gap-2">
                              {permission.title}
                              {permission.required && (
                                <span className="text-xs text-white/40">(Required)</span>
                              )}
                            </div>
                            <div className="text-white/50 text-sm">{permission.description}</div>
                          </div>
                          <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center ${
                            isGranted ? "border-[#10B981] bg-[#10B981]" : "border-white/30"
                          }`}>
                            {isGranted && (
                              <motion.div
                                initial={{ scale: 0 }}
                                animate={{ scale: 1 }}
                              >
                                <ChevronRight size={14} className="text-white" />
                              </motion.div>
                            )}
                          </div>
                        </div>
                      </motion.button>
                    );
                  })}
                </div>

                {/* Privacy Note */}
                <div className="glass-panel rounded-2xl p-4 mb-8 bg-gradient-to-br from-[#6B7FFF]/10 via-transparent to-[#6B7FFF]/5 border-[#6B7FFF]/20">
                  <p className="text-white/60 text-sm leading-relaxed">
                    🔒 <strong className="text-white">Privacy first:</strong> All data is encrypted and stored securely. Recordings never leave your device. You're in control.
                  </p>
                </div>

                {/* Actions */}
                <div className="space-y-3">
                  <Button
                    className="w-full rounded-2xl h-14 text-lg bg-gradient-to-r from-[#7C3AED] to-[#10B981] text-white hover:opacity-90"
                    onClick={handleNext}
                  >
                    Get Started
                  </Button>
                  <Button
                    variant="ghost"
                    className="w-full text-white/60 hover:text-white"
                    onClick={handleSkip}
                  >
                    I'll do this later
                  </Button>
                </div>
              </motion.div>
            )}
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
