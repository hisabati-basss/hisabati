import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/ThemeProvider";
import { LanguageProvider } from "@/context/LanguageContext";
import { GoogleAnalytics } from "@next/third-parties/google";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  metadataBase: new URL('https://hisabati.com'),
  title: "حساباتي | النظام المحاسبي العالمي المدمج بالذكاء الاصطناعي - Hisabati ERP",
  description: "The ultimate offline-first ERP and Accounting System with Local Edge AI. 100% local privacy. نظام حساباتي المحاسبي وإدارة الموارد الأول عالمياً الذي يعمل بدون إنترنت.",
  applicationName: "Hisabati",
  authors: [{ name: "Bassem Sabri" }],
  creator: "Bassem Sabri",
  publisher: "Hisabati Group",
  keywords: [
    "ERP", "Accounting", "Offline-First ERP", "Hisabati", "Edge AI", 
    "حساباتي", "نظام محاسبي", "Desktop ERP", "Financial Software", 
    "برنامج حسابات", "مبيعات", "Local AI"
  ],
  openGraph: {
    title: "حساباتي | Hisabati - Next-Gen Offline ERP",
    description: "The ultimate offline-first ERP & Accounting System. 100% Local Privacy with built-in Edge AI. أحدث ثورة في حساباتك.",
    url: "https://hisabati.com",
    siteName: "Hisabati ERP",
    images: [
      {
        url: "/dashboard-mockup.png", 
        width: 1200,
        height: 630,
        alt: "Hisabati ERP Dashboard",
      }
    ],
    locale: "en_US",
    alternateLocale: ["ar_SA"],
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Hisabati - The Global Offline-First ERP",
    description: "The ultimate offline-first ERP & Accounting System with Local Edge AI.",
    images: ["/dashboard-mockup.png"],
    creator: "@hisabati",
  },
  icons: {
    icon: "/hisabatilogo.png",
    shortcut: "/hisabatilogo.png",
    apple: "/hisabatilogo.png",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  verification: {
    google: "lu0jjgdOVJB6j4lttjgJhttLJvlrReC8mcu4cV_TFb4",
  },
};


export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'حساباتي',
    applicationCategory: 'FinanceApplication',
    operatingSystem: 'Web',
    url: 'https://hisabati.pages.dev',
    offers: {
      '@type': 'Offer',
      price: '0', 
      priceCurrency: 'USD',
    },
  };

  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body className={`${inter.className} min-h-screen flex flex-col bg-background text-foreground overflow-x-hidden`}>
        <ThemeProvider>
          <LanguageProvider>
            {children}
          </LanguageProvider>
        </ThemeProvider>
      </body>
      <GoogleAnalytics gaId="G-YOUR_MEASUREMENT_ID" />
    </html>
  );
}


