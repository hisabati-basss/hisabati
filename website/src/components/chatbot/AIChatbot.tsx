"use client";

import React, { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { MessageCircle, X, Mic, Send, Bot } from "lucide-react";
import { useLanguage } from "@/context/LanguageContext";
import { generateAIResponse, getWelcomeMessage, Language } from "./ChatBotEngine";

interface Message {
  id: string;
  text: string;
  sender: "user" | "ai";
}

export const AIChatbot = () => {
  const { language } = useLanguage();
  const lang = (language === "ar" ? "ar" : "en") as Language;
  
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState("");
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [isListening, setIsListening] = useState(false);
  const [hasWelcomed, setHasWelcomed] = useState(false);
  
  const messagesEndRef = useRef<HTMLDivElement>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const recognitionRef = useRef<any>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const speak = (text: string) => {
    if (!("speechSynthesis" in window)) return;
    
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    
    const voices = window.speechSynthesis.getVoices();
    if (lang === "ar") {
      utterance.lang = "ar-SA";
      const arVoice = voices.find(v => v.lang.includes("ar"));
      if (arVoice) utterance.voice = arVoice;
    } else {
      utterance.lang = "en-US";
      const enVoice = voices.find(v => v.lang.includes("en"));
      if (enVoice) utterance.voice = enVoice;
    }

    utterance.onstart = () => setIsSpeaking(true);
    utterance.onend = () => setIsSpeaking(false);
    utterance.onerror = () => setIsSpeaking(false);

    window.speechSynthesis.speak(utterance);
  };

  const handleUserMessage = (text: string) => {
    if (!text.trim()) return;
    
    const newUserMsg: Message = { id: Date.now().toString(), text, sender: "user" };
    setMessages(prev => [...prev, newUserMsg]);
    setInputValue("");
    
    if ("speechSynthesis" in window) window.speechSynthesis.cancel();

    setTimeout(() => {
      const responseText = generateAIResponse(text, lang);
      setMessages(prev => [...prev, { id: Date.now().toString(), text: responseText, sender: "ai" }]);
      speak(responseText);
    }, 600);
  };

  // Initialize Speech Recognition
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

  // Welcome message on load
  useEffect(() => {
    if (!hasWelcomed) {
      const timer = setTimeout(() => {
        setIsOpen(true);
        const welcomeTxt = getWelcomeMessage(lang);
        setMessages([{ id: Date.now().toString(), text: welcomeTxt, sender: "ai" }]);
        speak(welcomeTxt);
        setHasWelcomed(true);
      }, 3000); // 3 seconds after load
      return () => clearTimeout(timer);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hasWelcomed, lang]);


  const toggleListen = () => {
    if (isListening) {
      recognitionRef.current?.stop();
      setIsListening(false);
    } else {
      recognitionRef.current.lang = lang === "ar" ? "ar-SA" : "en-US";
      recognitionRef.current?.start();
      setIsListening(true);
    }
  };

  return (
    <div className={`fixed bottom-6 ${lang === "ar" ? "left-6" : "right-6"} z-50 flex flex-col items-end`}>
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 20, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.9 }}
            transition={{ type: "spring", stiffness: 200, damping: 20 }}
            className="w-80 sm:w-96 mb-4 bg-white/40 dark:bg-black/40 backdrop-blur-2xl border border-white/20 dark:border-white/10 shadow-2xl rounded-3xl overflow-hidden flex flex-col"
            style={{ height: "450px" }}
          >
            {/* Header */}
            <div className="bg-brand/90 backdrop-blur-md p-4 flex justify-between items-center text-white">
              <div className="flex items-center gap-3">
                <div className="relative w-10 h-10 flex items-center justify-center bg-white/20 rounded-full">
                  <Bot className="w-6 h-6 text-white" />
                  {isSpeaking && (
                    <motion.div
                      className="absolute inset-0 border-2 border-white rounded-full"
                      animate={{ scale: [1, 1.5, 1], opacity: [1, 0, 1] }}
                      transition={{ duration: 1, repeat: Infinity }}
                    />
                  )}
                </div>
                <div>
                  <h3 className="font-bold">{lang === "ar" ? "المساعد الذكي" : "AI Assistant"}</h3>
                  <p className="text-xs text-white/80">{lang === "ar" ? "يعمل داخلياً لخصوصيتك" : "Running locally for privacy"}</p>
                </div>
              </div>
              <button onClick={() => setIsOpen(false)} className="p-2 hover:bg-white/20 rounded-full transition">
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Visualizer (when speaking) */}
            <AnimatePresence>
              {isSpeaking && (
                <motion.div 
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 40, opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  className="w-full flex justify-center items-center gap-1 bg-brand/10 dark:bg-brand/5 overflow-hidden"
                >
                  {[...Array(5)].map((_, i) => (
                    <motion.div
                      key={i}
                      className="w-2 bg-brand rounded-full"
                      animate={{ height: ["10px", "30px", "10px"] }}
                      transition={{ duration: 0.5, repeat: Infinity, delay: i * 0.1 }}
                    />
                  ))}
                </motion.div>
              )}
            </AnimatePresence>

            {/* Chat Area */}
            <div className="flex-1 p-4 overflow-y-auto flex flex-col gap-3 custom-scrollbar" dir={lang === "ar" ? "rtl" : "ltr"}>
              {messages.map((msg) => (
                <div key={msg.id} className={`flex ${msg.sender === "user" ? "justify-end" : "justify-start"}`}>
                  <div className={`max-w-[85%] p-3 rounded-2xl text-sm ${msg.sender === "user" ? "bg-brand text-white rounded-tr-sm" : "bg-white/60 dark:bg-neutral-800/60 backdrop-blur-md border border-white/20 dark:border-white/5 rounded-tl-sm"}`}>
                    {msg.text}
                  </div>
                </div>
              ))}
              <div ref={messagesEndRef} />
            </div>

            {/* Input Area */}
            <div className="p-3 border-t border-black/5 dark:border-white/5 bg-white/30 dark:bg-black/30 backdrop-blur-md" dir={lang === "ar" ? "rtl" : "ltr"}>
              <div className="flex items-center gap-2 bg-white/50 dark:bg-neutral-900/50 rounded-full p-1 border border-black/5 dark:border-white/5">
                <button
                  onClick={toggleListen}
                  className={`p-2 rounded-full transition-colors ${isListening ? "bg-red-500 text-white animate-pulse" : "hover:bg-black/5 dark:hover:bg-white/5 text-foreground/70"}`}
                >
                  <Mic className="w-5 h-5" />
                </button>
                <input
                  type="text"
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && handleUserMessage(inputValue)}
                  placeholder={lang === "ar" ? "اكتب رسالتك..." : "Type your message..."}
                  className="flex-1 bg-transparent border-none outline-none text-sm px-2"
                />
                <button
                  onClick={() => handleUserMessage(inputValue)}
                  className="p-2 bg-brand hover:bg-brand-hover text-white rounded-full transition-transform hover:scale-105"
                >
                  <Send className={`w-4 h-4 ${lang === "ar" ? "rotate-180" : ""}`} />
                </button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Floating Button Capsule */}
      <AnimatePresence>
        {!isOpen && (
          <motion.button
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            exit={{ scale: 0 }}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => setIsOpen(true)}
            className="group relative flex items-center gap-3 bg-white/40 dark:bg-black/40 backdrop-blur-2xl border border-white/20 dark:border-white/10 shadow-[0_8px_32px_rgba(0,0,0,0.12)] p-3 pr-5 rounded-full overflow-hidden"
            dir={lang === "ar" ? "rtl" : "ltr"}
          >
            {/* Pulse Effect */}
            <div className="absolute inset-0 bg-brand/20 rounded-full animate-ping opacity-75" />
            
            <div className="relative bg-brand text-white p-3 rounded-full shadow-lg z-10">
              <MessageCircle className="w-6 h-6" />
            </div>
            <span className="font-bold text-sm text-foreground/90 z-10 hidden sm:block">
              {lang === "ar" ? "تحدث مع الذكاء الاصطناعي" : "Chat with AI"}
            </span>
          </motion.button>
        )}
      </AnimatePresence>
    </div>
  );
};
