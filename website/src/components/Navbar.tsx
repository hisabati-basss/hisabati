"use client";

import React, { useState, useEffect } from "react";
import { useLanguage } from "@/context/LanguageContext";
import { useTheme } from "next-themes";
import { Moon, Sun, Globe } from "lucide-react";
import { motion } from "framer-motion";

export const Navbar = () => {
  const { t, toggleLanguage, language } = useLanguage();
  const { theme, setTheme } = useTheme();

  const [activeSection, setActiveSection] = useState<string>("");

  useEffect(() => {
    const handleScroll = () => {
      const sections = ["features", "security", "affiliate", "pricing"];
      const scrollPos = window.scrollY + window.innerHeight / 3;

      let current = "";
      for (const section of sections) {
        const el = document.getElementById(section);
        if (el && el.offsetTop <= scrollPos) {
          current = section;
        }
      }
      setActiveSection(current);
    };

    window.addEventListener("scroll", handleScroll);
    handleScroll();
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const navLinks = [
    { id: "features", key: "nav.features" },
    { id: "security", key: "nav.security" },
    { id: "affiliate", key: "nav.affiliate" },
    { id: "pricing", key: "nav.pricing" },
  ];

  return (
    <div className="flex justify-center w-full">
      <motion.nav 
        initial={{ y: -100 }}
        animate={{ y: 0 }}
        transition={{ type: "spring", stiffness: 100, damping: 20 }}
        className="fixed top-6 w-[95%] max-w-6xl z-50 rounded-full glass border border-foreground/10 shadow-2xl transition-all duration-300 bg-background/40 backdrop-blur-2xl"
      >
        <div className="px-6 h-20 flex items-center justify-between">
          {/* Logo */}
          <div className="flex items-center gap-3 cursor-pointer">
            <div className="w-12 h-12 flex-shrink-0">
              <img src="/hisabatilogo.png" alt="Hisabati Logo" className="w-full h-full object-contain" />
            </div>
            <span className="text-xl font-extrabold tracking-tight">Hisabati</span>
          </div>

          {/* Links (Desktop) */}
          <div className="hidden lg:flex items-center gap-2 font-medium text-sm">
            {navLinks.map((link) => (
              <a 
                key={link.id} 
                href={`#${link.id}`} 
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
              </a>
            ))}
          </div>

          {/* Actions */}
          <div className="flex items-center gap-3">
            <button onClick={toggleLanguage} className="p-2 rounded-full hover:bg-foreground/10 transition-colors flex items-center gap-2 outline-none focus:outline-none focus:ring-0 focus-visible:ring-0 select-none">
              <Globe className="w-5 h-5" />
              <span className="text-xs font-bold uppercase">{language}</span>
            </button>
            
            <button 
              onClick={() => setTheme(theme === "dark" ? "light" : "dark")} 
              className="p-2 rounded-full hover:bg-foreground/10 transition-colors outline-none focus:outline-none focus:ring-0 focus-visible:ring-0 select-none"
            >
              {theme === "dark" ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            </button>

            <a href="#pricing" className="hidden sm:block bg-brand hover:bg-brand-hover text-white px-6 py-2.5 rounded-full font-bold transition-all transform hover:scale-105 active:scale-95 shadow-lg shadow-brand/30 outline-none focus:outline-none focus:ring-0 focus-visible:ring-0 select-none">
              {t("nav.join")}
            </a>
          </div>
        </div>
      </motion.nav>
    </div>
  );
};
