export type Language = "ar" | "en";

interface Intent {
  keywords: string[];
  response: {
    ar: string;
    en: string;
  };
}

const intents: Intent[] = [
  {
    keywords: ["hi", "hello", "مرحبا", "هلا", "سلام", "السلام"],
    response: {
      ar: "يا هلا بك في حساباتي! أنا مساعدك الذكي المدمج في النظام. تبيني أشرح لك كيف نطور تجارتك ونخليها أذكى؟",
      en: "Welcome to Hisabati! I'm your built-in AI assistant. Would you like me to explain how we can grow your business and make it smarter?"
    }
  },
  {
    keywords: ["price", "cost", "how much", "سعر", "بكم", "تكلفة", "باقات", "اشتراك"],
    response: {
      ar: "أسعارنا جداً تنافسية ومناسبة لكل حجم عمل. تبدأ باقاتنا من الباقة الأساسية المجانية للتجربة، إلى باقات احترافية تبدأ من 49 دولار شهرياً. تحب أرسل لك تفاصيل الأسعار على رقمك؟",
      en: "Our pricing is highly competitive and suitable for any business size. We start with a free trial tier, and professional tiers starting at $49/month. Would you like me to send the detailed pricing to your phone?"
    }
  },
  {
    keywords: ["features", "what", "how", "مميزات", "تفاصيل", "ميزة", "خصائص", "كيف"],
    response: {
      ar: "حساباتي مو بس نظام محاسبة عادي، هو نظام ERP كامل يشتغل بدون إنترنت (أوفلاين) وبسرعة خيالية، وفيه ذكاء اصطناعي محلي يساعدك في قراراتك، وكل هذا بخصوصية بيانات 100% بدون ما ترفع بياناتك على سيرفرات خارجية.",
      en: "Hisabati isn't just standard accounting. It's a complete offline-first ERP system that runs incredibly fast, features Local Edge AI to help your decisions, and ensures 100% data privacy without needing to upload data to external servers."
    }
  },
  {
    keywords: ["internet", "offline", "انترنت", "نت", "بدون انترنت", "اوفلاين", "أوفلاين"],
    response: {
      ar: "بالضبط! تطبيقنا مصمم يشتغل بشكل كامل بدون إنترنت. يعني لو انقطع النت بمحلك أو مصنعك، شغلك ما يوقف أبد، وكل بياناتك تُحفظ محلياً وتتزامن تلقائياً لما يرجع الاتصال.",
      en: "Exactly! Our application is designed to work completely offline. If the internet drops in your shop or factory, your work never stops. All data is saved locally and syncs automatically when connection restores."
    }
  },
  {
    keywords: ["ai", "ذكاء", "اصطناعي", "الذكاء الاصطناعي", "روبوت"],
    response: {
      ar: "نظام حساباتي يدمج ذكاء اصطناعي يعمل على جهازك (Edge AI). يعني يحلل مبيعاتك ويتوقع نقص المخزون ويعطيك نصائح تسويقية من غير ما يشارك بياناتك مع أي طرف ثالث.",
      en: "Hisabati integrates Edge AI that runs locally on your device. It analyzes your sales, predicts inventory shortages, and provides marketing advice without sharing your data with any third party."
    }
  },
  {
    keywords: ["contact", "number", "email", "تواصل", "رقم", "ايميل", "هاتف"],
    response: {
      ar: "يسعدنا تواصلك! تقدر تعطيني اسمك ورقم جوالك هنا، وفريق المبيعات بيتواصل معك في أسرع وقت لعمل عرض تجريبي (ديمو) مخصص لك.",
      en: "We'd love to connect! You can provide your name and phone number here, and our sales team will reach out ASAP to arrange a custom demo for you."
    }
  },
];

const fallbackResponse = {
  ar: "والله سؤال ممتاز. تقدر تعطيني رقم جوالك أو إيميلك عشان أخلي أحد الخبراء عندنا يتواصل معك ويفيدك بتفاصيل دقيقة؟",
  en: "That's an excellent question. Could you provide your phone number or email so one of our experts can reach out with precise details?"
};

export const generateAIResponse = (userInput: string, lang: Language): string => {
  const lowerInput = userInput.toLowerCase();
  
  for (const intent of intents) {
    if (intent.keywords.some(keyword => lowerInput.includes(keyword))) {
      return intent.response[lang];
    }
  }
  
  // Checking for phone numbers / emails to capture leads
  const phoneRegex = /[\d\+\-\(\)\s]{8,}/;
  const emailRegex = /\S+@\S+\.\S+/;
  
  if (phoneRegex.test(lowerInput) || emailRegex.test(lowerInput)) {
    return lang === "ar" 
      ? "شكراً لك! سجلت بياناتك، وفريقنا بيتواصل معك قريب جداً. في شيء ثاني أقدر أساعدك فيه؟"
      : "Thank you! I've recorded your details, and our team will be in touch very soon. Is there anything else I can help with?";
  }

  return fallbackResponse[lang];
};

export const getWelcomeMessage = (lang: Language): string => {
  return lang === "ar"
    ? "مرحباً بك في حساباتي! أنا مساعدك الذكي. نظامنا هو أول ERP يعمل بالذكاء الاصطناعي بدون إنترنت. كيف أقدر أطور لك تجارتك اليوم؟"
    : "Welcome to Hisabati! I'm your AI assistant. Our system is the first Edge AI ERP that works offline. How can I help grow your business today?";
};
