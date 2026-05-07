"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Handshake, Link as LinkIcon, DollarSign } from "lucide-react";

export const Affiliate = () => {
  const { t } = useLanguage();

  return (
    <section id="affiliate" className="py-24 px-6 relative bg-gradient-to-b from-card to-brand/5">
      <div className="max-w-7xl mx-auto rounded-3xl glass border border-brand/20 p-12 lg:p-20 text-center overflow-hidden relative shadow-2xl">
        <div className="absolute -top-1/2 -right-1/2 w-full h-full bg-brand/10 blur-[150px] rounded-full pointer-events-none" />
        
        <div className="w-20 h-20 mx-auto bg-brand/20 rounded-full flex items-center justify-center mb-8 relative z-10">
          <Handshake className="w-10 h-10 text-brand" />
        </div>

        <motion.h2 
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-4xl md:text-5xl font-extrabold mb-6 relative z-10"
        >
          {t("affiliate.title")}
        </motion.h2>

        <p className="text-xl text-foreground/70 max-w-2xl mx-auto mb-10 relative z-10 leading-relaxed">
          {t("affiliate.desc")}
        </p>

        <div className="flex flex-col sm:flex-row justify-center gap-6 relative z-10">
          <motion.a 
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            href="mailto:contact@hisabati.com" 
            className="bg-brand hover:bg-brand-hover text-white text-lg px-8 py-4 rounded-full font-bold shadow-xl flex items-center justify-center gap-2 outline-none focus:outline-none focus:ring-0 focus-visible:ring-0 select-none cursor-pointer"
          >
            <DollarSign className="w-5 h-5" /> {t("affiliate.btn1")}
          </motion.a>
          
          <motion.button 
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => {
              navigator.clipboard.writeText("https://hisabati.com/invite/partner");
              alert("تم نسخ رابط الدعوة بنجاح! / Invite link copied!");
            }}
            className="glass border border-brand/30 hover:bg-white/5 text-lg px-8 py-4 rounded-full font-bold transition-colors flex items-center justify-center gap-2 outline-none focus:outline-none focus:ring-0 focus-visible:ring-0 select-none"
          >
            <LinkIcon className="w-5 h-5" /> {t("affiliate.btn2")}
          </motion.button>
        </div>
      </div>
    </section>
  );
};
