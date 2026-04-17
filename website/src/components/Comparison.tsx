"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { CheckCircle2, XCircle, Minus } from "lucide-react";

export const Comparison = () => {
  const { t } = useLanguage();

  const comparisons = [
    { feature: t("comparison.row1"), hisabati: true, cloud: false },
    { feature: t("comparison.row2"), hisabati: true, cloud: false },
    { feature: t("comparison.row3"), hisabati: true, cloud: false },
    { feature: t("comparison.row4"), hisabati: true, cloud: true },
    { feature: t("comparison.row5"), hisabati: true, cloud: false },
    { feature: t("comparison.row6"), hisabati: true, cloud: false },
    { feature: t("comparison.row7"), hisabati: true, cloud: "partial" as const },
    { feature: t("comparison.row8"), hisabati: true, cloud: true },
    { feature: t("comparison.row9"), hisabati: true, cloud: "partial" as const },
    { feature: t("comparison.row10"), hisabati: true, cloud: "partial" as const },
    { feature: t("comparison.row11"), hisabati: true, cloud: false },
    { feature: t("comparison.row12"), hisabati: true, cloud: "partial" as const },
    { feature: t("comparison.row13"), hisabati: true, cloud: false },
    { feature: t("comparison.row14"), hisabati: true, cloud: false },
    { feature: t("comparison.row15"), hisabati: true, cloud: false },
  ];

  const renderIcon = (val: boolean | "partial", isBrand: boolean) => {
    if (val === true) return <CheckCircle2 className={`w-6 h-6 ${isBrand ? "text-brand" : "text-foreground/30"}`} />;
    if (val === "partial") return <Minus className="w-6 h-6 text-yellow-500/60" />;
    return <XCircle className="w-6 h-6 text-red-500/40" />;
  };

  return (
    <section className="py-24 px-6 max-w-5xl mx-auto">
      <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-16">
        <h2 className="text-4xl md:text-5xl font-extrabold mb-4">{t("comparison.title")}</h2>
        <p className="text-foreground/60 max-w-2xl mx-auto text-lg">{t("comparison.sub")}</p>
      </motion.div>

      <motion.div initial={{ opacity: 0, scale: 0.95 }} whileInView={{ opacity: 1, scale: 1 }} viewport={{ once: true }} className="glass-heavy rounded-3xl overflow-hidden border border-brand/20 shadow-2xl">
        {/* Header */}
        <div className="grid grid-cols-3 bg-card/80 p-5 border-b border-foreground/10 text-base font-bold">
          <div className="col-span-1 text-start">{t("comparison.feat")}</div>
          <div className="col-span-1 text-center text-brand text-lg">{t("comparison.hisabati")}</div>
          <div className="col-span-1 text-center text-foreground/50">{t("comparison.cloud")}</div>
        </div>

        {/* Rows */}
        {comparisons.map((item, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, x: -10 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.03 }}
            className="grid grid-cols-3 p-4 border-b border-foreground/5 hover:bg-foreground/[0.02] transition-colors items-center"
          >
            <div className="col-span-1 font-medium text-foreground/80 text-sm">{item.feature}</div>
            <div className="col-span-1 flex justify-center">{renderIcon(item.hisabati, true)}</div>
            <div className="col-span-1 flex justify-center">{renderIcon(item.cloud, false)}</div>
          </motion.div>
        ))}
      </motion.div>
    </section>
  );
};
