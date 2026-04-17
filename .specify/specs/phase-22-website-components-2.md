# Phase 22: Website Components Part 2 — EXACT CODE

## ⚠️ RULES: Copy code EXACTLY. Do NOT modify anything.

---

## FILE 8: Pricing.tsx (4-TIER QUICKBOOKS STYLE)
**Path:** `c:\my app creator\hisabati_app\website\src\components\Pricing.tsx`
**Action:** REPLACE ENTIRE FILE.

```tsx
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
```

---

## FILE 9: Comparison.tsx (15 ROWS)
**Path:** `c:\my app creator\hisabati_app\website\src\components\Comparison.tsx`
**Action:** REPLACE ENTIRE FILE.

```tsx
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
```

---

## FILE 10: Testimonials.tsx (NEW)
**Path:** `c:\my app creator\hisabati_app\website\src\components\Testimonials.tsx`
**Action:** CREATE NEW FILE.

```tsx
"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Star, Quote } from "lucide-react";

export const Testimonials = () => {
  const { t } = useLanguage();

  const testimonials = [
    { nameKey: "testimonials.t1.name", roleKey: "testimonials.t1.role", textKey: "testimonials.t1.text", stars: 5, color: "from-brand/20 to-orange-500/10" },
    { nameKey: "testimonials.t2.name", roleKey: "testimonials.t2.role", textKey: "testimonials.t2.text", stars: 5, color: "from-blue-500/20 to-cyan-500/10" },
    { nameKey: "testimonials.t3.name", roleKey: "testimonials.t3.role", textKey: "testimonials.t3.text", stars: 5, color: "from-green-500/20 to-emerald-500/10" },
    { nameKey: "testimonials.t4.name", roleKey: "testimonials.t4.role", textKey: "testimonials.t4.text", stars: 5, color: "from-purple-500/20 to-pink-500/10" },
  ];

  return (
    <section className="py-24 px-6 bg-card relative">
      <div className="max-w-7xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-extrabold mb-4">{t("testimonials.title")}</h2>
          <p className="text-lg text-foreground/60 max-w-2xl mx-auto">{t("testimonials.sub")}</p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-5xl mx-auto">
          {testimonials.map((item, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1 }}
              whileHover={{ y: -4 }}
              className="p-7 rounded-2xl glass border border-foreground/5 hover:border-brand/20 transition-all relative overflow-hidden"
            >
              <div className={`absolute inset-0 bg-gradient-to-br ${item.color} opacity-30 pointer-events-none`} />
              <div className="relative z-10">
                <Quote className="w-8 h-8 text-brand/30 mb-4" />
                <p className="text-foreground/80 leading-relaxed mb-6 text-sm">{t(item.textKey)}</p>
                <div className="flex items-center gap-1 mb-4">
                  {[...Array(item.stars)].map((_, j) => (
                    <Star key={j} className="w-4 h-4 fill-brand text-brand" />
                  ))}
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-brand/20 flex items-center justify-center text-brand font-bold text-sm">
                    {t(item.nameKey).charAt(0)}
                  </div>
                  <div>
                    <div className="font-bold text-sm">{t(item.nameKey)}</div>
                    <div className="text-foreground/50 text-xs">{t(item.roleKey)}</div>
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};
```

---

## FILE 11: DemoVideo.tsx (NEW)
**Path:** `c:\my app creator\hisabati_app\website\src\components\DemoVideo.tsx`
**Action:** CREATE NEW FILE.

