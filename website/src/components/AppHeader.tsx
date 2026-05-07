"use client";

import React, { useState, useEffect, useRef } from "react";
import { useLanguage } from "@/context/LanguageContext";
import { useTheme } from "next-themes";
import { Moon, Sun, Globe, Menu, X, MessageCircle, Send, Mic, Bot } from "lucide-react";
import { motion, AnimatePresence, useScroll, useMotionValueEvent } from "framer-motion";
import { generateAIResponse, getWelcomeMessage, Language } from "./chatbot/ChatBotEngine";

interface Message {
  id: string;
  text: string;
  sender: "user" | "ai";
}

const SunMoonToggle = ({ theme }: { theme: string | undefined }) => {
  const [mounted, setMounted] = useState(false);
  // eslint-disable-next-line react-hooks/exhaustive-deps, react-hooks/set-state-in-effect
  useEffect(() => setMounted(true), []);
  if (!mounted) return <div className="w-5 h-5" />;
  return theme === "dark" ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />;
};

export const AppHeader = () => {
  const { t, toggleLanguage, language } = useLanguage();
  const { theme, setTheme } = useTheme();
  const lang = (language === "ar" ? "ar" : "en") as Language;

  const { scrollY } = useScroll();
  const [isScrolled, setIsScrolled] = useState(false);
  
  useMotionValueEvent(scrollY, "change", (latest) => {
    if (latest > 100) setIsScrolled(true);
    else setIsScrolled(false);
  });

  const [activeSection, setActiveSection] = useState<string>("");
  const [mobileOpen, setMobileOpen] = useState(false);
  const [chatOpen, setChatOpen] = useState(false); // For mini chat in navbar

  // Chatbot States
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
  }, [messages, isScrolled, chatOpen]);

  useEffect(() => {
    const handleScroll = () => {
      const sections = ["features", "solutions", "security", "affiliate", "pricing", "contact"];
      const spyPos = window.scrollY + window.innerHeight / 3;
      let current = "";
      for (const section of sections) {
        const el = document.getElementById(section);
        if (el && el.offsetTop <= spyPos) current = section;
      }
      setActiveSection(current);
    };
    window.addEventListener("scroll", handleScroll);
    handleScroll();
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const navLinks = [
    { id: "features", key: "nav.features" },
    { id: "solutions", key: "nav.solutions" },
    { id: "security", key: "nav.security" },
    { id: "pricing", key: "nav.pricing" },
    { id: "contact", key: "nav.contact" },
  ];

  const scrollTo = (id: string) => {
    if (window.location.pathname !== "/") {
      window.location.assign(`/#${id}`);
      return;
    }
    document.getElementById(id)?.scrollIntoView({ behavior: "smooth" });
    setMobileOpen(false);
  };

  const speak = (text: string) => {
    if (!("speechSynthesis" in window)) return;
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    
    const voices = window.speechSynthesis.getVoices();
    if (lang === "ar") {
      utterance.lang = "ar-SA";
      const arVoice = voices.find(v => v.lang.includes("ar") && (v.name.includes("Natural") || v.name.includes("Online")));
      if (arVoice) utterance.voice = arVoice;
      else {
        const fallback = voices.find(v => v.lang.includes("ar"));
        if (fallback) utterance.voice = fallback;
      }
    } else {
      utterance.lang = "en-US";
      const enVoice = voices.find(v => v.lang.includes("en") && v.name.includes("Natural"));
      if (enVoice) utterance.voice = enVoice;
      else {
        const fallback = voices.find(v => v.lang.includes("en"));
        if (fallback) utterance.voice = fallback;
      }
    }

    utterance.pitch = 1.1; 
    utterance.rate = 1.05; 

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
        setMessages([{ id: Date.now().toString(), text: welcomeTxt, sender: "ai" }]);
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
    } else {
      recognitionRef.current.lang = lang === "ar" ? "ar-SA" : "en-US";
      recognitionRef.current?.start();
      setIsListening(true);
    }
  };

  const ChatInterface = () => (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex flex-col h-full w-full">
      <div className="flex-1 p-6 overflow-y-auto flex flex-col gap-4 custom-scrollbar" dir={lang === "ar" ? "rtl" : "ltr"}>
        {messages.map((msg) => (
          <div key={msg.id} className={`flex ${msg.sender === "user" ? "justify-end" : "justify-start"}`}>
            <div className={`max-w-[85%] p-4 rounded-3xl text-sm md:text-base font-medium shadow-sm ${msg.sender === "user" ? "bg-brand text-white rounded-tr-sm" : "bg-white/80 dark:bg-neutral-800/80 backdrop-blur-xl border border-white/40 dark:border-white/10 rounded-tl-sm text-foreground"}`}>
              {msg.text}
            </div>
          </div>
        ))}
        {isSpeaking && (
          <div className="flex justify-start">
            <motion.div initial={{ width: 0 }} animate={{ width: 60 }} className="h-10 bg-white/60 dark:bg-neutral-800/60 backdrop-blur-xl border border-white/20 rounded-3xl rounded-tl-sm flex items-center justify-evenly px-2">
              {[...Array(4)].map((_, i) => (
                <motion.div key={i} className="w-1.5 bg-brand rounded-full" animate={{ height: ["4px", "20px", "4px"] }} transition={{ duration: 0.5, repeat: Infinity, delay: i * 0.1 }} />
              ))}
            </motion.div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>
      <div className="p-4 pt-0" dir={lang === "ar" ? "rtl" : "ltr"}>
        <div className="flex items-center gap-2 bg-white/60 dark:bg-neutral-900/60 backdrop-blur-xl shadow-inner rounded-full p-1.5 border border-black/5 dark:border-white/10">
          <button onClick={toggleListen} className={`p-3 rounded-full transition-all ${isListening ? "bg-red-500 text-white animate-pulse shadow-lg shadow-red-500/30" : "hover:bg-black/5 dark:hover:bg-white/5 text-foreground/70"}`}>
            <Mic className="w-5 h-5" />
          </button>
          <input type="text" value={inputValue} onChange={(e) => setInputValue(e.target.value)} onKeyDown={(e) => e.key === "Enter" && handleUserMessage(inputValue)} placeholder={lang === "ar" ? "اسألني عن حساباتي..." : "Ask me..."} className="flex-1 bg-transparent border-none outline-none text-base px-2 font-medium placeholder-foreground/40" />
          <button onClick={() => handleUserMessage(inputValue)} className="p-3 bg-brand hover:bg-brand-hover text-white rounded-full transition-transform hover:scale-105 shadow-lg shadow-brand/30">
            <Send className={`w-5 h-5 ${lang === "ar" ? "rotate-180" : ""}`} />
          </button>
        </div>
      </div>
    </motion.div>
  );

  return (
    <>
      {/* 
        This is the magic: We have a wrapper that has `position: sticky` when scrolled, 
        and `position: relative` when at the top, making it part of the normal document flow!
        But framer-motion `layout` handles the actual visual morphing smoothly.
      */}
      <div className={`flex justify-center w-full z-50 transition-all duration-300 ${isScrolled ? "fixed top-0" : "relative top-10 mb-20"}`}>
        <motion.nav
          layout
          initial={false}
          animate={{
            y: isScrolled ? 24 : 0,
            width: isScrolled ? (chatOpen ? "380px" : "95%") : "90%",
            maxWidth: isScrolled ? (chatOpen ? "380px" : "1152px") : "1000px",
            height: isScrolled ? (chatOpen ? "500px" : "80px") : "500px",
            borderRadius: isScrolled && !chatOpen ? "9999px" : "32px",
            x: isScrolled && chatOpen && lang === "ar" ? "-40vw" : (isScrolled && chatOpen && lang === "en" ? "40vw" : 0), 
          }}
          transition={{ type: "spring", stiffness: 200, damping: 25, mass: 1.2 }}
          className={`bg-white/40 dark:bg-neutral-900/60 backdrop-blur-3xl backdrop-saturate-200 border border-white/30 dark:border-white/10 shadow-[0_32px_64px_rgba(0,0,0,0.15)] dark:shadow-[0_32px_64px_rgba(0,0,0,0.4)] overflow-hidden flex flex-col pointer-events-auto`}
          style={{ transformOrigin: "top center" }}
        >
          <AnimatePresence mode="wait">
            {!isScrolled && (
              <motion.div key="large-hero" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.2 }} className="flex flex-col h-full w-full">
                <div className="flex items-center justify-between p-6 pb-2">
                  <div className="flex items-center gap-3">
                    <div className="relative w-12 h-12 flex items-center justify-center bg-gradient-to-br from-brand to-brand-hover rounded-2xl shadow-lg">
                      <Bot className="w-7 h-7 text-white" />
                    </div>
                    <div>
                      <h2 className="text-2xl font-black tracking-tight bg-gradient-to-r from-foreground to-foreground/70 bg-clip-text text-transparent">
                        {lang === "ar" ? "المساعد الذكي (Edge AI)" : "Hisabati Edge AI"}
                      </h2>
                      <p className="font-semibold text-brand text-sm">{lang === "ar" ? "يعمل محلياً لخصوصيتك" : "Local AI for absolute privacy"}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <button onClick={toggleLanguage} className="p-2 bg-white/20 hover:bg-white/40 dark:bg-black/20 rounded-full transition"><Globe className="w-5 h-5" /></button>
                    <button onClick={() => setTheme(theme === "dark" ? "light" : "dark")} className="p-2 bg-white/20 hover:bg-white/40 dark:bg-black/20 rounded-full transition"><SunMoonToggle theme={theme} /></button>
                  </div>
                </div>
                <ChatInterface />
              </motion.div>
            )}

            {isScrolled && (
              <motion.div key="scrolled-navbar" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.2 }} className="w-full h-full flex flex-col">
                {!chatOpen ? (
                  <div className="px-6 h-20 flex items-center justify-between w-full">
                    <div className="flex items-center gap-3 cursor-pointer" onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}>
                      <div className="w-10 h-10"><img src="/hisabatilogo.png" alt="Logo" className="w-full h-full object-contain" /></div>
                      <span className="text-xl font-extrabold hidden sm:block">Hisabati</span>
                    </div>

                    <div className="hidden lg:flex items-center gap-1 font-medium text-sm">
                      {navLinks.map((link) => (
                        <button key={link.id} onClick={() => scrollTo(link.id)} className={`relative px-4 py-2 rounded-full transition-colors outline-none select-none ${activeSection === link.id ? "text-brand" : "hover:text-brand"}`}>
                          {activeSection === link.id && <motion.div layoutId="navPill" className="absolute inset-0 bg-brand/10 rounded-full" transition={{ type: "spring", stiffness: 350, damping: 30 }} />}
                          <span className="relative z-10">{t(link.key)}</span>
                        </button>
                      ))}
                    </div>

                    <div className="flex items-center gap-2">
                      <button onClick={toggleLanguage} className="p-2 hover:bg-foreground/10 rounded-full transition"><Globe className="w-5 h-5" /></button>
                      <button onClick={() => setTheme(theme === "dark" ? "light" : "dark")} className="p-2 hover:bg-foreground/10 rounded-full transition"><SunMoonToggle theme={theme} /></button>
                      
                      <button onClick={() => setChatOpen(true)} className="flex items-center gap-2 bg-gradient-to-r from-brand to-brand-hover text-white px-4 py-2 rounded-full font-bold shadow-lg shadow-brand/20 transition-transform hover:scale-105">
                        <MessageCircle className="w-5 h-5" />
                        <span className="hidden md:inline">{lang === "ar" ? "الذكاء الاصطناعي" : "AI"}</span>
                        {isSpeaking && <div className="w-2 h-2 bg-white rounded-full animate-ping absolute top-0 right-0" />}
                      </button>

                      <button onClick={() => setMobileOpen(!mobileOpen)} className="lg:hidden p-2">{mobileOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}</button>
                    </div>
                  </div>
                ) : (
                  <div className="flex flex-col h-full w-full">
                    <div className="bg-brand/10 p-4 flex justify-between items-center backdrop-blur-md">
                      <div className="flex items-center gap-2 font-bold"><Bot className="text-brand w-5 h-5" /> {lang === "ar" ? "المساعد الذكي" : "AI Assistant"}</div>
                      <button onClick={() => setChatOpen(false)} className="p-2 hover:bg-black/10 dark:hover:bg-white/10 rounded-full transition"><X className="w-5 h-5" /></button>
                    </div>
                    <ChatInterface />
                  </div>
                )}
              </motion.div>
            )}
          </AnimatePresence>
        </motion.nav>
      </div>
      
      {/* Spacer to push content down when the header is in "relative" flow */}
      {!isScrolled && <div className="h-[500px]" />}
      
      <AnimatePresence>
        {mobileOpen && isScrolled && !chatOpen && (
          <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -20 }} className="fixed top-28 left-[2.5%] right-[2.5%] z-40 lg:hidden pointer-events-auto">
            <div className="w-full bg-white/80 dark:bg-neutral-900/80 backdrop-blur-3xl border border-black/5 dark:border-white/10 rounded-3xl shadow-2xl p-6 flex flex-col gap-3">
              {navLinks.map((link) => (
                <button key={link.id} onClick={() => scrollTo(link.id)} className={`w-full text-start px-5 py-3 rounded-xl font-medium ${activeSection === link.id ? "bg-brand/10 text-brand" : "hover:bg-foreground/5"}`}>{t(link.key)}</button>
              ))}
              <button onClick={() => setChatOpen(true)} className="w-full bg-brand text-white py-3 rounded-xl font-bold mt-2">{lang === "ar" ? "تحدث مع الذكاء الاصطناعي" : "Chat with AI"}</button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
};
