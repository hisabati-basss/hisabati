export const TrustMarquee = () => {
  return (
    <div className="py-12 border-y border-foreground/5 bg-background overflow-hidden flex whitespace-nowrap">
      <div className="animate-marquee flex gap-16 items-center px-8 opacity-50 grayscale hover:grayscale-0 transition-all duration-500">
        <span className="text-2xl font-black font-serif tracking-widest">STRIPE</span>
        <span className="text-2xl font-black tracking-tighter">VISA</span>
        <span className="text-xl font-bold uppercase border-2 border-current px-2">ISO 27001</span>
        <span className="text-2xl font-bold italic text-blue-600">PayPal</span>
        <span className="text-2xl font-black">GDPR Ready</span>
        <span className="text-2xl font-mono border border-current px-3 rounded-lg">SQLite</span>
      </div>
      <div className="animate-marquee flex gap-16 items-center px-8 opacity-50 grayscale hover:grayscale-0 transition-all duration-500" aria-hidden="true">
        <span className="text-2xl font-black font-serif tracking-widest">STRIPE</span>
        <span className="text-2xl font-black tracking-tighter">VISA</span>
        <span className="text-xl font-bold uppercase border-2 border-current px-2">ISO 27001</span>
        <span className="text-2xl font-bold italic text-blue-600">PayPal</span>
        <span className="text-2xl font-black">GDPR Ready</span>
        <span className="text-2xl font-mono border border-current px-3 rounded-lg">SQLite</span>
      </div>
    </div>
  );
};