```tsx
"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Play, ArrowRight } from "lucide-react";

export const DemoVideo = () => {
  const { t } = useLanguage();

  return (
    <section id="demo" className="py-24 px-6 relative">
      <div className="max-w-5xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-12">
          <h2 className="text-4xl md:text-5xl font-extrabold mb-4">{t("demo.title")}</h2>
          <p className="text-lg text-foreground/60 max-w-2xl mx-auto">{t("demo.sub")}</p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          className="relative w-full aspect-video rounded-3xl glass-heavy border border-brand/20 shadow-2xl overflow-hidden group cursor-pointer"
          onClick={() => window.open("https://youtube.com/@hisabati", "_blank")}
        >
          {/* Gradient background */}
          <div className="absolute inset-0 bg-gradient-to-br from-brand/10 via-transparent to-brand/5" />
          
          {/* Play button */}
          <div className="absolute inset-0 flex items-center justify-center z-10">
            <motion.div
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.95 }}
              className="w-20 h-20 md:w-24 md:h-24 rounded-full bg-brand flex items-center justify-center shadow-2xl shadow-brand/40 group-hover:shadow-brand/60 transition-shadow"
            >
              <Play className="w-8 h-8 md:w-10 md:h-10 text-white fill-white ml-1" />
            </motion.div>
          </div>

          {/* Decorative elements */}
          <div className="absolute bottom-0 left-0 right-0 h-1/3 bg-gradient-to-t from-background/80 to-transparent z-10" />
          
          {/* Screenshot preview behind play button */}
          <img
            src="/dashboard-mockup.png"
            alt="Demo Preview"
            className="w-full h-full object-cover opacity-40 group-hover:opacity-50 transition-opacity"
            onError={(e) => { e.currentTarget.style.display = "none"; }}
          />
        </motion.div>

        <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }} className="text-center mt-8">
          <button
            onClick={() => document.getElementById("pricing")?.scrollIntoView({ behavior: "smooth" })}
            className="inline-flex items-center gap-2 bg-brand hover:bg-brand-hover text-white px-8 py-4 rounded-full font-bold transition-all hover:scale-105 active:scale-95 shadow-xl shadow-brand/20 outline-none select-none"
          >
            {t("demo.cta")} <ArrowRight className="w-5 h-5" />
          </button>
        </motion.div>
      </div>
    </section>
  );
};
```

---

## FILE 12: FAQ.tsx (10 ITEMS WITH ACCORDION)
**Path:** `c:\my app creator\hisabati_app\website\src\components\FAQ.tsx`
**Action:** REPLACE ENTIRE FILE.

```tsx
"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion, AnimatePresence } from "framer-motion";
import { ChevronDown } from "lucide-react";
import { useState } from "react";

export const FAQ = () => {
  const { t } = useLanguage();
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const faqs = [
    { q: t("faq.q1"), a: t("faq.a1") },
    { q: t("faq.q2"), a: t("faq.a2") },
    { q: t("faq.q3"), a: t("faq.a3") },
    { q: t("faq.q4"), a: t("faq.a4") },
    { q: t("faq.q5"), a: t("faq.a5") },
    { q: t("faq.q6"), a: t("faq.a6") },
    { q: t("faq.q7"), a: t("faq.a7") },
    { q: t("faq.q8"), a: t("faq.a8") },
    { q: t("faq.q9"), a: t("faq.a9") },
    { q: t("faq.q10"), a: t("faq.a10") },
  ];

  return (
    <section className="py-24 px-6 max-w-3xl mx-auto">
      <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-16">
        <h2 className="text-4xl md:text-5xl font-extrabold mb-4">{t("faq.title")}</h2>
      </motion.div>

      <div className="space-y-3">
        {faqs.map((faq, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, y: 10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.04 }}
            className="glass rounded-2xl border border-foreground/5 overflow-hidden"
          >
            <button
              onClick={() => setOpenIndex(openIndex === i ? null : i)}
              className="w-full flex items-center justify-between p-5 text-start font-semibold outline-none select-none hover:bg-foreground/[0.02] transition-colors"
            >
              <span className="text-sm md:text-base">{faq.q}</span>
              <motion.div animate={{ rotate: openIndex === i ? 180 : 0 }} transition={{ duration: 0.2 }}>
                <ChevronDown className="w-5 h-5 shrink-0 text-foreground/40" />
              </motion.div>
            </button>
            <AnimatePresence>
              {openIndex === i && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: "auto", opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.25 }}
                  className="overflow-hidden"
                >
                  <div className="px-5 pb-5 text-foreground/60 text-sm leading-relaxed border-t border-foreground/5 pt-4">
                    {faq.a}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        ))}
      </div>
    </section>
  );
};
```

---

## FILE 13: Contact.tsx (NEW)
**Path:** `c:\my app creator\hisabati_app\website\src\components\Contact.tsx`
**Action:** CREATE NEW FILE.

