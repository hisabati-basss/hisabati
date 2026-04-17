# Phase 21: Website Components — EXACT CODE (Part 1)

## ⚠️ RULES: Copy code EXACTLY. Do NOT modify anything. Do NOT add your own ideas.

---

## FILE 4: Hero.tsx
**Path:** `c:\my app creator\hisabati_app\website\src\components\Hero.tsx`
**Action:** REPLACE ENTIRE FILE.

```tsx
"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Monitor, Apple, Smartphone, Play, Sparkles } from "lucide-react";
import { useEffect, useState } from "react";

const StatCounter = ({ value, label, delay }: { value: string; label: string; delay: number }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ delay, duration: 0.6 }}
    className="text-center"
  >
    <div className="text-3xl md:text-4xl font-extrabold text-brand">{value}</div>
    <div className="text-xs md:text-sm text-foreground/50 mt-1 font-medium">{label}</div>
  </motion.div>
);

export const Hero = () => {
  const { t } = useLanguage();
  const [os, setOs] = useState<"Windows" | "Mac" | "Android" | "iOS" | "Unknown">("Unknown");

  useEffect(() => {
    const ua = navigator.userAgent;
    if (ua.indexOf("Win") !== -1) setOs("Windows");
    else if (ua.indexOf("like Mac") !== -1) setOs("iOS");
    else if (ua.indexOf("Mac") !== -1) setOs("Mac");
    else if (ua.indexOf("Android") !== -1) setOs("Android");
  }, []);

  return (
    <section className="relative pt-36 pb-20 px-6 max-w-7xl mx-auto overflow-hidden min-h-screen flex flex-col justify-center">
      {/* Background glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[900px] h-[900px] bg-brand/15 blur-[150px] rounded-full pointer-events-none" />
      <div className="absolute top-1/4 right-0 w-[400px] h-[400px] bg-brand/10 blur-[120px] rounded-full pointer-events-none" />

      <div className="relative z-10 flex flex-col lg:flex-row items-center justify-between gap-16">
        {/* Text Content */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, type: "spring", bounce: 0.3 }}
          className="flex-1 text-center lg:text-start"
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.2 }}
            className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full glass border-brand/30 text-brand text-sm font-semibold mb-6"
          >
            <Sparkles className="w-4 h-4" />
            {t("hero.welcome")}
          </motion.div>
          
          <h1 className="text-4xl sm:text-5xl lg:text-7xl font-extrabold tracking-tight leading-tight mb-6">
            {t("hero.headline").split(". ").map((line, i) => (
              <span key={i} className="block">{line}{i < t("hero.headline").split(". ").length - 1 ? "." : ""}</span>
            ))}
          </h1>
          
          <p className="text-lg md:text-xl text-foreground/70 mb-10 max-w-2xl mx-auto lg:mx-0 leading-relaxed">
            {t("hero.sub")}
          </p>

          <div className="flex flex-col sm:flex-row items-center lg:items-start gap-4 mb-10">
            <button
              onClick={() => document.getElementById("pricing")?.scrollIntoView({ behavior: "smooth" })}
              className="bg-brand hover:bg-brand-hover text-white text-lg px-8 py-4 rounded-full font-bold transition-all transform hover:scale-105 active:scale-95 shadow-2xl shadow-brand/30 flex items-center gap-3 outline-none select-none"
            >
              <Monitor className="w-6 h-6" />
              {t("hero.download")} {os !== "Unknown" ? os : "Windows"}
            </button>
            
            <button
              onClick={() => document.getElementById("demo")?.scrollIntoView({ behavior: "smooth" })}
              className="glass hover:bg-foreground/5 text-lg px-8 py-4 rounded-full font-bold transition-all transform hover:scale-105 active:scale-95 flex items-center gap-3 outline-none select-none border border-foreground/10"
            >
              <Play className="w-5 h-5 text-brand" />
              {t("hero.demo")}
            </button>
          </div>

          <div className="flex items-center gap-4 justify-center lg:justify-start">
            <span className="text-sm text-foreground/50">{t("hero.also")}</span>
            <div className="flex gap-3 text-foreground/70">
              <Apple className="w-5 h-5 hover:text-brand cursor-pointer transition-colors" />
              <Smartphone className="w-5 h-5 hover:text-brand cursor-pointer transition-colors" />
              <Monitor className="w-5 h-5 hover:text-brand cursor-pointer transition-colors" />
            </div>
          </div>
        </motion.div>

        {/* Dashboard Mockup */}
        <motion.div
          initial={{ opacity: 0, scale: 0.8, rotateY: 15 }}
          animate={{ opacity: 1, scale: 1, rotateY: 0 }}
          transition={{ duration: 1, delay: 0.3, type: "spring" }}
          style={{ perspective: 1200 }}
          className="flex-1 w-full max-w-xl relative"
        >
          <div className="absolute -inset-4 bg-gradient-to-tr from-brand/20 via-transparent to-brand/10 blur-2xl rounded-3xl pointer-events-none" />
          <div className="relative w-full aspect-[16/10] rounded-2xl glass-heavy p-1.5 border-brand/20 shadow-2xl overflow-hidden group">
            <div className="w-full h-full bg-card/90 rounded-xl border border-white/5 flex flex-col relative items-center justify-center overflow-hidden">
              <div className="w-full h-full relative bg-background/50">
                {/* Dashboard preview content */}
                <div className="absolute inset-0 p-4 flex flex-col gap-3 z-0">
                  {/* Top bar */}
                  <div className="flex items-center justify-between">
                    <div className="flex gap-2">
                      <div className="w-3 h-3 rounded-full bg-red-400/50" />
                      <div className="w-3 h-3 rounded-full bg-yellow-400/50" />
                      <div className="w-3 h-3 rounded-full bg-green-400/50" />
                    </div>
                    <div className="h-3 w-40 bg-foreground/5 rounded-full" />
                    <div className="w-6 h-6 rounded-full bg-brand/20" />
                  </div>
                  
                  {/* Sidebar + content layout */}
                  <div className="flex gap-3 flex-1">
                    {/* Sidebar */}
                    <div className="w-1/5 flex flex-col gap-2">
                      {[...Array(6)].map((_, i) => (
                        <div key={i} className={`h-3 rounded-full ${i === 1 ? "bg-brand/30 w-full" : "bg-foreground/5 w-4/5"}`} />
                      ))}
                    </div>
                    {/* Main */}
                    <div className="flex-1 flex flex-col gap-3">
                      {/* Stats row */}
                      <div className="flex gap-2">
                        {[...Array(4)].map((_, i) => (
                          <div key={i} className="flex-1 h-12 rounded-lg bg-foreground/5 flex items-center justify-center">
                            <div className={`h-5 w-5 rounded-full ${i === 0 ? "bg-brand/30" : i === 1 ? "bg-green-400/30" : i === 2 ? "bg-blue-400/30" : "bg-purple-400/30"}`} />
                          </div>
                        ))}
                      </div>
                      {/* Chart area */}
                      <div className="flex-1 rounded-lg bg-foreground/5 flex items-end p-3 gap-1">
                        {[40, 65, 45, 80, 55, 70, 90, 60, 75, 85, 50, 95].map((h, i) => (
                          <motion.div
                            key={i}
                            initial={{ height: 0 }}
                            animate={{ height: `${h}%` }}
                            transition={{ delay: 0.5 + i * 0.05, duration: 0.5 }}
                            className="flex-1 bg-brand/20 rounded-t-sm"
                            style={{ minHeight: 4 }}
                          />
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
                
                {/* Real screenshot overlay */}
                <img
                  src="/dashboard-mockup.png"
                  alt="Hisabati Dashboard"
                  className="w-full h-full object-cover z-10 relative transition-transform duration-700 group-hover:scale-[1.02] rounded-xl"
                  onError={(e) => { e.currentTarget.style.display = "none"; }}
                />
              </div>
              <div className="absolute top-0 left-0 right-0 h-1/3 bg-gradient-to-b from-white/10 to-transparent rounded-t-xl z-20 pointer-events-none mix-blend-overlay" />
            </div>
          </div>
          
          {/* Free trial badge */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 1 }}
            className="absolute -bottom-4 -right-4 glass-heavy px-4 py-2 rounded-full text-sm font-bold text-brand border border-brand/20 shadow-xl"
          >
            ✨ {t("hero.trial")}
          </motion.div>
        </motion.div>
      </div>

      {/* Stats Bar */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.8, duration: 0.6 }}
        className="relative z-10 mt-20 grid grid-cols-2 md:grid-cols-4 gap-8 max-w-3xl mx-auto"
      >
        <StatCounter value={t("hero.stat1")} label={t("hero.stat1.label")} delay={1.0} />
        <StatCounter value={t("hero.stat2")} label={t("hero.stat2.label")} delay={1.1} />
        <StatCounter value={t("hero.stat3")} label={t("hero.stat3.label")} delay={1.2} />
        <StatCounter value={t("hero.stat4")} label={t("hero.stat4.label")} delay={1.3} />
      </motion.div>
    </section>
  );
};
```

