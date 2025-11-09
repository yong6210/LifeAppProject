import { useState } from "react";
import { X, Smile, Meh, Frown, CheckCircle } from "lucide-react";
import { Session } from "../types/session";

interface SessionJournalProps {
  isOpen: boolean;
  onClose: () => void;
  session: Session;
  onSave: (notes: string, mood: string, effectiveness: number) => void;
}

const moods = [
  { value: "great", label: "Great", icon: Smile, color: "#10B981" },
  { value: "good", label: "Good", icon: Smile, color: "#3B82F6" },
  { value: "okay", label: "Okay", icon: Meh, color: "#F59E0B" },
  { value: "low", label: "Low", icon: Frown, color: "#EF4444" },
];

export function SessionJournal({ isOpen, onClose, session, onSave }: SessionJournalProps) {
  const [notes, setNotes] = useState("");
  const [selectedMood, setSelectedMood] = useState("good");
  const [effectiveness, setEffectiveness] = useState(3);

  if (!isOpen) return null;

  const handleSave = () => {
    onSave(notes, selectedMood, effectiveness);
  };

  const handleSkip = () => {
    onSave("", "good", 3);
  };

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-end sm:items-center justify-center">
      <div className="bg-white rounded-t-3xl sm:rounded-2xl w-full max-w-[430px] max-h-[85vh] overflow-hidden shadow-2xl">
        {/* Header */}
        <div className="px-5 py-4 border-b border-gray-200 flex items-center justify-between">
          <div>
            <h3 className="text-gray-900 font-semibold text-lg">Session Complete! 🎉</h3>
            <p className="text-gray-500 text-sm">How did it go?</p>
          </div>
          <button
            onClick={onClose}
            className="w-9 h-9 rounded-lg hover:bg-gray-100 flex items-center justify-center transition-colors"
          >
            <X size={20} className="text-gray-500" strokeWidth={1.5} />
          </button>
        </div>

        {/* Content */}
        <div className="px-5 py-6 overflow-y-auto max-h-[calc(85vh-140px)]">
          {/* Session Summary */}
          <div className="wellness-card p-4 mb-6 bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-blue-200 flex items-center justify-center">
                <CheckCircle size={20} className="text-blue-600" strokeWidth={1.5} />
              </div>
              <div>
                <div className="text-gray-900 font-semibold">{session.presetName}</div>
                <div className="text-gray-600 text-sm">{session.duration} minutes completed</div>
              </div>
            </div>
          </div>

          {/* Mood Selection */}
          <div className="mb-6">
            <label className="block text-gray-900 font-semibold text-sm mb-3">
              How do you feel?
            </label>
            <div className="grid grid-cols-4 gap-2">
              {moods.map((mood) => {
                const Icon = mood.icon;
                const isSelected = selectedMood === mood.value;
                return (
                  <button
                    key={mood.value}
                    onClick={() => setSelectedMood(mood.value)}
                    className={`wellness-card p-3 flex flex-col items-center gap-2 transition-all ${
                      isSelected ? "ring-2" : ""
                    }`}
                    style={{
                      ringColor: isSelected ? mood.color : "transparent",
                      backgroundColor: isSelected ? `${mood.color}10` : "#ffffff",
                    }}
                  >
                    <Icon 
                      size={24} 
                      style={{ color: isSelected ? mood.color : "#9CA3AF" }} 
                      strokeWidth={1.5}
                    />
                    <span 
                      className="text-xs font-medium"
                      style={{ color: isSelected ? mood.color : "#6B7280" }}
                    >
                      {mood.label}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Effectiveness Rating */}
          <div className="mb-6">
            <label className="block text-gray-900 font-semibold text-sm mb-3">
              Session Effectiveness
            </label>
            <div className="flex gap-2">
              {[1, 2, 3, 4, 5].map((rating) => (
                <button
                  key={rating}
                  onClick={() => setEffectiveness(rating)}
                  className={`flex-1 h-10 rounded-lg border-2 transition-all ${
                    effectiveness >= rating
                      ? "bg-blue-500 border-blue-500"
                      : "bg-white border-gray-200 hover:border-gray-300"
                  }`}
                >
                  <span className={`font-semibold ${
                    effectiveness >= rating ? "text-white" : "text-gray-400"
                  }`}>
                    {rating}
                  </span>
                </button>
              ))}
            </div>
            <div className="flex justify-between mt-2">
              <span className="text-xs text-gray-500">Not Effective</span>
              <span className="text-xs text-gray-500">Very Effective</span>
            </div>
          </div>

          {/* Notes */}
          <div className="mb-6">
            <label className="block text-gray-900 font-semibold text-sm mb-3">
              Notes (Optional)
            </label>
            <textarea
              className="w-full bg-gray-50 border border-gray-200 rounded-xl p-4 text-gray-900 placeholder:text-gray-400 resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
              rows={4}
              placeholder="What went well? Any challenges?"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
          </div>
        </div>

        {/* Footer */}
        <div className="px-5 py-4 border-t border-gray-200 flex gap-3">
          <button
            onClick={handleSkip}
            className="flex-1 btn-secondary h-12 rounded-xl"
          >
            Skip
          </button>
          <button
            onClick={handleSave}
            className="flex-1 btn-primary h-12 rounded-xl"
          >
            Save
          </button>
        </div>
      </div>
    </div>
  );
}
