"use client";

import React, { createContext, useContext, useState, useEffect } from "react";

type Language = "en" | "ar";

interface LanguageContextProps {
  language: Language;
  toggleLanguage: () => void;
  dir: "ltr" | "rtl";
  t: (key: string) => string;
}

const translations = {
  en: {
    "nav.features": "Features",
    "nav.security": "AI Security",
    "nav.affiliate": "Affiliate",
    "nav.pricing": "Pricing",
    "nav.join": "Join Hisabati",
    "hero.welcome": "Welcome to the Future of Accounting",
    "hero.headline": "Revolutionize Your Accounting. Online, Offline, Anytime.",
    "hero.sub": "The ultimate offline-first ERP and Accounting System with Local Edge AI.",
    "hero.download": "Download for",
    "hero.also": "Also available on:",
    "features.title": "World-Class Capabilities",
    "features.sub": "Experience an accounting ERP built for speed, privacy, and true global scalability.",
    "features.feat1.title": "Smart Expenses",
    "features.feat1.desc": "Automated tracking of multiple currency cash flows with deep analytics.",
    "features.feat2.title": "Instant Invoicing",
    "features.feat2.desc": "Create and send professional invoices in seconds with custom branding.",
    "features.feat3.title": "Real-time Analytics",
    "features.feat3.desc": "A powerful dashboard offering instant insights into business health.",
    "features.feat4.title": "Offline First",
    "features.feat4.desc": "Works flawlessly without internet. Syncs when you back online.",
    "features.feat5.title": "Cross Platform",
    "features.feat5.desc": "Syncs natively across Windows, macOS, Android, and iOS devices.",
    "features.feat6.title": "Highest Security",
    "features.feat6.desc": "Local data encryption and full privacy, no forced cloud hosting.",
    "security.privacy": "100% Local Privacy",
    "security.title": "Your Data. Your Power. Local AI.",
    "security.desc": "Unlike cloud ERPs, Hisabati's built-in AI Agent does not rely on Cloud APIs. All financial automation, data processing, and analysis happen locally on your device (Edge AI). Your private data never leaves your network without your explicit permission.",
    "security.li1": "Zero Cloud Data Mining",
    "security.li2": "Instant AI Responses (No Latency)",
    "security.li3": "Local Encryption AES-256",
    "security.blocked": "BLOCKED",
    "marketing.title": "Scale Fast with Built-in Marketing Tools.",
    "marketing.desc": "Stop paying for expensive third-party email tools. Hisabati includes a native mass-emailing engine capable of sending up to 1,000 professional marketing emails or personalized invoices instantly.",
    "marketing.campaign": "Campaign: Q4 Promos",
    "marketing.recipients": "1,000 Recipients selected",
    "marketing.launch": "Launch Campaign",
    "how.title": "How to Start?",
    "how.sub": "Set up your powerful accounting system in 3 simple steps.",
    "how.step1.title": "1. Download securely",
    "how.step1.desc": "Get the offline executable for your operating system natively.",
    "how.step2.title": "2. Create Local Profile",
    "how.step2.desc": "Your data is instantly encrypted and saved entirely on your hard drive.",
    "how.step3.title": "3. Sync (Optional)",
    "how.step3.desc": "Connect multiple branch devices securely over your own local network.",
    "comparison.title": "Why Hisabati?",
    "comparison.sub": "See why businesses are switching from legacy Cloud ERPs like QuickBooks and Odoo.",
    "comparison.feat": "Feature",
    "comparison.hisabati": "Hisabati",
    "comparison.cloud": "Cloud ERPs",
    "comparison.row1": "Offline Access",
    "comparison.row2": "Local AI Privacy",
    "comparison.row3": "Zero Monthly Latency",
    "comparison.row4": "Cross-Platform Sync",
    "comparison.row5": "Mass Email Engine",
    "affiliate.title": "Partner with Hisabati. Earn Passive Income.",
    "affiliate.desc": "Join our global network of marketers. Promote an application businesses actually need. Generate custom invite links, run paid promotions, and earn generous recurring commissions.",
    "affiliate.btn1": "Become an Affiliate",
    "affiliate.btn2": "Get Invite Link",
    "pricing.title": "Transparent Pricing",
    "pricing.sub": "Choose the plan that fits your business scale.",
    "pricing.free": "Free",
    "pricing.free.desc": "For small starters",
    "pricing.free.f1": "Single Device",
    "pricing.free.f2": "Basic Accounting",
    "pricing.free.f3": "Up to 100 Invoices/mo",
    "pricing.free.f4": "Community Support",
    "pricing.pro": "Pro",
    "pricing.pro.desc": "For growing businesses",
    "pricing.pro.f1": "Multi-Device Sync",
    "pricing.pro.f2": "Advanced Edge AI",
    "pricing.pro.f3": "Unlimited Invoices",
    "pricing.pro.f4": "Priority Support",
    "pricing.pro.f5": "Email Marketing Engine",
    "pricing.ent": "Enterprise",
    "pricing.ent.desc": "For large scales",
    "pricing.ent.f1": "Custom Integrations",
    "pricing.ent.f2": "Dedicated Account Manager",
    "pricing.ent.f3": "White-label Options",
    "pricing.ent.f4": "On-premise Deployment",
    "pricing.ent.f5": "24/7 Phone Support",
    "pricing.monthly": "/month",
    "pricing.yearly": "/year",
    "pricing.buy": "Get Started",
    "pricing.popular": "Most Popular",
    "faq.title": "Frequently Asked Questions",
    "faq.q1": "Is my data really offline?",
    "faq.a1": "Yes, Hisabati stores 100% of your primary data on your local device. We have no access to it.",
    "faq.q2": "Can I use it on mobile?",
    "faq.a2": "Absolutely. We have native apps for Android and iOS that sync seamlessly.",
    "faq.q3": "Does it support multiple users?",
    "faq.a3": "Yes, you can connect multiple devices over your local network for real-time collaboration.",
    "footer.desc": "The ultimate offline-first ERP system. Global standard accounting with local Edge AI privacy.",
    "footer.product": "Product",
    "footer.link1": "Download Windows",
    "footer.link2": "Download macOS",
    "footer.link3": "Pricing",
    "footer.link4": "Partners",
    "footer.developer": "Developer",
    "footer.sys1": "Developer: hbasss",
    "footer.sys2": "Privacy Policy",
    "footer.sys3": "Terms of Service",
    "footer.sys4": "bassemsabri@outlook.sa",
    "footer.rights": "© 2026 Hisabati. All rights reserved.",
  },
  ar: {
    "nav.features": "المميزات",
    "nav.security": "أمان الذكاء الاصطناعي",
    "nav.affiliate": "نظام الشركاء",
    "nav.pricing": "الأسعار",
    "nav.join": "انضم إلى حساباتي",
    "hero.welcome": "مرحباً بك في مستقبل المحاسبة",
    "hero.headline": "أحدث ثورة في حساباتك. متصل، غير متصل، في أي وقت.",
    "hero.sub": "نظام المحاسبة وإدارة الموارد الأول عالمياً الذي يعمل بدون إنترنت مع ذكاء اصطناعي محلي.",
    "hero.download": "تحميل لـ",
    "hero.also": "متاح أيضاً على:",
    "features.title": "قدرات عالمية المستوى",
    "features.sub": "جرب نظاماً محاسبياً بُني من أجل السرعة، الخصوصية، وقابلية التوسع العالمية الحقيقية.",
    "features.feat1.title": "مصروفات ذكية",
    "features.feat1.desc": "تتبع آلي للتدفقات النقدية متعددة العملات مع تحليلات عميقة.",
    "features.feat2.title": "فواتير فورية",
    "features.feat2.desc": "أنشئ وأرسل فواتير احترافية في ثوانٍ مع هويتك التجارية.",
    "features.feat3.title": "تحليلات لحظية",
    "features.feat3.desc": "لوحة بيانات قوية تقدم رؤى فورية لسلامة أعمالك.",
    "features.feat4.title": "الأولوية للأوفلاين",
    "features.feat4.desc": "يعمل بشكل مثالي بدون إنترنت. ويتزامن عند الاتصال.",
    "features.feat5.title": "متعدد المنصات",
    "features.feat5.desc": "يتزامن أصلياً عبر أجهزة ويندوز وماك وأندرويد و iOS.",
    "features.feat6.title": "أعلى حماية",
    "features.feat6.desc": "تشفير محلي للبيانات وخصوصية تامة، بدون استضافة سحابية إجبارية.",
    "security.privacy": "100% خصوصية محلية",
    "security.title": "بياناتك. قوتك. ذكاء اصطناعي محلي.",
    "security.desc": "على عكس الأنظمة السحابية، المساعد الذكي المدمج في حساباتي لا يعتمد على واجهات السحاب. جميع الأتمتة المالية، المعالجة السريعة، والتحليل تتم محلياً على جهازك (ذكاء الحافة). بياناتك الخاصة لا تغادر شبكتك أبدًا دون إذنك الصريح.",
    "security.li1": "لا يوجد تنقيب سحابي للبيانات",
    "security.li2": "ردود ذكاء اصطناعي فورية (بدون تأخير)",
    "security.li3": "تشفير محلي AES-256",
    "security.blocked": "محظور",
    "marketing.title": "انمو بسرعة مع أدوات التسويق المدمجة.",
    "marketing.desc": "توقف عن الدفع لأدوات البريد الخارجية باهظة الثمن. حساباتي يتضمن محرك بريد إلكتروني جماعي أساسي قادر على إرسال ما يصل إلى 1,000 بريد تسويقي احترافي أو فواتير مخصصة في لحظات.",
    "marketing.campaign": "حملة: عروض الربع الرابع",
    "marketing.recipients": "تم تحديد 1,000 مستلم",
    "marketing.launch": "إطلاق الحملة",
    "how.title": "كيف تبدأ؟",
    "how.sub": "قم بإعداد نظامك المحاسبي القوي في 3 خطوات بسيطة.",
    "how.step1.title": "1. تحميل آمن",
    "how.step1.desc": "احصل على النسخة المباشرة الأوفلاين الخاصة بنظام التشغيل الخاص بك.",
    "how.step2.title": "2. إنشاء ملف تعريف محلي",
    "how.step2.desc": "يتم تشفير جميع بياناتك فوراً وحفظها داخل جهازك بصورة كاملة.",
    "how.step3.title": "3. المزامنة (اختياري)",
    "how.step3.desc": "اربط أكثر من فرع وجهاز معاً بأمان تام عبر شبكتك المحلية الخاصة.",
    "comparison.title": "لماذا حساباتي؟",
    "comparison.sub": "اكتشف لماذا تهاجر الشركات من الأنظمة السحابية القديمة مثل كويك بوكس وأودو.",
    "comparison.feat": "الميزة",
    "comparison.hisabati": "حساباتي",
    "comparison.cloud": "الأنظمة السحابية",
    "comparison.row1": "الوصول بدون إنترنت",
    "comparison.row2": "خصوصية الذكاء الاصطناعي المحلي",
    "comparison.row3": "صفر تأخير سحابي شهري",
    "comparison.row4": "مزامنة بين المنصات المختلفة",
    "comparison.row5": "محرك البريد الإلكتروني الجماعي",
    "affiliate.title": "كُن شريكاً مع حساباتي. واربح عمولات دورية.",
    "affiliate.desc": "انضم إلى شبكتنا العالمية من المسوقين. قم بالترويج لتطبيق تحتاجه الشركات فعلياً. احصل على رابط دعوتك الخاص لتبدأ بتحقيق عمولات شهرية مستمرة ومجزية.",
    "affiliate.btn1": "انضم كشريك الآن",
    "affiliate.btn2": "احصل على رابطك",
    "pricing.title": "أسعار شفافة",
    "pricing.sub": "اختر الخطة المناسبة لحجم أعمالك.",
    "pricing.free": "مجانية",
    "pricing.free.desc": "للبدايات الصغيرة",
    "pricing.free.f1": "تزامن لجهاز واحد",
    "pricing.free.f2": "محاسبة أساسية",
    "pricing.free.f3": "حتى ١٠٠ فاتورة/شهر",
    "pricing.free.f4": "دعم المجتمع المفتوح",
    "pricing.pro": "برو",
    "pricing.pro.desc": "للأعمال المتنامية",
    "pricing.pro.f1": "تزامن لعدة أجهزة",
    "pricing.pro.f2": "أمان ذكاء اصطناعي متقدم",
    "pricing.pro.f3": "فواتير لا محدودة",
    "pricing.pro.f4": "دعم فني ذو أولوية",
    "pricing.pro.f5": "محرك تسويق إيميل جماعي",
    "pricing.ent": "إنتربرايز",
    "pricing.ent.desc": "للمؤسسات الكبيرة",
    "pricing.ent.f1": "تكامل برمجيات مخصص",
    "pricing.ent.f2": "مدير حساب مخصص",
    "pricing.ent.f3": "التسويق بهويتك التجارية",
    "pricing.ent.f4": "الاستضافة الداخلية",
    "pricing.ent.f5": "دعم عبر الهاتف ٢٤/٧",
    "pricing.monthly": "/شهرياً",
    "pricing.yearly": "/سنوياً",
    "pricing.buy": "ابدأ الآن",
    "pricing.popular": "الأكثر طلباً",
    "faq.title": "الأسئلة الشائعة",
    "faq.q1": "هل بياناتي حقاً أوفلاين؟",
    "faq.a1": "نعم، حساباتي يخزن 100% من بياناتك الأساسية على جهازك المحلي. ليس لدينا أي وصول إليها.",
    "faq.q2": "هل يمكنني استخدامه على الجوال؟",
    "faq.a2": "بالتأكيد. لدينا تطبيقات أصلية لنظامي Android و iOS تتزامن بسلاسة.",
    "faq.q3": "هل يدعم تعدد المستخدمين؟",
    "faq.a3": "نعم، يمكنك ربط عدة أجهزة عبر شبكتك المحلية للعمل الجماعي في الوقت الفعلي.",
    "footer.desc": "نظام ERP الشامل الذي يعمل الأوفلاين أولاً. محاسبة عالمية المعايير مع خصوصية الذكاء الاصطناعي المحلي.",
    "footer.product": "المنتج",
    "footer.link1": "تحميل لنظام الويندوز",
    "footer.link2": "تحميل للماك",
    "footer.link3": "الأسعار",
    "footer.link4": "الشركاء",
    "footer.developer": "المُطوِّر",
    "footer.sys1": "تطوير: hbasss",
    "footer.sys2": "سياسة الخصوصية",
    "footer.sys3": "شروط الخدمة",
    "footer.sys4": "bassemsabri@outlook.sa",
    "footer.rights": "© 2026 حساباتي. جميع الحقوق محفوظة.",
  }
};

