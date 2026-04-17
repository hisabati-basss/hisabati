"use client";

import React, { useState, useEffect } from "react";
import { useLanguage } from "@/context/LanguageContext";
import { useTheme } from "next-themes";
import { Moon, Sun, Globe, Menu, X } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

const SunMoonToggle = ({ theme }: { theme: string | undefined }) => {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  if (!mounted) return <div className="w-5 h-5" />;
  return theme === "dark" ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />;
};

export const Navbar = () => {
  const { t, toggleLanguage, language } = useLanguage();
  const { theme, setTheme } = useTheme();
  const [activeSection, setActiveSection] = useState<string>("");
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      const sections = ["features", "solutions", "security", "affiliate", "pricing", "contact"];
      const scrollPos = window.scrollY + window.innerHeight / 3;
      let current = "";
      for (const section of sections) {
        const el = document.getElementById(section);
        if (el && el.offsetTop <= scrollPos) current = section;
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
    document.getElementById(id)?.scrollIntoView({ behavior: "smooth" });
    setMobileOpen(false);
  };

  return (
    <>
      <div className="flex justify-center w-full">
        <motion.nav
          initial={{ y: -100, opacity: 0 }}
          animate={{ y: [0, 2, 0], opacity: 1 }}
          transition={{ 
            y: { repeat: Infinity, duration: 4, ease: "easeInOut" },
            opacity: { duration: 0.6 },
            default: { type: "spring", stiffness: 100, damping: 20 }
          }}
          className="fixed top-6 w-[95%] max-w-6xl z-50"
        >
          <div className="w-full h-full rounded-full bg-white/30 dark:bg-neutral-900/60 backdrop-blur-xl backdrop-saturate-150 border border-black/5 dark:border-white/10 shadow-2xl transition-all duration-300">
            <div className="px-6 h-20 flex items-center justify-between">
              {/* Logo */}
              <div className="flex items-center gap-3 cursor-pointer" onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}>
                <div className="w-12 h-12 flex-shrink-0">
                  <img src="/hisabatilogo.png" alt="Hisabati Logo" className="w-full h-full object-contain" />
                </div>
                <span className="text-xl font-extrabold tracking-tight">Hisabati</span>
              </div>

            {/* Desktop Links */}
            <div className="hidden lg:flex items-center gap-1 font-medium text-sm">
              {navLinks.map((link) => (
                <button
                  key={link.id}
                  onClick={() => scrollTo(link.id)}
                  className={`relative px-5 py-2.5 rounded-full transition-colors flex items-center justify-center select-none outline-none focus:outline-none ${activeSection === link.id ? "text-brand" : "hover:text-brand"}`}
                >
                  {activeSection === link.id && (
                    <motion.div
                      layoutId="activeNavPill"
                      className="absolute inset-0 bg-brand/10 dark:bg-brand/20 rounded-full"
                      transition={{ type: "spring", stiffness: 350, damping: 30 }}
                    />
                  )}
                  <span className="relative z-10">{t(link.key)}</span>
                </button>
              ))}
            </div>

            {/* Actions */}
            <div className="flex items-center gap-2">
              <button onClick={toggleLanguage} className="p-2 rounded-full hover:bg-foreground/10 transition-colors flex items-center gap-1.5 outline-none select-none">
                <Globe className="w-5 h-5" />
                <span className="text-xs font-bold uppercase hidden sm:inline">{language}</span>
              </button>

              <button onClick={() => setTheme(theme === "dark" ? "light" : "dark")} className="p-2 rounded-full hover:bg-foreground/10 transition-colors outline-none select-none">
                <SunMoonToggle theme={theme} />
              </button>

              <button onClick={() => scrollTo("pricing")} className="hidden md:block bg-brand hover:bg-brand-hover text-white px-6 py-2.5 rounded-full font-bold transition-all transform hover:scale-105 active:scale-95 shadow-lg shadow-brand/30 outline-none select-none text-sm">
                {t("nav.join")}
              </button>

              {/* Mobile Hamburger */}
              <button onClick={() => setMobileOpen(!mobileOpen)} className="lg:hidden p-2 rounded-full hover:bg-foreground/10 transition-colors outline-none select-none">
                {mobileOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
              </button>
            </div>
          </div>
          </div>
        </motion.nav>
      </div>

      {/* Mobile Drawer */}
      <AnimatePresence>
        {mobileOpen && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="fixed top-28 left-[2.5%] right-[2.5%] z-40 lg:hidden"
          >
            <div className="w-full h-full bg-white/30 dark:bg-neutral-900/60 backdrop-blur-xl backdrop-saturate-150 border border-black/5 dark:border-white/10 rounded-3xl shadow-2xl p-6 flex flex-col gap-3">
              {navLinks.map((link) => (
                <button
                  key={link.id}
                  onClick={() => scrollTo(link.id)}
                  className={`w-full text-start px-5 py-3 rounded-xl font-medium transition-colors outline-none select-none ${activeSection === link.id ? "bg-brand/10 text-brand" : "hover:bg-foreground/5"}`}
                >
                  {t(link.key)}
                </button>
              ))}
              <button onClick={() => { scrollTo("pricing"); }} className="w-full bg-brand hover:bg-brand-hover text-white py-3 rounded-xl font-bold mt-2 transition-all outline-none select-none">
                {t("nav.join")}
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
};
