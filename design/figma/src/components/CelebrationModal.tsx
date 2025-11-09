import { motion, AnimatePresence } from "motion/react";
import { X, Trophy, Zap, Star } from "lucide-react";
import { Button } from "./ui/button";

interface CelebrationModalProps {
  isOpen: boolean;
  onClose: () => void;
  xpGained?: number;
  levelUp?: {
    oldLevel: number;
    newLevel: number;
  };
}

export function CelebrationModal({
  isOpen,
  onClose,
  xpGained = 0,
  levelUp,
}: CelebrationModalProps) {
  const isLevelUp = !!levelUp;

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50"
          />

          {/* Modal */}
          <div className="fixed inset-0 flex items-center justify-center z-50 p-6 pointer-events-none">
            <motion.div
              initial={{ scale: 0.8, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.8, opacity: 0, y: 20 }}
              transition={{ type: "spring", damping: 20, stiffness: 300 }}
              className="modern-card max-w-sm w-full p-8 text-center relative pointer-events-auto"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Close Button */}
              <button
                onClick={onClose}
                className="absolute top-4 right-4 w-8 h-8 rounded-lg bg-gray-100 hover:bg-gray-200 flex items-center justify-center transition-colors"
              >
                <X size={18} className="text-gray-600" strokeWidth={2} />
              </button>

              {/* Animated Icon */}
              <motion.div
                initial={{ scale: 0, rotate: -180 }}
                animate={{ scale: 1, rotate: 0 }}
                transition={{ type: "spring", delay: 0.2, damping: 15 }}
                className={`w-24 h-24 rounded-3xl mx-auto mb-6 flex items-center justify-center shadow-2xl ${
                  isLevelUp
                    ? "bg-gradient-to-br from-amber-400 to-amber-600"
                    : "bg-gradient-to-br from-blue-500 to-blue-600"
                }`}
              >
                {isLevelUp ? (
                  <Trophy size={48} className="text-white" strokeWidth={2} />
                ) : (
                  <Star size={48} className="text-white" strokeWidth={2} fill="white" />
                )}
              </motion.div>

              {/* Title */}
              <motion.h3
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
                className="text-gray-900 font-bold text-2xl mb-2"
              >
                {isLevelUp ? "Level Up!" : "Great Job!"}
              </motion.h3>

              {/* Message */}
              <motion.p
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                className="text-gray-600 mb-6"
              >
                {isLevelUp
                  ? `You've reached level ${levelUp.newLevel}!`
                  : "You completed a session!"}
              </motion.p>

              {/* XP Badge */}
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ type: "spring", delay: 0.5, damping: 15 }}
                className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-gradient-to-br from-amber-50 to-amber-100 border-2 border-amber-200 mb-6"
              >
                <Zap size={20} className="text-amber-600" strokeWidth={2} fill="currentColor" />
                <span className="text-amber-900 font-bold text-xl">+{xpGained} XP</span>
              </motion.div>

              {/* Action Button */}
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.6 }}
              >
                <Button
                  onClick={onClose}
                  className="w-full h-12 rounded-xl bg-gradient-to-br from-blue-500 to-blue-600 text-white font-semibold shadow-lg hover:shadow-xl transition-all"
                >
                  Continue
                </Button>
              </motion.div>

              {/* Confetti Effect */}
              {isLevelUp && (
                <div className="absolute inset-0 pointer-events-none overflow-hidden rounded-3xl">
                  {[...Array(20)].map((_, i) => (
                    <motion.div
                      key={i}
                      initial={{
                        x: "50%",
                        y: "50%",
                        scale: 0,
                        opacity: 1,
                      }}
                      animate={{
                        x: `${Math.random() * 100}%`,
                        y: `${Math.random() * 100}%`,
                        scale: [0, 1, 0],
                        opacity: [1, 1, 0],
                      }}
                      transition={{
                        duration: 1.5,
                        delay: 0.3 + Math.random() * 0.5,
                        ease: "easeOut",
                      }}
                      className="absolute w-2 h-2 rounded-full"
                      style={{
                        backgroundColor: ["#FCD34D", "#F59E0B", "#3B82F6", "#8B5CF6", "#10B981"][
                          i % 5
                        ],
                      }}
                    />
                  ))}
                </div>
              )}
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}
