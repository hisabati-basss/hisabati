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
