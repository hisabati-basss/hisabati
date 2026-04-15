"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Monitor, Apple, Smartphone, LayoutDashboard } from "lucide-react";
import { useEffect, useState } from "react";

export const Hero = () => {
  const { t } = useLanguage();
  const [os, setOs] = useState<"Windows" | "Mac" | "Android" | "iOS" | "Unknown">("Unknown");

  useEffect(() => {
    const userAgent = navigator.userAgent;
    if (userAgent.indexOf("Win") !== -1) setOs("Windows");
    if (userAgent.indexOf("Mac") !== -1) setOs("Mac");
    if (userAgent.indexOf("Android") !== -1) setOs("Android");
    if (userAgent.indexOf("like Mac") !== -1) setOs("iOS");
  }, []);

  return (
    <section className="relative pt-32 pb-20 px-6 max-w-7xl mx-auto overflow-hidden min-h-screen flex flex-col justify-center">
      {/* Background elements */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-brand/20 blur-[120px] rounded-full pointer-events-none" />

      <div className="relative z-10 flex flex-col lg:flex-row items-center justify-between gap-16">
        
        {/* Text Content */}
        <motion.div 
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, type: "spring", bounce: 0.3 }}
          className="flex-1 text-center lg:text-start"
        >
          <div className="inline-block px-4 py-1.5 rounded-full glass border-brand/30 text-brand text-sm font-semibold mb-6">
            {t("hero.welcome")}
          </div>
          <h1 className="text-5xl lg:text-7xl font-extrabold tracking-tight leading-tight mb-6">
            {t("hero.headline").split(". ").map((line, i) => (
              <span key={i} className="block">{line}.</span>
            ))}
          </h1>
          <p className="text-xl text-foreground/70 mb-10 max-w-2xl mx-auto lg:mx-0">
            {t("hero.sub")}
          </p>

          <div className="flex flex-col items-center lg:items-start gap-4">
            <button onClick={() => document.getElementById("pricing")?.scrollIntoView({ behavior: "smooth" })} className="bg-brand hover:bg-brand-hover text-white text-lg px-8 py-4 rounded-full font-bold transition-all transform hover:scale-105 active:scale-95 shadow-2xl flex items-center gap-3">
              <Monitor className="w-6 h-6" />
              {t("hero.download")} {os !== "Unknown" ? os : "Windows"}
            </button>
            <div className="text-sm text-foreground/50 flex items-center gap-4">
              <span>{t("hero.also")}</span>
              <div className="flex gap-2 text-foreground/70">
                <Apple className="w-4 h-4 hover:text-brand cursor-pointer transition-colors" />
                <Smartphone className="w-4 h-4 hover:text-brand cursor-pointer transition-colors" />
                <Monitor className="w-4 h-4 hover:text-brand cursor-pointer transition-colors" />
              </div>
            </div>
          </div>
        </motion.div>

        {/* 3D Mockup Visual */}
        <motion.div 
          initial={{ opacity: 0, scale: 0.8, rotateY: 20 }}
          animate={{ opacity: 1, scale: 1, rotateY: 0 }}
          transition={{ duration: 1, delay: 0.2, type: "spring" }}
          style={{ perspective: 1000 }}
          className="flex-1 w-full max-w-xl relative"
        >
          <div className="relative w-full aspect-[16/9] rounded-2xl glass p-1.5 border-brand/20 shadow-2xl overflow-hidden group">
            {/* Screen Container */}
            <div className="w-full h-full bg-card/90 rounded-xl border border-white/5 flex flex-col relative items-center justify-center overflow-hidden">

              {/* Media Placeholders */}
              <div className="w-full h-full relative bg-background/50">
                
                {/* Abstract Background Animation (Fallback if no screenshot) */}
                <div className="absolute inset-0 flex flex-col items-center justify-center z-0 overflow-hidden">
                  <div className="absolute w-[800px] h-[800px] border border-brand/5 rounded-full animate-ping [animation-duration:4s]" />
                  <div className="absolute w-[500px] h-[500px] border border-brand/10 rounded-full animate-ping [animation-duration:2.5s]" />
                  <LayoutDashboard className="w-20 h-20 mb-6 text-brand/30 animate-pulse" />
                  <span className="text-foreground/40 font-medium px-4 py-2 border border-foreground/10 rounded-full bg-card/50 backdrop-blur-sm text-sm">
                    {t("hero.download")} /dashboard-mockup.png
                  </span>
                </div>

                {/* 2. Image Screenshot */}
                <img 
                  src="/dashboard-mockup.png" 
                  alt="Hisabati App Dashboard" 
                  className="w-full h-full object-cover z-10 relative transition-transform duration-700 group-hover:scale-[1.02] shadow-[0_20px_50px_rgba(0,0,0,0.5)] rounded-xl" 
                  onError={(e) => {
                    e.currentTarget.style.display = 'none';
                  }}
                />
              </div>

              {/* Subtle light reflection curve at the top to simulate gloss */}
              <div className="absolute top-0 left-0 right-0 h-1/3 bg-gradient-to-b from-white/10 to-transparent rounded-t-xl z-20 pointer-events-none mix-blend-overlay" />
            </div>
          </div>
        </motion.div>

      </div>
    </section>
  );
};
