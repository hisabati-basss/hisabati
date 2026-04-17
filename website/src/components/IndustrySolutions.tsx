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
