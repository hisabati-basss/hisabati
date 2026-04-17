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
