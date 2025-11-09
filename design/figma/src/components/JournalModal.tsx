import { useState } from "react";
import { X, Smile, Meh, Frown, ThumbsUp, Heart, Zap } from "lucide-react";
import { Button } from "./ui/button";
import { Textarea } from "./ui/textarea";
import { motion, AnimatePresence } from "motion/react";

interface JournalModalProps {
  isOpen: boolean;
  onClose: () => void;
  sessionType: "focus" | "workout" | "sleep";
  duration: number;
  onSave: (mood: string, note: string) => void;
}

const moods = [
  { id: "great", icon: ThumbsUp, label: "Great", color: "#3FE0A0" },
  { id: "good", icon: Smile, label: "Good", color: "#6B7FFF" },
  { id: "okay", icon: Meh, label: "Okay", color: "#F59E0B" },
  { id: "tired", icon: Frown, label: "Tired", color: "#8B5CF6" },
  { id: "energized", icon: Zap, label: "Energized", color: "#10B981" },
  { id: "peaceful", icon: Heart, label: "Peaceful", color: "#4FC3F7" },
];

export function JournalModal({ isOpen, onClose, sessionType, duration, onSave }: JournalModalProps) {
  const [selectedMood, setSelectedMood] = useState<string | null>(null);
  const [note, setNote] = useState("");

  const handleSave = () => {
    if (selectedMood) {
      onSave(selectedMood, note);
      setSelectedMood(null);
      setNote("");
      onClose();
    }
  };

  const handleSkip = () => {
    setSelectedMood(null);
    setNote("");
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
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50"
            onClick={handleSkip}
          />

          {/* Modal */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            className="fixed inset-x-4 top-1/2 -translate-y-1/2 max-w-md mx-auto z-50"
          >
            <div className="glass-panel-solid rounded-3xl p-6 shadow-2xl">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h2 className="text-white text-xl mb-1">How was your session?</h2>
                  <p className="text-white/60 text-sm">{duration} min {sessionType} session</p>
                </div>
                <Button
                  variant="ghost"
                  size="icon"
                  className="text-white/60 hover:text-white hover:bg-white/10 rounded-xl"
                  onClick={handleSkip}
                >
                  <X size={20} />
                </Button>
              </div>

              {/* Mood Selection */}
              <div className="mb-6">
                <label className="text-white/80 text-sm mb-3 block">Select your mood</label>
                <div className="grid grid-cols-3 gap-3">
                  {moods.map((mood) => {
                    const Icon = mood.icon;
                    const isSelected = selectedMood === mood.id;
                    return (
                      <motion.button
                        key={mood.id}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => setSelectedMood(mood.id)}
                        className={`glass-panel rounded-2xl p-4 text-center transition-all ${
                          isSelected ? "ring-2" : ""
                        }`}
                        style={{
                          ringColor: isSelected ? mood.color : "transparent",
                          backgroundColor: isSelected
                            ? `${mood.color}15`
                            : undefined,
                        }}
                      >
                        <Icon
                          size={24}
                          className="mx-auto mb-2"
                          style={{ color: mood.color }}
                        />
                        <div className="text-white text-xs">{mood.label}</div>
                      </motion.button>
                    );
                  })}
                </div>
              </div>

              {/* Note */}
              <div className="mb-6">
                <label className="text-white/80 text-sm mb-2 block">
                  Add a note (optional)
                </label>
                <Textarea
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder="What did you accomplish? How do you feel?"
                  className="bg-white/10 border-white/20 text-white placeholder:text-white/40 rounded-2xl min-h-[100px] resize-none"
                  maxLength={500}
                />
                <div className="text-white/40 text-xs mt-2 text-right">
                  {note.length}/500
                </div>
              </div>

              {/* Actions */}
              <div className="flex gap-3">
                <Button
                  variant="ghost"
                  className="flex-1 rounded-xl h-12 text-white/80 hover:text-white hover:bg-white/10"
                  onClick={handleSkip}
                >
                  Skip
                </Button>
                <Button
                  className="flex-1 rounded-xl h-12 bg-gradient-to-r from-[#7C3AED] to-[#10B981] text-white hover:opacity-90"
                  onClick={handleSave}
                  disabled={!selectedMood}
                >
                  Save Journal
                </Button>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
