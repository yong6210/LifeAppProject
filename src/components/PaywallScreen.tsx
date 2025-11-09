import { useState } from "react";
import { X, Check, Sparkles, TrendingUp, CloudUpload, Palette, ChevronDown, ChevronUp } from "lucide-react";
import { Button } from "./ui/button";
import { motion, AnimatePresence } from "motion/react";
import { toast } from "sonner@2.0.3";

interface PaywallScreenProps {
  isOpen: boolean;
  onClose: () => void;
  onSubscribe?: (plan: "monthly" | "yearly") => void;
}

const features = [
  { icon: TrendingUp, title: "Advanced Analytics", description: "Deep insights into your habits & patterns" },
  { icon: CloudUpload, title: "Auto Backup", description: "Automatic daily cloud backups" },
  { icon: Palette, title: "Premium Themes", description: "Exclusive color schemes & customization" },
  { icon: Sparkles, title: "Sleep Analysis", description: "AI-powered sound & quality tracking" },
];

const faqs = [
  { 
    question: "Can I cancel anytime?", 
    answer: "Yes! You can cancel your subscription at any time. Your premium features will remain active until the end of your billing period." 
  },
  { 
    question: "What's included in the free trial?", 
    answer: "Get full access to all premium features for 7 days. No credit card required. Cancel anytime before the trial ends." 
  },
  { 
    question: "Do you offer refunds?", 
    answer: "If you're not satisfied within the first 14 days, contact us for a full refund. We want you to love Life!" 
  },
  { 
    question: "Can I switch plans?", 
    answer: "Absolutely! You can upgrade or downgrade between monthly and yearly plans at any time." 
  },
];

