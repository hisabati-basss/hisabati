export const TrustMarquee = () => {
  const baseLogos = [
    <span key="1" className="text-2xl font-black font-serif tracking-widest">STRIPE</span>,
    <span key="2" className="text-2xl font-black tracking-tighter">VISA</span>,
    <img key="3" src="/hisabatilogo.png" alt="Hisabati Logo" className="h-10 w-auto object-contain" />,
    <span key="4" className="text-xl font-bold uppercase border-2 border-current px-2">ISO 27001</span>,
    <img key="dev" src="/dev-logo.svg" alt="Dev Logo" className="h-10 w-auto object-contain" />,
    <span key="5" className="text-2xl font-bold italic text-blue-600">PayPal</span>,
    <img key="6" src="/hisabatilogo.png" alt="Hisabati Logo" className="h-10 w-auto object-contain" />,
    <span key="7" className="text-2xl font-black">GDPR Ready</span>,
    <span key="8" className="text-2xl font-mono border border-current px-3 rounded-lg">SQLite</span>,
  ];

  // Duplicate the array to ensure the width is larger than ultra-wide monitors for a perfect seamless loop
  const logos = [...baseLogos, ...baseLogos];

  return (
    <div className="py-12 border-y border-foreground/5 bg-background overflow-hidden flex gap-16 whitespace-nowrap">
      <div className="animate-marquee flex gap-16 items-center px-8 flex-shrink-0">
        {logos.map((logo, index) => (
          <div key={`logo-1-${index}`} className="opacity-40 grayscale hover:grayscale-0 hover:opacity-100 transition-all duration-300 cursor-pointer hover:scale-110">
            {logo}
          </div>
        ))}
      </div>
      <div className="animate-marquee flex gap-16 items-center px-8 flex-shrink-0" aria-hidden="true">
        {logos.map((logo, index) => (
          <div key={`logo-2-${index}`} className="opacity-40 grayscale hover:grayscale-0 hover:opacity-100 transition-all duration-300 cursor-pointer hover:scale-110">
            {logo}
          </div>
        ))}
      </div>
    </div>
  );
};
