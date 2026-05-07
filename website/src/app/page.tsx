"use client";

import { Navbar } from "@/components/Navbar";
import { DynamicIsland } from "@/components/DynamicIsland";
import { Hero } from "@/components/Hero";
import { TrustMarquee } from "@/components/TrustMarquee";
import { HowItWorks } from "@/components/HowItWorks";
import { Features } from "@/components/Features";
import { IndustrySolutions } from "@/components/IndustrySolutions";
import { EdgeAI } from "@/components/EdgeAI";
import { DemoVideo } from "@/components/DemoVideo";
import { Marketing } from "@/components/Marketing";
import { Comparison } from "@/components/Comparison";
import { Testimonials } from "@/components/Testimonials";
import { Affiliate } from "@/components/Affiliate";
import { Pricing } from "@/components/Pricing";
import { FAQ } from "@/components/FAQ";
import { Contact } from "@/components/Contact";
import { Footer } from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Navbar />
      <DynamicIsland />
      <main className="flex-1 w-full flex flex-col">
        <Hero />
        <TrustMarquee />
        <HowItWorks />
        <Features />
        <IndustrySolutions />
        <EdgeAI />
        <DemoVideo />
        <Marketing />
        <Comparison />
        <Testimonials />
        <Affiliate />
        <Pricing />
        <FAQ />
        <Contact />
      </main>
      <Footer />
    </>
  );
}
