import { Link } from 'react-router';
import SEOHead from '../components/SEOHead';

const DIVISIBILITY_TRICKS = [
  { n: 2, rule: 'The last digit is even (0, 2, 4, 6, 8).', example: '134 → last digit 4 is even, so 134 is divisible by 2.' },
  { n: 3, rule: 'The digits add up to a multiple of 3.', example: 'once you can add single digits fast, 3 becomes instant: 1+3+5=9, so 135 is divisible by 3.' },
  { n: 4, rule: 'The last two digits, read as their own number, divide by 4.', example: '316 → 16 ÷ 4 = 4, so 316 is divisible by 4.' },
  { n: 5, rule: 'The last digit is 0 or 5.', example: '210 → ends in 0, divisible by 5.' },
  { n: 9, rule: 'The digits add up to a multiple of 9 — same trick as 3, one level up.', example: '2+7+0=9, so 270 is divisible by 9.' },
  { n: 10, rule: 'The last digit is 0.', example: '400 → ends in 0, divisible by 10.' },
];

const MISTAKES = [
  {
    title: 'Doing full division under pressure',
    body: 'Long division on a falling tile costs you the tile. Divisibility rules exist so you never actually have to divide — you check the last digit or the digit sum and move on. If you catch yourself computing an exact quotient, you\'re working harder than the level requires.',
  },
  {
    title: 'Ignoring the Dead bucket until it\'s too late',
    body: 'New players treat the Dead bucket as pure punishment and try to avoid it at all costs, even when a tile clearly doesn\'t match any live bucket. That hesitation is what actually costs points — a fast, correct trip to Dead beats a slow, wrong guess at a live bucket every time.',
  },
  {
    title: 'Locking onto one bucket instead of scanning all of them',
    body: 'It\'s tempting to fixate on the bucket nearest your current lane. But the fastest players scan every live bucket value against the falling number the instant it spawns, before committing to a direction — by the time the tile is halfway down, the decision should already be made.',
  },
  {
    title: 'Playing the same speed at every level',
    body: 'The drop speed and number range both increase as you climb. A read-then-react rhythm that works cleanly through level 10 will get you punished by level 20. Rebuild the habit of pre-scanning buckets earlier in the drop as levels get harder, rather than trying to react faster.',
  },
];

const StrategyGuide: React.FC = () => {
  return (
    <>
      <SEOHead
        title="Strategy Guide"
        description="A real strategy guide for Modulo Squares: divisibility shortcuts, when to use the Dead bucket on purpose, how level pacing changes, and the mistakes that separate beginners from leaderboard regulars."
        path="/strategy-guide"
      />
      <section className="section-padding bg-white">
        <div className="container-max max-w-3xl">
          <p className="text-sm font-semibold uppercase tracking-wide text-primary-700 mb-3">
            Strategy guide
          </p>
          <h1 className="text-3xl md:text-5xl font-bold text-gray-950 mb-6">
            How to actually get good at Modulo Squares
          </h1>
          <p className="text-xl text-gray-600 mb-10">
            The rule is simple — land the number in a bucket it divides evenly. Getting
            good at it isn't about being fast at math, it's about never doing math at
            all. Every trick below replaces calculation with instant recognition.
          </p>

          <h2 className="text-2xl font-bold text-gray-950 mb-4">
            Divisibility shortcuts that replace mental math
          </h2>
          <p className="text-gray-700 mb-6">
            Every bucket value in the game has a shortcut that tells you whether a
            falling number belongs there, just by looking at it — no division required.
            These are the same rules taught in most elementary number theory courses,
            but here they're muscle memory you build under a timer instead of on paper.
          </p>
          <div className="grid sm:grid-cols-2 gap-4 mb-10">
            {DIVISIBILITY_TRICKS.map((t) => (
              <article key={t.n} className="bg-gray-50 border border-gray-200 rounded-lg p-5">
                <h3 className="font-bold text-gray-950 mb-1">Divisible by {t.n}</h3>
                <p className="text-gray-700 text-sm mb-2">{t.rule}</p>
                <p className="text-gray-500 text-sm italic">{t.example}</p>
              </article>
            ))}
          </div>
          <p className="text-gray-700 mb-10">
            Buckets for 6, 7, and 8 don't have a single clean digit trick — that's
            intentional, and it's what makes higher levels harder. For 6, check divisible
            by 2 <em>and</em> by 3. For 8, check whether the last three digits divide by
            8, which is really just the "divisible by 4" trick applied twice. 7 has no
            fast shortcut worth memorizing; recognizing multiples of 7 by sight is a
            skill that only comes from repetition, which is exactly why it shows up more
            often at higher levels.
          </p>

          <h2 className="text-2xl font-bold text-gray-950 mb-4">
            The Dead bucket is a tool, not just a penalty
          </h2>
          <p className="text-gray-700 mb-10">
            Every falling number that doesn't cleanly divide into any live bucket
            belongs in Dead — and choosing Dead on purpose, quickly, is a real skill.
            The players who climb the leaderboard fastest aren't the ones who avoid
            Dead entirely; they're the ones who recognize a no-match number instantly
            and route it there without hesitating, instead of burning time hunting for
            a bucket that was never going to work.
          </p>

          <h2 className="text-2xl font-bold text-gray-950 mb-4">
            How level pacing changes as you climb
          </h2>
          <p className="text-gray-700 mb-10">
            Early levels use a small number range and a forgiving drop speed, which is
            why divisibility-by-2/5/10 buckets carry most beginners through level 10.
            Past that, the number range widens and drop speed increases together, which
            is what makes 3/9 (digit-sum) and 4/8 (last-digits) buckets start to matter
            more. By the levels where 6 and 7 buckets appear regularly, the game is
            testing whether you've actually built the pattern-recognition habit, not
            whether you can do math faster under a shorter clock.
          </p>

          <h2 className="text-2xl font-bold text-gray-950 mb-4">
            Mistakes that keep players off the leaderboard
          </h2>
          <div className="space-y-6 mb-10">
            {MISTAKES.map((m) => (
              <article key={m.title} className="border-l-4 border-secondary-500 pl-5">
                <h3 className="font-bold text-gray-950 mb-1">{m.title}</h3>
                <p className="text-gray-700">{m.body}</p>
              </article>
            ))}
          </div>

          <h2 className="text-2xl font-bold text-gray-950 mb-4">
            Chasing the weekly leaderboard
          </h2>
          <p className="text-gray-700 mb-10">
            The <Link to="/leaderboard" className="text-primary-700 font-semibold hover:underline">weekly leaderboard</Link> resets
            on a fixed schedule and awards Bronze through Legend badges by rank, separate
            from the all-time board. Because it resets, a single strong session can move
            you into a badge tier even if your all-time score is far from the top — it
            rewards a good run this week, not just a lifetime of grinding.
          </p>

          <div className="bg-primary-50 border border-primary-100 rounded-lg p-8 text-center">
            <h2 className="text-2xl font-bold text-gray-950 mb-3">
              Want the mechanics explanation first?
            </h2>
            <p className="text-lg text-gray-600 mb-6">
              See <Link to="/how-it-works" className="text-primary-700 font-semibold hover:underline">how the game works</Link>,
              or read <Link to="/modular-arithmetic-explained" className="text-primary-700 font-semibold hover:underline">what modular arithmetic actually is</Link> if
              you want the math behind the divisibility rules above.
            </p>
            <Link to="/download" className="btn-primary inline-block">
              Get the App
            </Link>
          </div>
        </div>
      </section>
    </>
  );
};

export default StrategyGuide;
