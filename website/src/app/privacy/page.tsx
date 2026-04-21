"use client";

import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { useLanguage } from "@/context/LanguageContext";

export default function PrivacyPolicy() {
  const { t } = useLanguage();

  return (
    <div className="min-h-screen flex flex-col bg-background text-foreground selection:bg-brand/30 selection:text-brand transition-colors duration-300">
      <Navbar />
      
      <main className="flex-1 pt-32 pb-24 px-6 relative overflow-hidden">
        {/* Background Accents */}
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-brand/5 blur-[120px] rounded-full pointer-events-none" />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-brand/10 blur-[120px] rounded-full pointer-events-none" />

        <div className="max-w-4xl mx-auto relative z-10">
          {/* Header Section */}
          <div className="mb-16 text-center">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full glass border border-foreground/5 text-xs font-semibold tracking-widest uppercase text-brand mb-6">
              Legal Documentation
            </div>
            <h1 className="text-4xl md:text-6xl font-extrabold tracking-tight mb-6 bg-clip-text text-transparent bg-gradient-to-b from-foreground to-foreground/60">
              Privacy Policy
            </h1>
            <p className="text-foreground/50 font-medium">
              Last Updated: April 21, 2026
            </p>
          </div>

          {/* Content Sections */}
          <div className="space-y-12">
            {/* Introduction */}
            <section className="glass-heavy p-8 md:p-12 rounded-3xl border border-foreground/10 shadow-2xl">
              <h2 className="text-2xl font-bold mb-6 flex items-center gap-3">
                <span className="w-8 h-8 rounded-lg bg-brand/10 flex items-center justify-center text-brand text-lg">01</span>
                Sovereign Privacy & Introduction
              </h2>
              <div className="space-y-4 text-foreground/70 leading-relaxed">
                <p>
                  At <strong>Hisabati</strong>, we prioritize <strong>"Sovereign Privacy"</strong> and an <strong>"Offline-First"</strong> approach. We believe that your financial data is yours alone. This Privacy Policy explains how we handle your information in our financial ERP system.
                </p>
                <p>
                  By using Hisabati, you agree to the terms outlined in this policy. We are committed to protecting your data using enterprise-grade security and transparent practices.
                </p>
              </div>
            </section>

            {/* Information Collection */}
            <section className="p-8 md:px-4">
              <h2 className="text-2xl font-bold mb-6 flex items-center gap-3 text-brand">
                Information Collection
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="glass p-6 rounded-2xl border border-foreground/5 hover:border-brand/30 transition-all group">
                  <h3 className="font-bold mb-3 group-hover:text-brand transition-colors">User Provided Data</h3>
                  <p className="text-sm text-foreground/60 leading-relaxed">
                    Account details, business names, and financial configurations you provide during setup or through Google OAuth.
                  </p>
                </div>
                <div className="glass p-6 rounded-2xl border border-foreground/5 hover:border-brand/30 transition-all group">
                  <h3 className="font-bold mb-3 group-hover:text-brand transition-colors">Usage Information</h3>
                  <p className="text-sm text-foreground/60 leading-relaxed">
                    Technical logs, device information, and interaction data to improve the application experience.
                  </p>
                </div>
              </div>
            </section>

            {/* AI Usage */}
            <section className="glass-heavy p-8 md:p-12 rounded-3xl border border-foreground/10 shadow-xl overflow-hidden relative">
              <div className="absolute top-0 right-0 w-32 h-32 bg-brand/5 blur-3xl rounded-full" />
              <h2 className="text-2xl font-bold mb-6 flex items-center gap-3">
                <span className="w-8 h-8 rounded-lg bg-brand/10 flex items-center justify-center text-brand text-lg">02</span>
                AI & Intelligence Usage
              </h2>
              <div className="space-y-6 text-foreground/70 leading-relaxed">
                <p>
                  Hisabati utilizes advanced AI models to provide financial insights. We distinguish between:
                </p>
                <ul className="space-y-4">
                  <li className="flex gap-4">
                    <div className="mt-1.5 w-1.5 h-1.5 rounded-full bg-brand flex-shrink-0" />
                    <span><strong>Local AI:</strong> Sensitive data processing occurs directly on your device to ensure maximum privacy.</span>
                  </li>
                  <li className="flex gap-4">
                    <div className="mt-1.5 w-1.5 h-1.5 rounded-full bg-brand flex-shrink-0" />
                    <span><strong>Cloud AI:</strong> For complex computations, anonymized data may be processed via secure cloud environments.</span>
                  </li>
                </ul>
              </div>
            </section>

            {/* Third-Party Services */}
            <section className="p-8 md:px-4">
              <h2 className="text-2xl font-bold mb-6 flex items-center gap-3 text-brand">
                Third-Party Integrations
              </h2>
              <p className="text-foreground/70 mb-8 leading-relaxed">
                We integrate with trusted partners to provide core infrastructure:
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                {['Supabase', 'Google OAuth', 'Firebase'].map((service) => (
                  <div key={service} className="glass py-4 px-6 rounded-xl border border-foreground/5 flex items-center justify-center font-bold text-foreground/80">
                    {service}
                  </div>
                ))}
              </div>
              <p className="mt-6 text-xs text-foreground/40 italic">
                * Each service maintains its own privacy policy which we recommend you review.
              </p>
            </section>

            {/* Data Retention */}
            <section className="glass-heavy p-8 md:p-12 rounded-3xl border border-foreground/10 shadow-xl">
              <h2 className="text-2xl font-bold mb-6 flex items-center gap-3">
                <span className="w-8 h-8 rounded-lg bg-brand/10 flex items-center justify-center text-brand text-lg">03</span>
                Data Retention
              </h2>
              <p className="text-foreground/70 leading-relaxed mb-6">
                Your data is stored securely in your local environment and synced with <strong>Supabase</strong> for cross-device access. You maintain full control:
              </p>
              <div className="bg-foreground/5 rounded-2xl p-6 border border-foreground/5">
                <p className="text-sm font-medium mb-2 text-foreground/80">Retention Policy:</p>
                <p className="text-sm text-foreground/60">
                  Data is retained as long as your account is active. Upon request for deletion, all identifying financial records are purged from our cloud servers within 30 days.
                </p>
              </div>
            </section>

            {/* Contact */}
            <section className="text-center py-12">
              <h2 className="text-xl font-bold mb-4">Questions or Concerns?</h2>
              <p className="text-foreground/60 mb-8">We are here to help you understand your rights.</p>
              <a 
                href="mailto:hisabati.basss@gmail.com" 
                className="inline-flex items-center gap-3 px-8 py-4 bg-brand text-white rounded-2xl font-bold hover:bg-brand-hover transition-all transform hover:scale-105 shadow-xl shadow-brand/20"
              >
                Contact Legal Support
              </a>
              <div className="mt-6 text-sm text-foreground/40">
                hisabati.basss@gmail.com
              </div>
            </section>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
