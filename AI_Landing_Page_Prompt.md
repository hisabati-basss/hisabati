# Prompt Engineering: Hisabati Landing Page
**Target AI Agent:** Elite Frontend Next.js Developer & UX Motion Designer

---

## 1. Context & System Role
You are a World-Class Frontend Engineer and UI/UX Designer specializing in high-converting, blazing-fast SaaS landing pages. 
Your objective is to build a professional, single-page landing page for **"Hisabati" (حساباتي)**, an Offline-First ERP and Accounting System. 

**CRITICAL INSTRUCTION:** Do NOT use Flutter Web. You must build this landing page using **Next.js (App Router)**, **Tailwind CSS**, and **Framer Motion** for maximum performance, SEO, and load speed.

## 2. Core Vibe & Design Language (The "Apple" Standard)
- **Theme Support:** Must natively support **Light Mode** and **Dark Mode** seamlessly via `next-themes` with a smooth toggle.
- **Aesthetic:** Apple/Google-tier minimalism. Extremely premium, structural, and clean. Use a Dark Mode base with white, subtle gold, and light-blue modern accents to imply luxury and security.
- **Motion & Interactions (Crucial):**
  - Implement fluid, Apple-style spring animations for interactions.
  - Use `Framer Motion` for scroll-triggered reveal animations (fade-in, slide up).
  - Apply glassmorphism (frosted glass effects) on the Navigation bar and floating cards.
  - Magnetic hover effects on main Call to Action (CTA) buttons.

## 3. Structure & Required Sections

### 3.1. Glassmorphic Navigation Bar
- A sleek, sticky, frosted-glass header.
- **Left:** The Developer's / App's Logo (use a placeholder if needed).
- **Middle:** Quick links (Features, AI Security, Affiliate, Pricing).
- **Right:** Social Media Icons (LinkedIn, Facebook, etc.), Theme Toggle (Sun/Moon), and a magnetic "Join Hisabati" CTA button.

### 3.2. Hero Section (The Hook)
- **Greeting & Hook:** A powerful, welcoming introduction.
- **Headline:** Bold, dynamic typography. Example: *"Revolutionize Your Accounting. Online, Offline, Anytime."* 
- **Visuals:** Implement a 3D-effect floating isometric mockup displaying the Hisabati Dashboard (PC and Mobile).
- **Smart OS Download Button:** Create a dynamic button component that detects the user's OS (Windows, macOS, iOS, Android) and offers the correct download link directly, with smaller "Also available on..." links underneath.

### 3.3. Core ERP Features (Inspired by QuickBooks World-Class UX)
- Highlight massive capabilities similar to top-tier ERPs like QuickBooks:
  - Automated tracking of expenses and multi-currency cash flows.
  - Professional formatting for instant invoice generation.
  - Real-time financial analytics dashboard.
- **Visuals:** Interactive cards that tilt/highlight smoothly upon hover.

### 3.4. Edge AI & Security Shield (Zero Cloud Dependency)
- **Headline:** *"Your Data. Your Power. Local Edge AI."*
- **Explanation:** Clearly explain that the built-in Hisabati AI Agent does **not** rely on cloud APIs. It processes all tasks and automation **locally on the user's device**. Zero data leaves the network without permission.
- **Animation:** An animated local shield icon blocking data from floating to a cloud.

### 3.5. Business Growth & Marketing Engine
- **Headline:** *"Scale Fast with Built-in Marketing Tools."*
- **Content:** Showcase the ability to seamlessly send up to 1,000 professional marketing/invoicing emails instantly from inside Hisabati.
- **Animation:** An envelope/email list beautifully animating into outgoing mail streams.

### 3.6. Competitive Comparison Table
- Provide a sleek, animated grid comparing Hisabati vs. Cloud ERPs (Odoo, QuickBooks).
- **Key metrics:**
  - Offline Access: Hisabati (✅) vs Others (❌)
  - Local AI Privacy: Hisabati (✅) vs Others (❌)
  - Zero Cloud Latency: Hisabati (✅) vs Others (❌)
  - Cross-Platform Sync: Hisabati (✅) vs Others (✅)

### 3.7. Affiliate, Paid Promotions & Partners Program
- **Headline:** *"Partner with Hisabati. Earn Passive Income."*
- **Content:** Detail the powerful affiliate marketing features. Explain the recurring commission model, how to generate invite links, and run paid promotional campaigns.
- Include a specific CTA: *"Become an Affiliate"*.

### 3.8. Trust & Integrations Marquee
- A subtle, infinite scrolling marquee in grayscale displaying trust logos.
- Examples: ISO Security standard, GDPR, Stripe, Visa, SQLite.

### 3.9. Comprehensive Developer Footer
- **Branding:** Feature the primary Developer's Name, Developer Data, and Logo prominently.
- **Socials:** Full array of social links (LinkedIn, X, Facebook, GitHub).
- **Utility:** Links to Privacy Policy, Terms, and an Arabic/English Language Switcher.

## 4. Final Constraints for the AI Code Generation
- Ensure code is fully responsive (Mobile, Tablet, 4K Desktop).
- Write professional, high-converting copywriting (ideally prepare for i18n structure for Arabic & English).
- Do not leave empty boilerplate; provide functional, detailed Tailwind components and proper Framer Motion configurations.
- Guarantee high Lighthouse SEO and Performance scores. Use semantic HTML tags.