export function PaywallScreen({ isOpen, onClose, onSubscribe }: PaywallScreenProps) {
  const [selectedPlan, setSelectedPlan] = useState<"monthly" | "yearly">("yearly");
  const [expandedFaq, setExpandedFaq] = useState<number | null>(null);

  const handleSubscribe = () => {
    if (onSubscribe) {
      onSubscribe(selectedPlan);
    }
    toast.success("Welcome to Premium! 🎉", {
      description: "Your 7-day free trial has started",
    });
    onClose();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/80 backdrop-blur-md z-50"
            onClick={onClose}
          />

          {/* Modal */}
          <motion.div
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 50 }}
            className="fixed inset-0 z-50 overflow-y-auto"
          >
            <div className="min-h-full flex items-end sm:items-center justify-center p-0 sm:p-4">
              <div className="w-full max-w-lg bg-gradient-to-br from-[#1e293b] via-[#334155] to-[#1e293b] sm:rounded-3xl overflow-hidden">
                {/* Close Button */}
                <div className="absolute top-4 right-4 z-10">
                  <Button
                    variant="ghost"
                    size="icon"
                    className="rounded-full bg-black/40 text-white hover:bg-black/60"
                    onClick={onClose}
                  >
                    <X size={20} />
                  </Button>
                </div>

                {/* Hero Section */}
                <div className="relative px-6 pt-12 pb-8 text-center overflow-hidden">
                  <div className="absolute inset-0 bg-gradient-to-br from-[#7C3AED]/30 to-[#10B981]/20 opacity-50" />
                  <div className="absolute top-10 right-10 w-40 h-40 bg-[#7C3AED]/30 rounded-full blur-3xl" />
                  <div className="absolute bottom-10 left-10 w-40 h-40 bg-[#10B981]/20 rounded-full blur-3xl" />
                  
                  <div className="relative z-10">
                    <div className="w-20 h-20 mx-auto mb-4 rounded-3xl bg-gradient-to-br from-[#7C3AED] to-[#10B981] flex items-center justify-center shadow-2xl">
                      <Sparkles size={36} className="text-white" />
                    </div>
                    <h2 className="text-white text-3xl mb-3">
                      Unlock Your Full Potential
                    </h2>
                    <p className="text-white/70 text-sm max-w-sm mx-auto">
                      Get advanced insights, automatic backups, and premium features to supercharge your wellness journey
                    </p>
                  </div>
                </div>

                {/* Features */}
                <div className="px-6 pb-6">
                  <div className="grid grid-cols-2 gap-3 mb-6">
                    {features.map((feature, index) => {
                      const Icon = feature.icon;
                      return (
                        <motion.div
                          key={index}
                          initial={{ opacity: 0, y: 20 }}
                          animate={{ opacity: 1, y: 0 }}
                          transition={{ delay: index * 0.1 }}
                          className="glass-panel rounded-2xl p-4"
                        >
                          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#7C3AED]/20 to-[#10B981]/20 flex items-center justify-center mb-3">
                            <Icon size={20} className="text-white" />
                          </div>
                          <h3 className="text-white text-sm mb-1">{feature.title}</h3>
                          <p className="text-white/50 text-xs leading-tight">{feature.description}</p>
                        </motion.div>
                      );
                    })}
                  </div>

                  {/* Plan Selection */}
                  <div className="space-y-3 mb-6">
                    <motion.button
                      whileTap={{ scale: 0.98 }}
                      onClick={() => setSelectedPlan("yearly")}
                      className={`w-full glass-panel rounded-2xl p-4 text-left transition-all relative overflow-hidden ${
                        selectedPlan === "yearly" ? "ring-2 ring-[#10B981]" : ""
                      }`}
                    >
                      {selectedPlan === "yearly" && (
                        <div className="absolute top-3 right-3 px-2 py-1 rounded-full bg-[#10B981] text-white text-xs">
                          Save 40%
                        </div>
                      )}
                      <div className="flex items-center gap-3 mb-2">
                        <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                          selectedPlan === "yearly" ? "border-[#10B981] bg-[#10B981]" : "border-white/30"
                        }`}>
                          {selectedPlan === "yearly" && <Check size={14} className="text-white" />}
                        </div>
                        <div className="flex-1">
                          <div className="text-white mb-1">Yearly Plan</div>
                          <div className="text-white/50 text-xs">$5.99/month • Billed annually</div>
                        </div>
                        <div className="text-white text-xl">$71.88</div>
                      </div>
                    </motion.button>

                    <motion.button
                      whileTap={{ scale: 0.98 }}
                      onClick={() => setSelectedPlan("monthly")}
                      className={`w-full glass-panel rounded-2xl p-4 text-left transition-all ${
                        selectedPlan === "monthly" ? "ring-2 ring-[#10B981]" : ""
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                          selectedPlan === "monthly" ? "border-[#10B981] bg-[#10B981]" : "border-white/30"
                        }`}>
                          {selectedPlan === "monthly" && <Check size={14} className="text-white" />}
                        </div>
                        <div className="flex-1">
                          <div className="text-white mb-1">Monthly Plan</div>
                          <div className="text-white/50 text-xs">Billed monthly</div>
                        </div>
                        <div className="text-white text-xl">$9.99</div>
                      </div>
                    </motion.button>
                  </div>

                  {/* CTA */}
                  <Button
                    className="w-full rounded-2xl h-14 text-lg bg-gradient-to-r from-[#7C3AED] to-[#10B981] text-white hover:opacity-90 shadow-xl mb-3"
                    onClick={handleSubscribe}
                  >
                    Start 7-Day Free Trial
                  </Button>
                  <p className="text-center text-white/40 text-xs mb-6">
                    Cancel anytime. No credit card required.
                  </p>

                  {/* FAQs */}
                  <div>
                    <h3 className="text-white mb-3 text-sm">Frequently Asked Questions</h3>
                    <div className="space-y-2">
                      {faqs.map((faq, index) => {
                        const isExpanded = expandedFaq === index;
                        return (
                          <div key={index} className="glass-panel rounded-2xl overflow-hidden">
                            <button
                              onClick={() => setExpandedFaq(isExpanded ? null : index)}
                              className="w-full px-4 py-3 flex items-center justify-between text-left"
                            >
                              <span className="text-white text-sm">{faq.question}</span>
                              {isExpanded ? (
                                <ChevronUp size={16} className="text-white/60" />
                              ) : (
                                <ChevronDown size={16} className="text-white/60" />
                              )}
                            </button>
                            <AnimatePresence>
                              {isExpanded && (
                                <motion.div
                                  initial={{ height: 0, opacity: 0 }}
                                  animate={{ height: "auto", opacity: 1 }}
                                  exit={{ height: 0, opacity: 0 }}
                                  className="overflow-hidden"
                                >
                                  <div className="px-4 pb-3 text-white/60 text-sm leading-relaxed">
                                    {faq.answer}
                                  </div>
                                </motion.div>
                              )}
                            </AnimatePresence>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