```tsx
"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Send, Phone, Mail, Calendar } from "lucide-react";

export const Contact = () => {
  const { t } = useLanguage();

  return (
    <section id="contact" className="py-24 px-6 bg-card border-t border-foreground/5">
      <div className="max-w-6xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-extrabold mb-4">{t("contact.title")}</h2>
          <p className="text-lg text-foreground/60 max-w-2xl mx-auto">{t("contact.sub")}</p>
        </motion.div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Contact Form */}
          <motion.div initial={{ opacity: 0, x: -30 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }}>
            <form onSubmit={(e) => e.preventDefault()} className="space-y-5">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-2 text-foreground/70">{t("contact.name")}</label>
                  <input type="text" className="w-full px-4 py-3 rounded-xl bg-foreground/5 border border-foreground/10 focus:border-brand/50 transition-colors text-sm outline-none" />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-2 text-foreground/70">{t("contact.email")}</label>
                  <input type="email" className="w-full px-4 py-3 rounded-xl bg-foreground/5 border border-foreground/10 focus:border-brand/50 transition-colors text-sm outline-none" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium mb-2 text-foreground/70">{t("contact.company")}</label>
                <input type="text" className="w-full px-4 py-3 rounded-xl bg-foreground/5 border border-foreground/10 focus:border-brand/50 transition-colors text-sm outline-none" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2 text-foreground/70">{t("contact.message")}</label>
                <textarea rows={5} className="w-full px-4 py-3 rounded-xl bg-foreground/5 border border-foreground/10 focus:border-brand/50 transition-colors text-sm outline-none resize-none" />
              </div>
              <button type="submit" className="w-full bg-brand hover:bg-brand-hover text-white py-4 rounded-xl font-bold flex items-center justify-center gap-2 transition-all hover:scale-[1.02] active:scale-95 shadow-xl shadow-brand/20 outline-none select-none">
                <Send className="w-5 h-5" />
                {t("contact.send")}
              </button>
            </form>
          </motion.div>

          {/* Quick Contact Cards */}
          <motion.div initial={{ opacity: 0, x: 30 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} className="flex flex-col gap-5 justify-center">
            <p className="font-semibold text-foreground/70 mb-2">{t("contact.or")}</p>

            <a href="tel:+966125122822" className="p-5 rounded-2xl glass border border-foreground/5 hover:border-brand/30 transition-all flex items-center gap-4 group">
              <div className="w-12 h-12 rounded-xl bg-brand/10 flex items-center justify-center group-hover:bg-brand/20 transition-colors">
                <Phone className="w-6 h-6 text-brand" />
              </div>
              <div>
                <div className="font-bold text-sm">{t("contact.sales")}</div>
                <div className="text-foreground/50 text-xs">+966 125 122 822</div>
              </div>
            </a>

            <a href="mailto:bassemsabri@outlook.sa" className="p-5 rounded-2xl glass border border-foreground/5 hover:border-brand/30 transition-all flex items-center gap-4 group">
              <div className="w-12 h-12 rounded-xl bg-brand/10 flex items-center justify-center group-hover:bg-brand/20 transition-colors">
                <Mail className="w-6 h-6 text-brand" />
              </div>
              <div>
                <div className="font-bold text-sm">{t("contact.support")}</div>
                <div className="text-foreground/50 text-xs">bassemsabri@outlook.sa</div>
              </div>
            </a>

            <div className="p-5 rounded-2xl glass border border-foreground/5 hover:border-brand/30 transition-all flex items-center gap-4 group cursor-pointer">
              <div className="w-12 h-12 rounded-xl bg-brand/10 flex items-center justify-center group-hover:bg-brand/20 transition-colors">
                <Calendar className="w-6 h-6 text-brand" />
              </div>
              <div>
                <div className="font-bold text-sm">{t("contact.demo")}</div>
                <div className="text-foreground/50 text-xs">Schedule a 30-min live demo</div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
};
```

---

## FILE 14: Footer.tsx (UPDATED)
**Path:** `c:\my app creator\hisabati_app\website\src\components\Footer.tsx`
**Action:** REPLACE ENTIRE FILE.