const LanguageContext = createContext<LanguageContextProps | undefined>(undefined);

export const LanguageProvider = ({ children }: { children: React.ReactNode }) => {
  const [language, setLanguage] = useState<Language>("en");

  // On mount, check if there's a saved preference or default to browser language
  useEffect(() => {
    const saved = localStorage.getItem("hisabati_lang") as Language;
    if (saved && (saved === "en" || saved === "ar")) {
      setLanguage(saved);
    } else {
      const isArabic = navigator.language.startsWith("ar");
      setLanguage(isArabic ? "ar" : "en");
    }
  }, []);

  const toggleLanguage = () => {
    const newLang = language === "en" ? "ar" : "en";
    setLanguage(newLang);
    localStorage.setItem("hisabati_lang", newLang);
  };

  const dir = language === "ar" ? "rtl" : "ltr";

  const t = (key: string): string => {
    return translations[language][key as keyof typeof translations["en"]] || key;
  };

  useEffect(() => {
    document.documentElement.dir = dir;
    document.documentElement.lang = language;
  }, [dir, language]);

  return (
    <LanguageContext.Provider value={{ language, toggleLanguage, dir, t }}>
      <div dir={dir}>{children}</div>
    </LanguageContext.Provider>
  );
};

export const useLanguage = () => {
  const context = useContext(LanguageContext);
  if (!context) throw new Error("useLanguage must be used within LanguageProvider");
  return context;
};