---

## FILE 5: HowItWorks.tsx (TRANSLATED BADGE)
**Path:** `c:\my app creator\hisabati_app\website\src\components\HowItWorks.tsx`
**Action:** REPLACE ENTIRE FILE.

```tsx
"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { DownloadCloud, Building2, RefreshCw } from "lucide-react";

export const HowItWorks = () => {
  const { t } = useLanguage();

  const steps = [
    { icon: <DownloadCloud className="w-10 h-10 text-brand" />, title: t("how.step1.title"), desc: t("how.step1.desc"), delay: 0.1 },
    { icon: <Building2 className="w-10 h-10 text-brand" />, title: t("how.step2.title"), desc: t("how.step2.desc"), delay: 0.3 },
    { icon: <RefreshCw className="w-10 h-10 text-brand" />, title: t("how.step3.title"), desc: t("how.step3.desc"), delay: 0.5 },
  ];

  return (
    <section className="py-24 px-6 relative bg-card">
      <div className="max-w-7xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-20">
          <div className="inline-block px-4 py-1.5 rounded-full glass text-brand text-sm font-bold mb-4">
            {t("how.badge")}
          </div>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-6">{t("how.title")}</h2>
          <p className="text-lg text-foreground/60 max-w-2xl mx-auto">{t("how.sub")}</p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 lg:gap-12 relative">
          <div className="hidden md:block absolute top-[45px] left-[15%] right-[15%] h-[2px] bg-gradient-to-r from-transparent via-brand/20 to-transparent" />
          {steps.map((step, i) => (
            <motion.div key={i} initial={{ opacity: 0, scale: 0.95 }} whileInView={{ opacity: 1, scale: 1 }} viewport={{ once: true }} transition={{ delay: step.delay }} className="relative flex flex-col items-center text-center group">
              <div className="w-24 h-24 rounded-2xl glass mb-8 flex items-center justify-center relative z-10 border border-brand/20 group-hover:bg-brand/5 group-hover:scale-110 transition-all duration-300 shadow-xl">
                {step.icon}
                <div className="absolute -top-3 -right-3 w-8 h-8 rounded-full bg-brand text-white font-bold flex items-center justify-center shadow-lg">{i + 1}</div>
              </div>
              <h3 className="text-xl font-bold mb-4">{step.title}</h3>
              <p className="text-foreground/60 leading-relaxed text-sm md:text-base">{step.desc}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};
```

