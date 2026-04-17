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
