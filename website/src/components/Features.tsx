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
