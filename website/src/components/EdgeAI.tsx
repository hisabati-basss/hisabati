"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Lock, CloudOff, Database, Shield } from "lucide-react";

export const EdgeAI = () => {
  const { t } = useLanguage();

  return (
    <section id="security" className="py-24 px-6 max-w-7xl mx-auto overflow-hidden">
      <div className="flex flex-col lg:flex-row items-center gap-16">
        
        <motion.div 
          initial={{ opacity: 0, x: -50 }}
          whileInView={{ opacity: 1, x: 0 }}
          viewport={{ once: true }}
          className="flex-1"
        >
          <div className="relative w-full max-w-md mx-auto aspect-square">
            <div className="absolute inset-0 bg-brand/20 blur-[100px] rounded-full" />
            <div className="relative z-10 w-full h-full flex items-center justify-center">
              
              {/* Edge AI Analytics Core */}
              <div className="relative w-64 h-64 border border-brand/30 rounded-full flex items-center justify-center bg-card/60 backdrop-blur-2xl shadow-[0_0_50px_rgba(255,107,0,0.15)] group">
                
                {/* Spinning Scanner Lines */}
                <motion.div 
                  animate={{ rotate: 360 }} 
                  transition={{ duration: 8, repeat: Infinity, ease: "linear" }}
                  className="absolute inset-0 w-full h-full border-t-2 border-l-2 border-brand/70 rounded-full opacity-50"
                />
                <motion.div 
                  animate={{ rotate: -360 }} 
                  transition={{ duration: 12, repeat: Infinity, ease: "linear" }}
                  className="absolute inset-4 border-r border-b border-foreground/30 rounded-full border-dashed"
                />

                <Shield className="w-20 h-20 text-brand absolute z-20 drop-shadow-[0_0_15px_rgba(255,107,0,0.6)] group-hover:scale-110 transition-transform duration-500" />
                
                {/* Data Packets escaping attempt */}
                <motion.div 
                  initial={{ x: 0, y: 0, opacity: 1, scale: 0.5 }}
                  animate={{ x: [0, 80], y: [0, -80], opacity: [1, 0], scale: [0.5, 1.2] }}
                  transition={{ duration: 2.5, repeat: Infinity, ease: "easeOut" }}
                  className="absolute z-10 text-brand"
                >
                  <Database className="w-6 h-6" />
                </motion.div>
                <motion.div 
                  initial={{ x: 0, y: 0, opacity: 1, scale: 0.5 }}
                  animate={{ x: [0, -80], y: [0, -60], opacity: [1, 0], scale: [0.5, 1] }}
                  transition={{ duration: 3, repeat: Infinity, ease: "easeOut", delay: 1 }}
                  className="absolute z-10 text-brand/50"
                >
                  <Database className="w-4 h-4" />
                </motion.div>

                {/* Cloud Blocked Warning Box */}
                <motion.div 
                  initial={{ opacity: 0.8, y: 0 }}
                  animate={{ opacity: 1, y: [-5, 5, -5] }}
                  transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
                  className="absolute -top-4 -right-12 text-foreground/80 flex flex-col items-center gap-1.5 bg-card/90 p-3 rounded-2xl border border-red-500/40 backdrop-blur-md shadow-2xl z-30"
                >
                  <CloudOff className="w-8 h-8 text-red-500 drop-shadow-[0_0_8px_rgba(239,68,68,0.5)]" />
                  <span className="font-bold text-[10px] text-red-500 uppercase tracking-widest">{t("security.blocked")}</span>
                </motion.div>
              </div>

            </div>
          </div>
        </motion.div>

        <motion.div 
          initial={{ opacity: 0, x: 50 }}
          whileInView={{ opacity: 1, x: 0 }}
          viewport={{ once: true }}
          className="flex-1 text-center lg:text-start"
        >
          <div className="inline-block px-4 py-1.5 rounded-full glass text-brand text-sm font-semibold mb-6 flex items-center gap-2 w-fit mx-auto lg:mx-0">
            <Lock className="w-4 h-4" /> {t("security.privacy")}
          </div>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-6 leading-tight">
            {t("security.title")}
          </h2>
          <p className="text-lg text-foreground/70 mb-8 max-w-xl mx-auto lg:mx-0 leading-relaxed">
            {t("security.desc")}
          </p>
          <ul className="space-y-4 text-start max-w-xl mx-auto lg:mx-0">
            <li className="flex items-center gap-4 text-foreground/80 font-medium">
              <div className="w-6 h-6 rounded-full bg-green-500/20 text-green-500 flex items-center justify-center">✓</div>
              {t("security.li1")}
            </li>
            <li className="flex items-center gap-4 text-foreground/80 font-medium">
              <div className="w-6 h-6 rounded-full bg-green-500/20 text-green-500 flex items-center justify-center">✓</div>
              {t("security.li2")}
            </li>
            <li className="flex items-center gap-4 text-foreground/80 font-medium">
              <div className="w-6 h-6 rounded-full bg-green-500/20 text-green-500 flex items-center justify-center">✓</div>
              {t("security.li3")}
            </li>
          </ul>
        </motion.div>

      </div>
    </section>
  );
};
