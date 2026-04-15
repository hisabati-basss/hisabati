"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { DownloadCloud, ShieldCheck, RefreshCw } from "lucide-react";

export const HowItWorks = () => {
  const { t } = useLanguage();

  const steps = [
    {
      icon: <DownloadCloud className="w-10 h-10 text-brand" />,
      title: t("how.step1.title"),
      desc: t("how.step1.desc"),
      delay: 0.1,
    },
    {
      icon: <ShieldCheck className="w-10 h-10 text-brand" />,
      title: t("how.step2.title"),
      desc: t("how.step2.desc"),
      delay: 0.3,
    },
    {
      icon: <RefreshCw className="w-10 h-10 text-brand" />,
      title: t("how.step3.title"),
      desc: t("how.step3.desc"),
      delay: 0.5,
    },
  ];

  return (
    <section className="py-24 px-6 relative bg-card">
      <div className="max-w-7xl mx-auto">
        <motion.div 
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-20"
        >
          <div className="inline-block px-4 py-1.5 rounded-full glass text-brand text-sm font-bold mb-4">
            Easy Setup
          </div>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-6">
            {t("how.title")}
          </h2>
          <p className="text-lg text-foreground/60 max-w-2xl mx-auto">
            {t("how.sub")}
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 lg:gap-12 relative">
          {/* Connector Line */}
          <div className="hidden md:block absolute top-[45px] left-[15%] right-[15%] h-[2px] bg-gradient-to-r from-transparent via-brand/20 to-transparent" />

          {steps.map((step, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, scale: 0.95 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ delay: step.delay }}
              className="relative flex flex-col items-center text-center group"
            >
              {/* Outer Ring */}
              <div className="w-24 h-24 rounded-2xl glass mb-8 flex items-center justify-center relative z-10 border border-brand/20 group-hover:bg-brand/5 group-hover:scale-110 transition-all duration-300 shadow-xl">
                {step.icon}
                {/* Number Badge */}
                <div className="absolute -top-3 -right-3 w-8 h-8 rounded-full bg-brand text-white font-bold flex items-center justify-center shadow-lg">
                  {i + 1}
                </div>
              </div>

              <h3 className="text-xl font-bold mb-4">{step.title}</h3>
              <p className="text-foreground/60 leading-relaxed text-sm md:text-base">
                {step.desc}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};
