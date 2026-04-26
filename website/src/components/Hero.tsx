"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Monitor, Apple, Smartphone, Play, Sparkles } from "lucide-react";
import { useEffect, useState } from "react";

const StatCounter = ({ value, label, delay }: { value: string; label: string; delay: number }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ delay, duration: 0.6 }}
    className="text-center"
  >
    <div className="text-3xl md:text-4xl font-extrabold text-brand">{value}</div>
    <div className="text-xs md:text-sm text-foreground/50 mt-1 font-medium">{label}</div>
  </motion.div>
);

export const Hero = () => {
  const { t } = useLanguage();
  const [os, setOs] = useState<"Windows" | "Mac" | "Android" | "iOS" | "Unknown">("Unknown");

  useEffect(() => {
    const timer = setTimeout(() => {
      const ua = navigator.userAgent;
      // eslint-disable-next-line react-hooks/set-state-in-effect
      if (ua.indexOf("Win") !== -1) setOs("Windows");
      // eslint-disable-next-line react-hooks/set-state-in-effect
      else if (ua.indexOf("like Mac") !== -1) setOs("iOS");
      // eslint-disable-next-line react-hooks/set-state-in-effect
      else if (ua.indexOf("Mac") !== -1) setOs("Mac");
      // eslint-disable-next-line react-hooks/set-state-in-effect
      else if (ua.indexOf("Android") !== -1) setOs("Android");
    }, 0);
    return () => clearTimeout(timer);
  }, []);

  return (
    <section className="relative pt-36 pb-20 px-6 max-w-7xl mx-auto overflow-hidden min-h-screen flex flex-col justify-center">
      {/* Background glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[900px] h-[900px] bg-brand/15 blur-[150px] rounded-full pointer-events-none" />
      <div className="absolute top-1/4 right-0 w-[400px] h-[400px] bg-brand/10 blur-[120px] rounded-full pointer-events-none" />

      <div className="relative z-10 flex flex-col lg:flex-row items-center justify-between gap-16">
        {/* Text Content */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, type: "spring", bounce: 0.3 }}
          className="flex-1 text-center lg:text-start"
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.2 }}
            className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full glass border-brand/30 text-brand text-sm font-semibold mb-6"
          >
            <Sparkles className="w-4 h-4" />
            {t("hero.welcome")}
          </motion.div>
          
          <h1 className="text-4xl sm:text-5xl lg:text-7xl font-extrabold tracking-tight leading-tight mb-6">
            {t("hero.headline").split(". ").map((line, i) => (
              <span key={i} className="block">{line}{i < t("hero.headline").split(". ").length - 1 ? "." : ""}</span>
            ))}
          </h1>
          
          <p className="text-lg md:text-xl text-foreground/70 mb-10 max-w-2xl mx-auto lg:mx-0 leading-relaxed">
            {t("hero.sub")}
          </p>

          <div className="flex flex-col sm:flex-row items-center lg:items-start gap-4 mb-10">
            <a
              href="/Hisabati_Setup.exe"
              download="Hisabati_Setup.exe"
              className="bg-brand hover:bg-brand-hover text-white text-lg px-8 py-4 rounded-full font-bold transition-all transform hover:scale-105 active:scale-95 shadow-2xl shadow-brand/30 flex items-center gap-3 outline-none select-none"
            >
              <Monitor className="w-6 h-6" />
              {t("hero.download")} {os !== "Unknown" ? os : "Windows"}
            </a>
            
            <button
              onClick={() => document.getElementById("demo")?.scrollIntoView({ behavior: "smooth" })}
              className="glass hover:bg-foreground/5 text-lg px-8 py-4 rounded-full font-bold transition-all transform hover:scale-105 active:scale-95 flex items-center gap-3 outline-none select-none border border-foreground/10"
            >
              <Play className="w-5 h-5 text-brand" />
              {t("hero.demo")}
            </button>
          </div>

          <div className="flex items-center gap-4 justify-center lg:justify-start">
            <span className="text-sm text-foreground/50">{t("hero.also")}</span>
            <div className="flex gap-3 text-foreground/70">
              <Apple className="w-5 h-5 hover:text-brand cursor-pointer transition-colors" />
              <Smartphone className="w-5 h-5 hover:text-brand cursor-pointer transition-colors" />
              <Monitor className="w-5 h-5 hover:text-brand cursor-pointer transition-colors" />
            </div>
          </div>
        </motion.div>

        {/* Dashboard Mockup */}
        <motion.div
          initial={{ opacity: 0, scale: 0.8, rotateY: 15 }}
          animate={{ opacity: 1, scale: 1, rotateY: 0 }}
          transition={{ duration: 1, delay: 0.3, type: "spring" }}
          style={{ perspective: 1200 }}
          className="flex-1 w-full max-w-xl relative"
        >
          <div className="absolute -inset-4 bg-gradient-to-tr from-brand/20 via-transparent to-brand/10 blur-2xl rounded-3xl pointer-events-none" />
          <div className="relative w-full aspect-[16/10] rounded-2xl glass-heavy p-1.5 border-brand/20 shadow-2xl overflow-hidden group">
            <div className="w-full h-full bg-card/90 rounded-xl border border-white/5 flex flex-col relative items-center justify-center overflow-hidden">
              <div className="w-full h-full relative bg-background/50">
                {/* Dashboard preview content */}
                <div className="absolute inset-0 p-4 flex flex-col gap-3 z-0">
                  {/* Top bar */}
                  <div className="flex items-center justify-between">
                    <div className="flex gap-2">
                      <div className="w-3 h-3 rounded-full bg-red-400/50" />
                      <div className="w-3 h-3 rounded-full bg-yellow-400/50" />
                      <div className="w-3 h-3 rounded-full bg-green-400/50" />
                    </div>
                    <div className="h-3 w-40 bg-foreground/5 rounded-full" />
                    <div className="w-6 h-6 rounded-full bg-brand/20" />
                  </div>
                  
                  {/* Sidebar + content layout */}
                  <div className="flex gap-3 flex-1">
                    {/* Sidebar */}
                    <div className="w-1/5 flex flex-col gap-2">
                      {[...Array(6)].map((_, i) => (
                        <div key={i} className={`h-3 rounded-full ${i === 1 ? "bg-brand/30 w-full" : "bg-foreground/5 w-4/5"}`} />
                      ))}
                    </div>
                    {/* Main */}
                    <div className="flex-1 flex flex-col gap-3">
                      {/* Stats row */}
                      <div className="flex gap-2">
                        {[...Array(4)].map((_, i) => (
                          <div key={i} className="flex-1 h-12 rounded-lg bg-foreground/5 flex items-center justify-center">
                            <div className={`h-5 w-5 rounded-full ${i === 0 ? "bg-brand/30" : i === 1 ? "bg-green-400/30" : i === 2 ? "bg-blue-400/30" : "bg-purple-400/30"}`} />
                          </div>
                        ))}
                      </div>
                      {/* Chart area */}
                      <div className="flex-1 rounded-lg bg-foreground/5 flex items-end p-3 gap-1">
                        {[40, 65, 45, 80, 55, 70, 90, 60, 75, 85, 50, 95].map((h, i) => (
                          <motion.div
                            key={i}
                            initial={{ height: 0 }}
                            animate={{ height: `${h}%` }}
                            transition={{ delay: 0.5 + i * 0.05, duration: 0.5 }}
                            className="flex-1 bg-brand/20 rounded-t-sm"
                            style={{ minHeight: 4 }}
                          />
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
                
                {/* Real screenshot overlay */}
                <img
                  src="/dashboard-mockup.png"
                  alt="Hisabati Dashboard"
                  className="w-full h-full object-cover z-10 relative transition-transform duration-700 group-hover:scale-[1.02] rounded-xl"
                  onError={(e) => { e.currentTarget.style.display = "none"; }}
                />
              </div>
              <div className="absolute top-0 left-0 right-0 h-1/3 bg-gradient-to-b from-white/10 to-transparent rounded-t-xl z-20 pointer-events-none mix-blend-overlay" />
            </div>
          </div>
          
          {/* Free trial badge */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 1 }}
            className="absolute -bottom-4 -right-4 glass-heavy px-4 py-2 rounded-full text-sm font-bold text-brand border border-brand/20 shadow-xl"
          >
            ✨ {t("hero.trial")}
          </motion.div>
        </motion.div>
      </div>

      {/* Stats Bar */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.8, duration: 0.6 }}
        className="relative z-10 mt-20 grid grid-cols-2 md:grid-cols-4 gap-8 max-w-3xl mx-auto"
      >
        <StatCounter value={t("hero.stat1")} label={t("hero.stat1.label")} delay={1.0} />
        <StatCounter value={t("hero.stat2")} label={t("hero.stat2.label")} delay={1.1} />
        <StatCounter value={t("hero.stat3")} label={t("hero.stat3.label")} delay={1.2} />
        <StatCounter value={t("hero.stat4")} label={t("hero.stat4.label")} delay={1.3} />
      </motion.div>
    </section>
  );
};