```tsx
"use client";

import { useLanguage } from "@/context/LanguageContext";

const FacebookIcon = ({ className }: { className?: string }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"/>
  </svg>
);

const LinkedinIcon = ({ className }: { className?: string }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"/>
    <rect width="4" height="12" x="2" y="9"/><circle cx="4" cy="4" r="2"/>
  </svg>
);

const InstagramIcon = ({ className }: { className?: string }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <rect width="20" height="20" x="2" y="2" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" x2="17.51" y1="6.5" y2="6.5"/>
  </svg>
);

const TiktokIcon = ({ className }: { className?: string }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M9 12a4 4 0 1 0 4 4V4a5 5 0 0 0 5 5"/>
  </svg>
);

export const Footer = () => {
  const { t } = useLanguage();

  return (
    <footer className="bg-card border-t border-foreground/10 pt-16 pb-8 px-6">
      <div className="max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
        <div className="col-span-1 md:col-span-2">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 flex-shrink-0">
              <img src="/hisabatilogo.png" alt="Hisabati Logo" className="w-full h-full object-contain" />
            </div>
            <span className="text-xl font-extrabold tracking-tight">Hisabati</span>
          </div>
          <p className="text-foreground/60 max-w-sm mb-6 text-sm leading-relaxed">
            {t("footer.desc")}
          </p>
          <div className="flex gap-3">
            <a href="https://www.linkedin.com/in/hisabati-undefined-0a9b9a402/" target="_blank" rel="noreferrer" className="w-10 h-10 rounded-full bg-foreground/5 flex items-center justify-center hover:bg-brand hover:text-white transition-colors">
              <LinkedinIcon className="w-4 h-4" />
            </a>
            <a href="https://www.instagram.com/hisabati.basss" target="_blank" rel="noreferrer" className="w-10 h-10 rounded-full bg-foreground/5 flex items-center justify-center hover:bg-brand hover:text-white transition-colors">
              <InstagramIcon className="w-4 h-4" />
            </a>
            <a href="https://www.facebook.com/share/1BPvxD3aAr/" target="_blank" rel="noreferrer" className="w-10 h-10 rounded-full bg-foreground/5 flex items-center justify-center hover:bg-brand hover:text-white transition-colors">
              <FacebookIcon className="w-4 h-4" />
            </a>
            <a href="https://www.tiktok.com/@hisabati.app" target="_blank" rel="noreferrer" className="w-10 h-10 rounded-full bg-foreground/5 flex items-center justify-center hover:bg-brand hover:text-white transition-colors">
              <TiktokIcon className="w-4 h-4" />
            </a>
          </div>
        </div>

        <div>
          <h4 className="font-bold mb-4 uppercase text-xs tracking-wider text-foreground/50">{t("footer.product")}</h4>
          <ul className="space-y-3 text-foreground/70 text-sm">
            <li><a href="#features" className="hover:text-brand transition-colors">{t("footer.features")}</a></li>
            <li><a href="#solutions" className="hover:text-brand transition-colors">{t("footer.solutions")}</a></li>
            <li><a href="#pricing" className="hover:text-brand transition-colors">{t("footer.link3")}</a></li>
            <li><a href="#affiliate" className="hover:text-brand transition-colors">{t("footer.link4")}</a></li>
          </ul>
        </div>

        <div>
          <h4 className="font-bold mb-4 uppercase text-xs tracking-wider text-foreground/50">{t("footer.developer")}</h4>
          <ul className="space-y-3 text-foreground/70 text-sm">
            <li><a href="#" className="hover:text-brand transition-colors">{t("footer.sys1")}</a></li>
            <li><a href="#" className="hover:text-brand transition-colors">{t("footer.sys2")}</a></li>
            <li><a href="#" className="hover:text-brand transition-colors">{t("footer.sys3")}</a></li>
            <li><a href="mailto:bassemsabri@outlook.sa" className="hover:text-brand transition-colors">{t("footer.sys4")}</a></li>
          </ul>
        </div>
      </div>

      <div className="max-w-7xl mx-auto pt-8 border-t border-foreground/10 text-center text-foreground/40 text-xs">
        {t("footer.rights")}
      </div>
    </footer>
  );
};
```

---

## FILES THAT DO NOT CHANGE (keep as-is):
- `EdgeAI.tsx` — Keep existing file, no changes needed
- `Marketing.tsx` — Keep existing file, no changes needed
- `Affiliate.tsx` — Keep existing file, no changes needed
- `TrustMarquee.tsx` — Keep existing file, no changes needed
- `ThemeProvider.tsx` — Keep existing file, no changes needed
- `layout.tsx` — Keep existing file, no changes needed
- `globals.css` — Already updated (glass fix done)

---

## AFTER ALL FILES ARE DONE:

### Step 1: Verify build
```bash
cd "c:\my app creator\hisabati_app\website"
npm run build
```

### Step 2: If build succeeds, run dev server
```bash
npm run dev
```

### Step 3: Open browser and verify
1. Check dark mode: glass cards should be OPAQUE frosted, NOT see-through
2. Check light mode: glass cards should be soft frosted white
3. Check Arabic: toggle language and verify RTL layout
4. Check mobile: resize browser to 375px width, verify hamburger menu opens
5. Count pricing plans: should be 4 (Starter, Business, Professional, Enterprise)
6. Count FAQ items: should be 10
7. Count feature categories: should be 6 tabs
8. Count industry cards: should be 19
9. Count comparison rows: should be 15
10. Count testimonials: should be 4

### Common Errors and Fixes:
- If import error for `IndustrySolutions`, `Testimonials`, `DemoVideo`, or `Contact`: make sure the filenames match EXACTLY as specified above.
- If Framer Motion errors: make sure `AnimatePresence` is imported from "framer-motion".
- If lucide-react icon not found: check exact icon name in lucide docs, some icons may have different names in different versions.
