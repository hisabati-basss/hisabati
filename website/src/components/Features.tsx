"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Calculator, FileText, LineChart, WifiOff, Globe2, ShieldCheck } from "lucide-react";

export const Features = () => {
  const { t } = useLanguage();

  const featuresList = [
    {
      icon: <Calculator className="w-8 h-8 text-brand" />,
      title: t("features.feat1.title"),
      desc: t("features.feat1.desc"),
    },
    {
      icon: <FileText className="w-8 h-8 text-brand" />,
      title: t("features.feat2.title"),
      desc: t("features.feat2.desc"),
    },
    {
      icon: <LineChart className="w-8 h-8 text-brand" />,
      title: t("features.feat3.title"),
      desc: t("features.feat3.desc"),
    },
    {
      icon: <WifiOff className="w-8 h-8 text-brand" />,
      title: t("features.feat4.title"),
      desc: t("features.feat4.desc"),
    },
    {
      icon: <Globe2 className="w-8 h-8 text-brand" />,
      title: t("features.feat5.title"),
      desc: t("features.feat5.desc"),
    },
    {
      icon: <ShieldCheck className="w-8 h-8 text-brand" />,
      title: t("features.feat6.title"),
      desc: t("features.feat6.desc"),
    }
  ];

  return (
    <section id="features" className="py-24 px-6 bg-card relative z-10 border-t border-b border-foreground/5">
      <div className="max-w-7xl mx-auto">
        <motion.div 
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl font-extrabold mb-4">{t("features.title")}</h2>
          <p className="text-foreground/60 max-w-2xl mx-auto text-lg">
            {t("features.sub")}
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {featuresList.map((feat, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1 }}
              whileHover={{ y: -8, scale: 1.02 }}
              className="p-8 rounded-2xl glass border border-foreground/5 hover:border-brand/30 transition-all bg-card/50 group"
            >
              <div className="w-16 h-16 rounded-xl bg-brand/10 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                {feat.icon}
              </div>
              <h3 className="text-xl font-bold mb-3">{feat.title}</h3>
              <p className="text-foreground/70 leading-relaxed">
                {feat.desc}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};