---

## FILE 6: Features.tsx (28 FEATURES IN CATEGORIES)
**Path:** `c:\my app creator\hisabati_app\website\src\components\Features.tsx`
**Action:** REPLACE ENTIRE FILE.

```tsx
"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { useState } from "react";
import {
  Calculator, BookOpen, Scale, FileSpreadsheet, Landmark, Coins,
  FileText, ShoppingCart, FileCheck, CreditCard, Wallet, RotateCcw,
  Users, DollarSign, CalendarDays, UserPlus,
  Warehouse, ScanBarcode, Bell, TrendingUp,
  LayoutDashboard, Receipt, Sliders, Download,
  Brain, ShieldAlert, Lock, ClipboardList
} from "lucide-react";

interface Feature {
  icon: React.ReactNode;
  titleKey: string;
  descKey: string;
  category: string;
}

export const Features = () => {
  const { t } = useLanguage();

  const categories = [
    { key: "features.cat.accounting", label: t("features.cat.accounting") },
    { key: "features.cat.sales", label: t("features.cat.sales") },
    { key: "features.cat.hr", label: t("features.cat.hr") },
    { key: "features.cat.inventory", label: t("features.cat.inventory") },
    { key: "features.cat.reports", label: t("features.cat.reports") },
    { key: "features.cat.ai", label: t("features.cat.ai") },
  ];

  const [activeCategory, setActiveCategory] = useState(categories[0].key);

  const allFeatures: Feature[] = [
    // Accounting
    { icon: <Calculator className="w-7 h-7 text-brand" />, titleKey: "features.f1.title", descKey: "features.f1.desc", category: "features.cat.accounting" },
    { icon: <BookOpen className="w-7 h-7 text-brand" />, titleKey: "features.f2.title", descKey: "features.f2.desc", category: "features.cat.accounting" },
    { icon: <Scale className="w-7 h-7 text-brand" />, titleKey: "features.f3.title", descKey: "features.f3.desc", category: "features.cat.accounting" },
    { icon: <FileSpreadsheet className="w-7 h-7 text-brand" />, titleKey: "features.f4.title", descKey: "features.f4.desc", category: "features.cat.accounting" },
    { icon: <Landmark className="w-7 h-7 text-brand" />, titleKey: "features.f5.title", descKey: "features.f5.desc", category: "features.cat.accounting" },
    { icon: <Coins className="w-7 h-7 text-brand" />, titleKey: "features.f6.title", descKey: "features.f6.desc", category: "features.cat.accounting" },
    // Sales
    { icon: <FileText className="w-7 h-7 text-brand" />, titleKey: "features.f7.title", descKey: "features.f7.desc", category: "features.cat.sales" },
    { icon: <ShoppingCart className="w-7 h-7 text-brand" />, titleKey: "features.f8.title", descKey: "features.f8.desc", category: "features.cat.sales" },
    { icon: <FileCheck className="w-7 h-7 text-brand" />, titleKey: "features.f9.title", descKey: "features.f9.desc", category: "features.cat.sales" },
    { icon: <CreditCard className="w-7 h-7 text-brand" />, titleKey: "features.f10.title", descKey: "features.f10.desc", category: "features.cat.sales" },
    { icon: <Wallet className="w-7 h-7 text-brand" />, titleKey: "features.f11.title", descKey: "features.f11.desc", category: "features.cat.sales" },
    { icon: <RotateCcw className="w-7 h-7 text-brand" />, titleKey: "features.f12.title", descKey: "features.f12.desc", category: "features.cat.sales" },
    // HR
    { icon: <Users className="w-7 h-7 text-brand" />, titleKey: "features.f13.title", descKey: "features.f13.desc", category: "features.cat.hr" },
    { icon: <DollarSign className="w-7 h-7 text-brand" />, titleKey: "features.f14.title", descKey: "features.f14.desc", category: "features.cat.hr" },
    { icon: <CalendarDays className="w-7 h-7 text-brand" />, titleKey: "features.f15.title", descKey: "features.f15.desc", category: "features.cat.hr" },
    { icon: <UserPlus className="w-7 h-7 text-brand" />, titleKey: "features.f16.title", descKey: "features.f16.desc", category: "features.cat.hr" },
    // Inventory
    { icon: <Warehouse className="w-7 h-7 text-brand" />, titleKey: "features.f17.title", descKey: "features.f17.desc", category: "features.cat.inventory" },
    { icon: <ScanBarcode className="w-7 h-7 text-brand" />, titleKey: "features.f18.title", descKey: "features.f18.desc", category: "features.cat.inventory" },
    { icon: <Bell className="w-7 h-7 text-brand" />, titleKey: "features.f19.title", descKey: "features.f19.desc", category: "features.cat.inventory" },
    { icon: <TrendingUp className="w-7 h-7 text-brand" />, titleKey: "features.f20.title", descKey: "features.f20.desc", category: "features.cat.inventory" },
    // Reports
    { icon: <LayoutDashboard className="w-7 h-7 text-brand" />, titleKey: "features.f21.title", descKey: "features.f21.desc", category: "features.cat.reports" },
    { icon: <Receipt className="w-7 h-7 text-brand" />, titleKey: "features.f22.title", descKey: "features.f22.desc", category: "features.cat.reports" },
    { icon: <Sliders className="w-7 h-7 text-brand" />, titleKey: "features.f23.title", descKey: "features.f23.desc", category: "features.cat.reports" },
    { icon: <Download className="w-7 h-7 text-brand" />, titleKey: "features.f24.title", descKey: "features.f24.desc", category: "features.cat.reports" },
    // AI & Security
    { icon: <Brain className="w-7 h-7 text-brand" />, titleKey: "features.f25.title", descKey: "features.f25.desc", category: "features.cat.ai" },
    { icon: <ShieldAlert className="w-7 h-7 text-brand" />, titleKey: "features.f26.title", descKey: "features.f26.desc", category: "features.cat.ai" },
    { icon: <Lock className="w-7 h-7 text-brand" />, titleKey: "features.f27.title", descKey: "features.f27.desc", category: "features.cat.ai" },
    { icon: <ClipboardList className="w-7 h-7 text-brand" />, titleKey: "features.f28.title", descKey: "features.f28.desc", category: "features.cat.ai" },
  ];

  const filtered = allFeatures.filter((f) => f.category === activeCategory);

  return (
    <section id="features" className="py-24 px-6 bg-card relative z-10 border-t border-b border-foreground/5">
      <div className="max-w-7xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-12">
          <h2 className="text-4xl md:text-5xl font-extrabold mb-4">{t("features.title")}</h2>
          <p className="text-foreground/60 max-w-2xl mx-auto text-lg">{t("features.sub")}</p>
        </motion.div>

        {/* Category Tabs */}
        <div className="flex flex-wrap justify-center gap-2 mb-12">
          {categories.map((cat) => (
            <button
              key={cat.key}
              onClick={() => setActiveCategory(cat.key)}
              className={`px-5 py-2.5 rounded-full text-sm font-semibold transition-all outline-none select-none ${
                activeCategory === cat.key
                  ? "bg-brand text-white shadow-lg shadow-brand/20"
                  : "glass hover:bg-foreground/5 text-foreground/70"
              }`}
            >
              {cat.label}
            </button>
          ))}
        </div>

        {/* Feature Cards */}
        <motion.div layout className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {filtered.map((feat, i) => (
            <motion.div
              key={feat.titleKey}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              whileHover={{ y: -6, scale: 1.02 }}
              className="p-6 rounded-2xl glass border border-foreground/5 hover:border-brand/30 transition-all bg-card/50 group"
            >
              <div className="w-14 h-14 rounded-xl bg-brand/10 flex items-center justify-center mb-5 group-hover:scale-110 transition-transform">
                {feat.icon}
              </div>
              <h3 className="text-lg font-bold mb-2">{t(feat.titleKey)}</h3>
              <p className="text-foreground/60 text-sm leading-relaxed">{t(feat.descKey)}</p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
};
```

