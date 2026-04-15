"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { CheckCircle2, XCircle } from "lucide-react";

export const Comparison = () => {
  const { t } = useLanguage();

  const comparisons = [
    { feature: t("comparison.row1"), hisabati: true, cloud: false },
    { feature: t("comparison.row2"), hisabati: true, cloud: false },
    { feature: t("comparison.row3"), hisabati: true, cloud: false },
    { feature: t("comparison.row4"), hisabati: true, cloud: true },
    { feature: t("comparison.row5"), hisabati: true, cloud: false },
  ];

  return (
    <section className="py-24 px-6 max-w-5xl mx-auto">
      <div className="text-center mb-16">
        <h2 className="text-4xl font-extrabold mb-4">{t("comparison.title")}</h2>
        <p className="text-foreground/60 max-w-2xl mx-auto text-lg">
          {t("comparison.sub")}
        </p>
      </div>

      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }}
        whileInView={{ opacity: 1, scale: 1 }}
        viewport={{ once: true }}
        className="glass rounded-3xl overflow-hidden border border-brand/20 shadow-2xl"
      >
        <div className="grid grid-cols-3 bg-card/80 p-6 border-b border-foreground/10 text-lg font-bold">
          <div className="col-span-1 text-start">{t("comparison.feat")}</div>
          <div className="col-span-1 text-center text-brand text-xl">{t("comparison.hisabati")}</div>
          <div className="col-span-1 text-center text-foreground/50">{t("comparison.cloud")}</div>
        </div>

        {comparisons.map((item, i) => (
          <div key={i} className="grid grid-cols-3 p-6 border-b border-foreground/5 hover:bg-white/5 transition-colors items-center">
            <div className="col-span-1 font-medium text-foreground/80">{item.feature}</div>
            
            <div className="col-span-1 flex justify-center">
              {item.hisabati ? <CheckCircle2 className="w-8 h-8 text-brand" /> : <XCircle className="w-8 h-8 text-red-500/50" />}
            </div>
            
            <div className="col-span-1 flex justify-center">
              {item.cloud ? <CheckCircle2 className="w-8 h-8 text-foreground/30" /> : <XCircle className="w-8 h-8 text-red-500/50" />}
            </div>
          </div>
        ))}
      </motion.div>
    </section>
  );
};
