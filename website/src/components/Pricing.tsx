"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Check } from "lucide-react";

export const Pricing = () => {
  const { t } = useLanguage();

  const plans = [
    {
      name: t("pricing.free"),
      desc: t("pricing.free.desc"),
      price: "$0",
      period: t("pricing.monthly"),
      features: [t("pricing.free.f1"), t("pricing.free.f2"), t("pricing.free.f3"), t("pricing.free.f4")],
      isPopular: false,
    },
    {
      name: t("pricing.pro"),
      desc: t("pricing.pro.desc"),
      price: "$29",
      period: t("pricing.monthly"),
      features: [t("pricing.pro.f1"), t("pricing.pro.f2"), t("pricing.pro.f3"), t("pricing.pro.f4"), t("pricing.pro.f5")],
      isPopular: true,
    },
    {
      name: t("pricing.ent"),
      desc: t("pricing.ent.desc"),
      price: "$99",
      period: t("pricing.monthly"),
      features: [t("pricing.ent.f1"), t("pricing.ent.f2"), t("pricing.ent.f3"), t("pricing.ent.f4"), t("pricing.ent.f5")],
      isPopular: false,
    }
  ];

  return (
    <section id="pricing" className="py-24 px-6 relative bg-card/50">
      <div className="max-w-7xl mx-auto">
        <motion.div 
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <div className="inline-block px-4 py-1.5 rounded-full glass border-brand/30 text-brand text-sm font-semibold mb-4 lg:mx-0">
            {t("nav.pricing")}
          </div>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-6">
            {t("pricing.title")}
          </h2>
          <p className="text-lg text-foreground/60 max-w-2xl mx-auto">
            {t("pricing.sub")}
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-center max-w-6xl mx-auto">
          {plans.map((plan, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1 }}
              className={`p-8 rounded-3xl relative border transition-transform hover:-translate-y-2 ${
                plan.isPopular 
                  ? "bg-brand text-white border-brand shadow-2xl shadow-brand/20 scale-105 z-10" 
                  : "glass bg-card/80 border-foreground/10"
              }`}
            >
              {plan.isPopular && (
                <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-foreground text-background px-4 py-1 rounded-full text-sm font-bold shadow-lg">
                  {t("pricing.popular")}
                </div>
              )}
              
              <h3 className="text-2xl font-bold mb-2">{plan.name}</h3>
              <p className={`text-sm mb-6 ${plan.isPopular ? 'text-white/80' : 'text-foreground/60'}`}>{plan.desc}</p>
              
              <div className="flex items-baseline gap-1 mb-8">
                <span className="text-5xl font-extrabold tracking-tight">{plan.price}</span>
                <span className={`text-sm ${plan.isPopular ? 'text-white/80' : 'text-foreground/60'}`}>{plan.period}</span>
              </div>

              <div className="space-y-4 mb-8">
                {plan.features.map((feature, j) => (
                  <div key={j} className="flex items-start gap-3">
                    <Check className={`w-5 h-5 shrink-0 ${plan.isPopular ? 'text-white' : 'text-brand'}`} />
                    <span className="text-sm font-medium">{feature}</span>
                  </div>
                ))}
              </div>

              <button onClick={() => document.getElementById("pricing")?.scrollIntoView({ behavior: "smooth" })} className={`w-full py-4 rounded-xl font-bold transition-transform active:scale-95 outline-none focus:outline-none focus:ring-0 focus-visible:ring-0 select-none ${
                plan.isPopular
                  ? "bg-white text-brand hover:bg-gray-100 shadow-xl hover:scale-105"
                  : "bg-foreground/5 hover:bg-foreground/10 text-foreground border border-foreground/10 hover:scale-105"
              }`}>
                {t("pricing.buy")}
              </button>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};
