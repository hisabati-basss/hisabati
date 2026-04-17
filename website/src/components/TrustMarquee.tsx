export const TrustMarquee = () => {
  const baseLogos = [
    <span key="1" className="text-2xl font-black font-serif tracking-widest">STRIPE</span>,
    <span key="2" className="text-2xl font-black tracking-tighter">VISA</span>,
    <span key="3" className="text-xl font-bold uppercase border-2 border-current px-2">ISO 27001</span>,
    <img key="dev" src="/dev-logo.svg" alt="Dev Logo" className="h-10 w-auto object-contain" />,
    <span key="4" className="text-2xl font-bold italic text-blue-600">PayPal</span>,
    <span key="5" className="text-2xl font-black">GDPR Ready</span>,
    <span key="6" className="text-2xl font-mono border border-current px-3 rounded-lg">SQLite</span>,
  ];

  // We duplicate the set twice for the -50% trick, and each set is repeated internally to ensure length.
  const fullSet = [...baseLogos, ...baseLogos, ...baseLogos];
  const allLogos = [...fullSet, ...fullSet];

  return (
    <div className="py-12 border-y border-foreground/5 bg-background overflow-hidden flex">
      <div className="animate-marquee flex flex-shrink-0 items-center gap-16 pr-16">
        {allLogos.map((logo, index) => (
          <div key={index} className="opacity-40 grayscale hover:grayscale-0 hover:opacity-100 transition-all duration-300 cursor-pointer hover:scale-110">
            {logo}
          </div>
        ))}
      </div>
    </div>
  );
};
