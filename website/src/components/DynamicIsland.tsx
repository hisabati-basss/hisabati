"use client";

import React, { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence, useScroll, useMotionValueEvent } from "framer-motion";
import { Mic, Bot, Settings2 } from "lucide-react";
import { useLanguage } from "@/context/LanguageContext";
import { generateAIResponse, getWelcomeMessage, Language } from "./chatbot/ChatBotEngine";

const TypingMessage = ({ text }: { text: string }) => {
  return (
    <motion.div
      initial="hidden"
      animate="visible"
      variants={{ visible: { transition: { staggerChildren: 0.15 } } }}
      className="inline-block text-sm md:text-base font-bold text-foreground tracking-wide text-center"
    >
      {text.split(" ").map((word, index) => (
        <motion.span
          key={index}
          variants={{ hidden: { opacity: 0, filter: "blur(4px)" }, visible: { opacity: 1, filter: "blur(0px)" } }}
          className="inline-block ml-1"
        >
          {word}
        </motion.span>
      ))}
    </motion.div>
  );
};

export const DynamicIsland = () => {
  const { language } = useLanguage();
  const lang = (language === "ar" ? "ar" : "en") as Language;

  const [currentAIResponse, setCurrentAIResponse] = useState("");
  const [inputValue, setInputValue] = useState("");
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [isListening, setIsListening] = useState(false);
  const [hasWelcomed, setHasWelcomed] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [selectedVoiceURI, setSelectedVoiceURI] = useState("");

  const { scrollY } = useScroll();
  const [isScrolled, setIsScrolled] = useState(false);

  useMotionValueEvent(scrollY, "change", (latest) => {
    setIsScrolled(latest > 100);
  });

  const [voices, setVoices] = useState<SpeechSynthesisVoice[]>([]);

  useEffect(() => {
    const savedVoice = localStorage.getItem("hisabati_voice_uri");
    if (savedVoice) setSelectedVoiceURI(savedVoice);

    const updateVoices = () => {
      setVoices(window.speechSynthesis.getVoices());
    };
    if (typeof window !== "undefined" && "speechSynthesis" in window) {
      updateVoices();
      window.speechSynthesis.onvoiceschanged = updateVoices;
    }
  }, []);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const recognitionRef = useRef<any>(null);

  const speak = (text: string) => {
    if (!("speechSynthesis" in window)) return;
    
    // Chrome bug: engine gets stuck. We must resume then cancel.
    window.speechSynthesis.resume();
    window.speechSynthesis.cancel();

    // Chrome bug: calling speak() immediately after cancel() throws an empty Error.
    // We must wait a tiny bit before creating and speaking the new utterance.
    setTimeout(() => {
      const utterance = new SpeechSynthesisUtterance(text);
      const availableVoices = voices.length > 0 ? voices : window.speechSynthesis.getVoices();
      
      let selectedVoice = null;
      if (selectedVoiceURI) {
        selectedVoice = availableVoices.find(v => v.voiceURI === selectedVoiceURI);
      }

      if (!selectedVoice) {
        if (lang === "ar") {
          utterance.lang = "ar-SA";
          selectedVoice = availableVoices.find(v => v.lang.includes("ar") && (v.name.toLowerCase().includes("natural") || v.name.toLowerCase().includes("online")));
          if (!selectedVoice) selectedVoice = availableVoices.find(v => v.lang.includes("ar") && v.name.toLowerCase().includes("google"));
          if (!selectedVoice) selectedVoice = availableVoices.find(v => v.lang === "ar-SA" || v.lang === "ar-EG" || v.lang === "ar-AE");
          if (!selectedVoice) selectedVoice = availableVoices.find(v => v.lang.includes("ar"));
        } else {
          utterance.lang = "en-US";
          selectedVoice = availableVoices.find(v => v.lang.includes("en") && (v.name.toLowerCase().includes("natural") || v.name.toLowerCase().includes("online")));
          if (!selectedVoice) selectedVoice = availableVoices.find(v => v.lang.includes("en") && v.name.toLowerCase().includes("google"));
          if (!selectedVoice) selectedVoice = availableVoices.find(v => v.lang.includes("en"));
        }
      }

      if (selectedVoice) {
        utterance.voice = selectedVoice;
        utterance.lang = selectedVoice.lang;
      }
      
      // Adjust pitch and rate to sound more human and professional
      utterance.pitch = 1.0; 
      utterance.rate = 1.0; 
      
      utterance.onstart = () => setIsSpeaking(true);
      utterance.onend = () => {
        setIsSpeaking(false);
        setTimeout(() => setCurrentAIResponse(""), 3000); // clear text after 3s
      };
      utterance.onerror = (e) => {
        console.error("SpeechSynthesis Error:", e);
        
        // Fallback: If Chrome rejected the specific voice, try the absolute basic native voice
        if (utterance.voice) {
          console.log("Retrying with default browser voice...");
          const fallbackUtterance = new SpeechSynthesisUtterance(text);
          fallbackUtterance.lang = lang === "ar" ? "ar-SA" : "en-US";
          fallbackUtterance.onstart = () => setIsSpeaking(true);
          fallbackUtterance.onend = () => {
            setIsSpeaking(false);
            setTimeout(() => setCurrentAIResponse(""), 3000);
          };
          fallbackUtterance.onerror = () => setIsSpeaking(false);
          window.speechSynthesis.speak(fallbackUtterance);
        } else {
          setIsSpeaking(false);
        }
      };
      
      window.speechSynthesis.speak(utterance);
    }, 100);
  };

  const handleUserMessage = (text: string) => {
    if (!text.trim()) return;
    if ("speechSynthesis" in window) window.speechSynthesis.cancel();
    setCurrentAIResponse(""); 
    setInputValue("");
    setTimeout(() => {
      const responseText = generateAIResponse(text, lang);
      setCurrentAIResponse(responseText);
      speak(responseText);
    }, 400);
  };

  useEffect(() => {
    if (typeof window !== "undefined") {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
      if (SpeechRecognition) {
        recognitionRef.current = new SpeechRecognition();
        recognitionRef.current.continuous = false;
        recognitionRef.current.interimResults = false;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        recognitionRef.current.onresult = (event: any) => {
          const transcript = event.results[0][0].transcript;
          handleUserMessage(transcript);
        };
        recognitionRef.current.onend = () => {
          setIsListening(false);
        };
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lang]);

  useEffect(() => {
    if (!hasWelcomed) {
      const timer = setTimeout(() => {
        const welcomeTxt = getWelcomeMessage(lang);
        setCurrentAIResponse(welcomeTxt);
        speak(welcomeTxt);
        setHasWelcomed(true);
      }, 1500); 
      return () => clearTimeout(timer);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hasWelcomed, lang]);

  const toggleListen = () => {
    if (isListening) {
      recognitionRef.current?.stop();
      setIsListening(false);
      setCurrentAIResponse("");
    } else {
      if ("speechSynthesis" in window) window.speechSynthesis.cancel();
      setIsSpeaking(false);
      setCurrentAIResponse(lang === "ar" ? "جاري الاستماع..." : "Listening...");
      recognitionRef.current.lang = lang === "ar" ? "ar-SA" : "en-US";
      recognitionRef.current?.start();
      setIsListening(true);
    }
  };

  // The capsule width is dynamic based on content.
  // When idle, it's small. When speaking, it's larger but remains a capsule.
  const isExpanded = currentAIResponse.length > 0;

  return (
    <div className={`w-full flex justify-center fixed z-[60] pointer-events-none transition-all duration-300 ${isScrolled ? "top-[110px]" : "top-6"}`}>
      <motion.div
        layout
        initial={false}
        animate={{
          width: isExpanded ? "auto" : "95%",
          maxWidth: isExpanded ? "90%" : "400px",
        }}
        transition={{ type: "spring", stiffness: 300, damping: 25 }}
        className="h-[60px] md:h-[70px] bg-white/30 dark:bg-neutral-900/60 backdrop-blur-xl backdrop-saturate-150 border border-black/5 dark:border-white/10 shadow-xl rounded-full overflow-hidden flex items-center justify-between px-3 pointer-events-auto"
        dir={lang === "ar" ? "rtl" : "ltr"}
      >
        {/* Robot Icon */}
        <div className="flex items-center gap-3 flex-shrink-0">
          <div className="w-10 h-10 md:w-12 md:h-12 rounded-full bg-brand/20 flex items-center justify-center relative">
            <Bot className="w-5 h-5 md:w-6 md:h-6 text-brand" />
            {isSpeaking && <div className="absolute inset-0 rounded-full border border-brand animate-ping" />}
          </div>
          
          {/* Interactive Area */}
          {!isExpanded && (
            <motion.div 
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              className="flex-1 px-2 md:px-3 flex items-center min-w-0 overflow-hidden"
            >
              {showSettings ? (
                <select 
                  className="w-full min-w-0 bg-transparent border-none outline-none text-xs md:text-sm font-bold text-foreground focus:ring-0 text-ellipsis overflow-hidden whitespace-nowrap"
                  value={selectedVoiceURI}
                  onChange={(e) => {
                    setSelectedVoiceURI(e.target.value);
                    localStorage.setItem("hisabati_voice_uri", e.target.value);
                    setShowSettings(false);
                    speak(lang === "ar" ? "تم تغيير الصوت بنجاح" : "Voice changed successfully");
                  }}
                >
                  <option value="" className="text-black dark:text-white bg-white dark:bg-neutral-900">{lang === "ar" ? "الصوت الافتراضي (تلقائي)" : "Default Voice"}</option>
                  {voices.filter(v => v.lang.includes(lang === "ar" ? "ar" : "en")).map(v => (
                    <option key={v.voiceURI} value={v.voiceURI} className="text-black dark:text-white bg-white dark:bg-neutral-900">
                      {v.name}
                    </option>
                  ))}
                </select>
              ) : (
                <input 
                  type="text"
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  onKeyDown={(e) => { if (e.key === "Enter") handleUserMessage(inputValue); }}
                  placeholder={lang === "ar" ? "اسأل المساعد الذكي..." : "Ask AI Assistant..."}
                  className="w-full min-w-0 bg-transparent border-none outline-none text-sm md:text-base font-bold text-foreground placeholder-foreground/60 tracking-wide text-ellipsis overflow-hidden whitespace-nowrap"
                />
              )}
            </motion.div>
          )}
        </div>

        {/* Dynamic Text Area */}
        <AnimatePresence mode="wait">
          {isExpanded && (
            <motion.div 
              key="typing"
              initial={{ opacity: 0, width: 0 }}
              animate={{ opacity: 1, width: "auto" }}
              exit={{ opacity: 0, width: 0 }}
              className="mx-4 overflow-hidden whitespace-nowrap"
            >
              <TypingMessage text={currentAIResponse} />
            </motion.div>
          )}
        </AnimatePresence>

        {/* Action Right Side (Settings / Mic / Wave) */}
        <div className="flex items-center gap-1 md:gap-2 flex-shrink-0 pl-2">
          {isSpeaking ? (
            <div className="flex items-center gap-1 px-2">
              {[...Array(4)].map((_, i) => (
                <motion.div key={i} className="w-1 bg-brand rounded-full" animate={{ height: ["4px", "16px", "4px"] }} transition={{ duration: 0.5, repeat: Infinity, delay: i * 0.1 }} />
              ))}
            </div>
          ) : (
            <>
              {!isExpanded && (
                <button 
                  onClick={() => setShowSettings(!showSettings)}
                  className={`p-2 rounded-full transition-all ${showSettings ? "bg-foreground/10 text-brand" : "hover:bg-foreground/5 text-foreground/50 hover:text-brand"}`}
                  title={lang === "ar" ? "تغيير الصوت" : "Change Voice"}
                >
                  <Settings2 className="w-4 h-4 md:w-5 md:h-5" />
                </button>
              )}
              <button 
                onClick={toggleListen}
                className={`p-2 md:p-3 rounded-full transition-all ${isListening ? "bg-red-500 text-white animate-pulse" : "hover:bg-foreground/5 text-brand"}`}
              >
                <Mic className="w-5 h-5 md:w-6 md:h-6" />
              </button>
            </>
          )}
        </div>
      </motion.div>
    </div>
  );
};
