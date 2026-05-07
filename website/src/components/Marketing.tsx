"use client";

import React, { useState, useEffect, useRef } from "react";
import { useLanguage } from "@/context/LanguageContext";
import { motion, useInView, animate } from "framer-motion";
import { Send, Mail, Users, CheckCircle2 } from "lucide-react";

export const Marketing = () => {
  const { t } = useLanguage();
  const [sentCount, setSentCount] = useState(0);
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  useEffect(() => {
    if (isInView) {
      const controls = animate(0, 1000, {
        duration: 3,
        ease: "easeOut",
        onUpdate: (val) => setSentCount(Math.floor(val))
      });
      return controls.stop;
    }
  }, [isInView]);

  return (
    <section className="py-24 px-6 bg-card relative z-10 border-t border-foreground/5 overflow-hidden">
      <div className="max-w-7xl mx-auto flex flex-col-reverse lg:flex-row items-center gap-16">
        
        <motion.div 
          ref={ref}
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="flex-1 w-full"
        >
          <div className="glass p-8 rounded-3xl border border-brand/20 relative shadow-2xl overflow-hidden group hover:border-brand/40 transition-colors duration-500">
            
            <div className="absolute inset-0 bg-brand/5 blur-[100px] z-0 pointer-events-none" />

            {/* Live Interactive UI */}
            <div className="relative z-10">
              <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:scale-110 group-hover:opacity-20 transition-all duration-700">
                <Mail className="w-24 h-24 text-brand" />
              </div>
              <div className="flex items-center gap-4 mb-8">
                <div className="w-12 h-12 rounded-full bg-brand flex items-center justify-center shadow-lg shadow-brand/20">
                  <Users className="w-6 h-6 text-white" />
                </div>
                <div>
                  <h3 className="font-bold text-lg">{t("marketing.campaign")}</h3>
                  <p className="text-sm text-foreground/50">
                    تم إرسال {sentCount.toLocaleString()} من 1,000 مستلم
                  </p>
                </div>
              </div>

              <div className="space-y-4">
                {[...Array(3)].map((_, i) => (
                  <motion.div 
                    key={i}
                    initial={{ opacity: 0, x: -20 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    viewport={{ once: true }}
                    transition={{ delay: 0.2 + i * 0.1 }}
                    className="p-4 rounded-xl bg-foreground/5 relative overflow-hidden flex items-center justify-between shadow-inner hover:bg-foreground/10 transition-colors cursor-default"
                  >
                    {/* Animated Progress Bar Background */}
                    <motion.div 
                      initial={{ width: "0%" }}
                      animate={isInView ? { width: "100%" } : { width: "0%" }}
                      transition={{ duration: 2, delay: 0.5 + (i * 0.4), ease: "easeInOut" }}
                      className="absolute left-0 top-0 bottom-0 bg-brand/10 z-0"
                    />

                    <div className="flex items-center gap-3 relative z-10">
                      <div className="w-8 h-8 rounded-full bg-foreground/10" />
                      <div className="h-4 w-32 bg-foreground/10 rounded" />
                    </div>
                    
                    <div className="relative z-10">
                      <motion.div
                        initial={{ scale: 1, opacity: 1 }}
                        animate={isInView ? { scale: 0, opacity: 0 } : { scale: 1, opacity: 1 }}
                        transition={{ duration: 0.3, delay: 2 + (i * 0.4) }}
                        className="absolute inset-0 flex items-center justify-center"
                      >
                        <Send className="w-4 h-4 text-brand" />
                      </motion.div>
                      <motion.div
                        initial={{ scale: 0, opacity: 0 }}
                        animate={isInView ? { scale: 1, opacity: 1 } : { scale: 0, opacity: 0 }}
                        transition={{ duration: 0.3, delay: 2.2 + (i * 0.4), type: "spring" }}
                        className="flex items-center justify-center text-[#25D366]"
                      >
                        <CheckCircle2 className="w-5 h-5" />
                      </motion.div>
                    </div>
                  </motion.div>
                ))}
              </div>

              <button 
                onClick={() => {
                  const text = `مرحباً، أود الاستفسار عن أداة التسويق المدمجة وإطلاق حملات عبر نظام حساباتي.`;
                  window.open(`https://wa.me/971558870648?text=${text}`, '_blank');
                }}
                className="w-full mt-6 bg-brand hover:bg-brand-hover text-white py-3 rounded-xl font-bold flex items-center justify-center gap-2 transition-transform transform hover:scale-105 active:scale-95 shadow-xl shadow-brand/20 select-none outline-none"
              >
                <Send className="w-5 h-5" /> {t("marketing.launch")}
              </button>
            </div>
          </div>
        </motion.div>

        <motion.div 
          initial={{ opacity: 0, x: 50 }}
          whileInView={{ opacity: 1, x: 0 }}
          viewport={{ once: true }}
          className="flex-1 text-center lg:text-start"
        >
          <h2 className="text-4xl md:text-5xl font-extrabold mb-6 leading-tight">
            {t("marketing.title")}
          </h2>
          <p className="text-lg text-foreground/70 mb-8 max-w-xl mx-auto lg:mx-0 leading-relaxed">
            {t("marketing.desc")}
          </p>
        </motion.div>

      </div>
    </section>
  );
};
