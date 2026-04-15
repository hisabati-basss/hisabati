"use client";

import { Navbar } from "@/components/Navbar";
import { Hero } from "@/components/Hero";
import { Features } from "@/components/Features";
import { HowItWorks } from "@/components/HowItWorks";
import { EdgeAI } from "@/components/EdgeAI";
import { Marketing } from "@/components/Marketing";
import { Comparison } from "@/components/Comparison";
import { Affiliate } from "@/components/Affiliate";
import { Pricing } from "@/components/Pricing";
import { FAQ } from "@/components/FAQ";
import { TrustMarquee } from "@/components/TrustMarquee";
import { Footer } from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Navbar />
      <main className="flex-1 w-full flex flex-col gap-8 md:gap-16">
        <Hero />
        <HowItWorks />
        <Features />
        <EdgeAI />
        <Marketing />
        <Comparison />
        <Affiliate />
        <Pricing />
        <FAQ />
        <TrustMarquee />
      </main>
      <Footer />
    </>
  );
}