---

## FILE 7: IndustrySolutions.tsx (NEW)
**Path:** `c:\my app creator\hisabati_app\website\src\components\IndustrySolutions.tsx`
**Action:** CREATE NEW FILE.

```tsx
"use client";

import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import {
  ShoppingBag, Briefcase, HardHat, Factory, HeartPulse, Hotel,
  Truck, Car, Building2, UtensilsCrossed, Pill, Wheat,
  Fuel, Cpu, GraduationCap, Gem, Globe2, Shirt, SprayCan, ArrowRight
} from "lucide-react";

const industries = [
  { icon: ShoppingBag, nameKey: "solutions.retail", descKey: "solutions.retail.desc" },
  { icon: Briefcase, nameKey: "solutions.offices", descKey: "solutions.offices.desc" },
  { icon: HardHat, nameKey: "solutions.construction", descKey: "solutions.construction.desc" },
  { icon: Factory, nameKey: "solutions.manufacturing", descKey: "solutions.manufacturing.desc" },
  { icon: HeartPulse, nameKey: "solutions.healthcare", descKey: "solutions.healthcare.desc" },
  { icon: Hotel, nameKey: "solutions.hotels", descKey: "solutions.hotels.desc" },
  { icon: Truck, nameKey: "solutions.logistics", descKey: "solutions.logistics.desc" },
  { icon: Car, nameKey: "solutions.automotive", descKey: "solutions.automotive.desc" },
  { icon: Building2, nameKey: "solutions.realestate", descKey: "solutions.realestate.desc" },
  { icon: UtensilsCrossed, nameKey: "solutions.restaurants", descKey: "solutions.restaurants.desc" },
  { icon: Pill, nameKey: "solutions.pharma", descKey: "solutions.pharma.desc" },
  { icon: Wheat, nameKey: "solutions.agriculture", descKey: "solutions.agriculture.desc" },
  { icon: Fuel, nameKey: "solutions.energy", descKey: "solutions.energy.desc" },
  { icon: Cpu, nameKey: "solutions.technology", descKey: "solutions.technology.desc" },
  { icon: GraduationCap, nameKey: "solutions.education", descKey: "solutions.education.desc" },
  { icon: Gem, nameKey: "solutions.jewelry", descKey: "solutions.jewelry.desc" },
  { icon: Globe2, nameKey: "solutions.ecommerce", descKey: "solutions.ecommerce.desc" },
  { icon: Shirt, nameKey: "solutions.textiles", descKey: "solutions.textiles.desc" },
  { icon: SprayCan, nameKey: "solutions.cleaning", descKey: "solutions.cleaning.desc" },
];

export const IndustrySolutions = () => {
  const { t } = useLanguage();

  return (
    <section id="solutions" className="py-24 px-6 relative">
      <div className="max-w-7xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-16">
          <div className="inline-block px-4 py-1.5 rounded-full glass border-brand/30 text-brand text-sm font-semibold mb-4">
            200+ Industries
          </div>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-6">{t("solutions.title")}</h2>
          <p className="text-lg text-foreground/60 max-w-3xl mx-auto">{t("solutions.sub")}</p>
        </motion.div>

        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {industries.map((ind, i) => {
            const Icon = ind.icon;
            return (
              <motion.div
                key={ind.nameKey}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.03 }}
                whileHover={{ y: -4, scale: 1.03 }}
                className="p-5 rounded-2xl glass border border-foreground/5 hover:border-brand/30 transition-all cursor-default group text-center"
              >
                <div className="w-12 h-12 rounded-xl bg-brand/10 flex items-center justify-center mx-auto mb-3 group-hover:scale-110 group-hover:bg-brand/20 transition-all">
                  <Icon className="w-6 h-6 text-brand" />
                </div>
                <h3 className="font-bold text-sm mb-1">{t(ind.nameKey)}</h3>
                <p className="text-foreground/50 text-xs leading-relaxed hidden md:block">{t(ind.descKey)}</p>
              </motion.div>
            );
          })}
        </div>

        <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }} className="text-center mt-10">
          <button className="inline-flex items-center gap-2 text-brand font-bold hover:underline text-lg outline-none select-none">
            {t("solutions.all")} <ArrowRight className="w-5 h-5" />
          </button>
        </motion.div>
      </div>
    </section>
  );
};
```

## ⚠️ CONTINUED IN phase-22-website-components-2.md
