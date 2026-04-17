"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Check, Zap, Building2, Crown, Rocket } from "lucide-react";
import { useState } from "react";

export const Pricing = () => {
  const { t } = useLanguage();
  const [yearly, setYearly] = useState(false);

  const plans = [
    {
      name: t("pricing.starter"),
      desc: t("pricing.starter.desc"),
      price: yearly ? t("pricing.starter.price.yr") : t("pricing.starter.price.mo"),
      period: yearly ? t("pricing.yr") : t("pricing.mo"),
      icon: <Zap className="w-6 h-6" />,
      features: [
        t("pricing.starter.f1"), t("pricing.starter.f2"), t("pricing.starter.f3"),
        t("pricing.starter.f4"), t("pricing.starter.f5"), t("pricing.starter.f6"),
      ],
      isPopular: false,
      isEnterprise: false,
    },
    {
      name: t("pricing.business"),
      desc: t("pricing.business.desc"),
      price: yearly ? t("pricing.business.price.yr") : t("pricing.business.price.mo"),
      period: yearly ? t("pricing.yr") : t("pricing.mo"),
      icon: <Building2 className="w-6 h-6" />,
      features: [
        t("pricing.business.f1"), t("pricing.business.f2"), t("pricing.business.f3"),
        t("pricing.business.f4"), t("pricing.business.f5"), t("pricing.business.f6"),
        t("pricing.business.f7"), t("pricing.business.f8"),
      ],
      isPopular: false,
      isEnterprise: false,
    },
    {
      name: t("pricing.professional"),
      desc: t("pricing.professional.desc"),
      price: yearly ? t("pricing.professional.price.yr") : t("pricing.professional.price.mo"),
      period: yearly ? t("pricing.yr") : t("pricing.mo"),
      icon: <Crown className="w-6 h-6" />,
      features: [
        t("pricing.professional.f1"), t("pricing.professional.f2"), t("pricing.professional.f3"),
        t("pricing.professional.f4"), t("pricing.professional.f5"), t("pricing.professional.f6"),
        t("pricing.professional.f7"), t("pricing.professional.f8"), t("pricing.professional.f9"),
      ],
      isPopular: true,
      isEnterprise: false,
    },
    {
      name: t("pricing.enterprise"),
      desc: t("pricing.enterprise.desc"),
      price: yearly ? t("pricing.enterprise.price.yr") : t("pricing.enterprise.price.mo"),
      period: yearly ? t("pricing.yr") : t("pricing.mo"),
      icon: <Rocket className="w-6 h-6" />,
      features: [
        t("pricing.enterprise.f1"), t("pricing.enterprise.f2"), t("pricing.enterprise.f3"),
        t("pricing.enterprise.f4"), t("pricing.enterprise.f5"), t("pricing.enterprise.f6"),
        t("pricing.enterprise.f7"), t("pricing.enterprise.f8"), t("pricing.enterprise.f9"),
      ],
      isPopular: false,
      isEnterprise: true,
    },
  ];

  return (
    <section id="pricing" className="py-24 px-6 relative bg-card/50">
      <div className="max-w-7xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-12">
          <div className="inline-block px-4 py-1.5 rounded-full glass border-brand/30 text-brand text-sm font-semibold mb-4">
            {t("nav.pricing")}
          </div>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-6">{t("pricing.title")}</h2>
          <p className="text-lg text-foreground/60 max-w-2xl mx-auto">{t("pricing.sub")}</p>
        </motion.div>

        {/* Monthly / Yearly Toggle */}
        <div className="flex items-center justify-center gap-4 mb-12">
          <span className={`font-semibold transition-colors ${!yearly ? "text-foreground" : "text-foreground/40"}`}>{t("pricing.monthly")}</span>
          <button
            onClick={() => setYearly(!yearly)}
            className={`relative w-14 h-7 rounded-full transition-colors outline-none select-none ${yearly ? "bg-brand" : "bg-foreground/20"}`}
          >
            <motion.div
              animate={{ x: yearly ? 28 : 2 }}
              transition={{ type: "spring", stiffness: 500, damping: 30 }}
              className="absolute top-1 w-5 h-5 rounded-full bg-white shadow-md"
            />
          </button>
          <span className={`font-semibold transition-colors ${yearly ? "text-foreground" : "text-foreground/40"}`}>
            {t("pricing.yearly")}
          </span>
          {yearly && (
            <motion.span initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} className="text-xs font-bold text-green-500 bg-green-500/10 px-3 py-1 rounded-full">
              {t("pricing.yearly.save")}
            </motion.span>
          )}
        </div>

        {/* Plan Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 items-stretch max-w-7xl mx-auto">
          {plans.map((plan, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.08 }}
              className={`p-7 rounded-3xl relative border transition-all hover:-translate-y-2 flex flex-col ${
                plan.isPopular
                  ? "bg-brand text-white border-brand shadow-2xl shadow-brand/20 scale-[1.03] z-10"
                  : "glass bg-card/80 border-foreground/10"
              }`}
            >
              {plan.isPopular && (
                <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-foreground text-background px-4 py-1 rounded-full text-xs font-bold shadow-lg">
                  {t("pricing.popular")}
                </div>
              )}

              <div className={`w-12 h-12 rounded-xl flex items-center justify-center mb-4 ${plan.isPopular ? "bg-white/20" : "bg-brand/10"}`}>
                <div className={plan.isPopular ? "text-white" : "text-brand"}>{plan.icon}</div>
              </div>

              <h3 className="text-xl font-bold mb-1">{plan.name}</h3>
              <p className={`text-sm mb-5 ${plan.isPopular ? "text-white/70" : "text-foreground/50"}`}>{plan.desc}</p>

              <div className="flex items-baseline gap-1 mb-6">
                <span className="text-4xl font-extrabold tracking-tight">{plan.price}</span>
                <span className={`text-sm ${plan.isPopular ? "text-white/70" : "text-foreground/50"}`}>{plan.period}</span>
              </div>

              <div className="space-y-3 mb-8 flex-1">
                {plan.features.map((feature, j) => (
                  <div key={j} className="flex items-start gap-2.5">
                    <Check className={`w-4 h-4 shrink-0 mt-0.5 ${plan.isPopular ? "text-white" : "text-brand"}`} />
                    <span className="text-sm font-medium">{feature}</span>
                  </div>
                ))}
              </div>

              <button
                onClick={() => plan.isEnterprise ? document.getElementById("contact")?.scrollIntoView({ behavior: "smooth" }) : undefined}
                className={`w-full py-3.5 rounded-xl font-bold transition-all active:scale-95 outline-none select-none ${
                  plan.isPopular
                    ? "bg-white text-brand hover:bg-gray-100 shadow-xl hover:scale-105"
                    : plan.isEnterprise
                    ? "bg-brand text-white hover:bg-brand-hover shadow-lg hover:scale-105"
                    : "bg-foreground/5 hover:bg-foreground/10 text-foreground border border-foreground/10 hover:scale-105"
                }`}
              >
                {plan.isEnterprise ? t("pricing.contact") : t("pricing.buy")}
              </button>
            </motion.div>
          ))}
        </div>

        {/* All plans include */}
        <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }} className="mt-12 text-center">
          <p className="font-semibold mb-4 text-foreground/70">{t("pricing.all.include")}</p>
          <div className="flex flex-wrap justify-center gap-6 text-sm text-foreground/50">
            <span className="flex items-center gap-2"><Check className="w-4 h-4 text-brand" />{t("pricing.all.f1")}</span>
            <span className="flex items-center gap-2"><Check className="w-4 h-4 text-brand" />{t("pricing.all.f2")}</span>
            <span className="flex items-center gap-2"><Check className="w-4 h-4 text-brand" />{t("pricing.all.f3")}</span>
            <span className="flex items-center gap-2"><Check className="w-4 h-4 text-brand" />{t("pricing.all.f4")}</span>
          </div>
        </motion.div>
      </div>
    </section>
  );
};
