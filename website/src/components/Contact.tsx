"use client";

import React, { useState } from "react";
import { useLanguage } from "@/context/LanguageContext";
import { motion } from "framer-motion";
import { Send, Phone, Mail, Calendar, MessageCircle } from "lucide-react";

export const Contact = () => {
  const { t } = useLanguage();

  const [formData, setFormData] = useState({ name: "", email: "", company: "", message: "" });

  const handleWhatsAppSend = () => {
    const text = `مرحباً، أود الاستفسار عن نظام حساباتي.%0A%0Aالاسم: ${formData.name}%0Aالبريد: ${formData.email}%0Aالشركة: ${formData.company}%0Aالرسالة: ${formData.message}`;
    window.open(`https://wa.me/971558870648?text=${text}`, '_blank');
  };

  const handleEmailSend = (e: React.FormEvent) => {
    e.preventDefault();
    const subject = `Inquiry from ${formData.name || "Website"}`;
    const body = `Name: ${formData.name}%0AEmail: ${formData.email}%0ACompany: ${formData.company}%0AMessage:%0A${formData.message}`;
    window.location.href = `mailto:hisabati.basss@gmail.com?subject=${subject}&body=${body}`;
  };

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
            <form onSubmit={handleEmailSend} className="space-y-5">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-2 text-foreground/70">{t("contact.name")}</label>
                  <input type="text" required value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} className="w-full px-4 py-3 rounded-xl bg-foreground/5 border border-foreground/10 focus:border-brand/50 transition-colors text-sm outline-none" />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-2 text-foreground/70">{t("contact.email")}</label>
                  <input type="email" required value={formData.email} onChange={(e) => setFormData({...formData, email: e.target.value})} className="w-full px-4 py-3 rounded-xl bg-foreground/5 border border-foreground/10 focus:border-brand/50 transition-colors text-sm outline-none" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium mb-2 text-foreground/70">{t("contact.company")}</label>
                <input type="text" value={formData.company} onChange={(e) => setFormData({...formData, company: e.target.value})} className="w-full px-4 py-3 rounded-xl bg-foreground/5 border border-foreground/10 focus:border-brand/50 transition-colors text-sm outline-none" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2 text-foreground/70">{t("contact.message")}</label>
                <textarea rows={5} required value={formData.message} onChange={(e) => setFormData({...formData, message: e.target.value})} className="w-full px-4 py-3 rounded-xl bg-foreground/5 border border-foreground/10 focus:border-brand/50 transition-colors text-sm outline-none resize-none" />
              </div>
              
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <button type="submit" className="w-full bg-brand hover:bg-brand-hover text-white py-4 rounded-xl font-bold flex items-center justify-center gap-2 transition-all hover:scale-[1.02] active:scale-95 shadow-xl shadow-brand/20 outline-none select-none">
                  <Send className="w-5 h-5" />
                  {t("contact.send")}
                </button>
                <button type="button" onClick={handleWhatsAppSend} className="w-full bg-[#25D366] hover:bg-[#128C7E] text-white py-4 rounded-xl font-bold flex items-center justify-center gap-2 transition-all hover:scale-[1.02] active:scale-95 shadow-xl shadow-[#25D366]/20 outline-none select-none">
                  <MessageCircle className="w-5 h-5" />
                  {t("contact.sales") || "WhatsApp"}
                </button>
              </div>
            </form>
          </motion.div>

          {/* Quick Contact Cards */}
          <motion.div initial={{ opacity: 0, x: 30 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} className="flex flex-col gap-5 justify-center">
            <p className="font-semibold text-foreground/70 mb-2">{t("contact.or")}</p>

            <a href="tel:+971558870648" className="p-5 rounded-2xl glass border border-foreground/5 hover:border-brand/30 transition-all flex items-center gap-4 group">
              <div className="w-12 h-12 rounded-xl bg-brand/10 flex items-center justify-center group-hover:bg-brand/20 transition-colors">
                <Phone className="w-6 h-6 text-brand" />
              </div>
              <div>
                <div className="font-bold text-sm">{t("contact.sales")}</div>
                <div className="text-foreground/50 text-xs">+971 55 887 0648</div>
              </div>
            </a>

            <a href="mailto:hisabati.basss@gmail.com" className="p-5 rounded-2xl glass border border-foreground/5 hover:border-brand/30 transition-all flex items-center gap-4 group">
              <div className="w-12 h-12 rounded-xl bg-brand/10 flex items-center justify-center group-hover:bg-brand/20 transition-colors">
                <Mail className="w-6 h-6 text-brand" />
              </div>
              <div>
                <div className="font-bold text-sm">{t("contact.support")}</div>
                <div className="text-foreground/50 text-xs">hisabati.basss@gmail.com</div>
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
