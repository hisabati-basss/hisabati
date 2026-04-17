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
