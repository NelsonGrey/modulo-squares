import { Link } from 'react-router-dom';
import SEOHead from './SEOHead';

const APP_JSON_LD = {
  '@context': 'https://schema.org',
  '@type': 'MobileApplication',
  name: 'Modulo Squares',
  description:
    'A falling-squares math puzzle where players guide numbered tiles into divisor buckets, score clean divisions, and climb leaderboards.',
  applicationCategory: 'GameApplication',
  genre: 'Puzzle',
  operatingSystem: 'iOS',
  offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
  url: 'https://modulosquares.com',
};

const BUCKETS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];
const FALLING_VALUE = 18;
const ACTIVE_LANE = 5;

const PERSONAS = [
  {
    label: 'Puzzle Enthusiast',
    headline: 'A smarter break than another match-3.',
    body:
      'Fast drops, clean rules, and enough pressure to make every correct landing feel earned.',
    proof: 'Best for commute breaks, evening downtime, and players who like mastery over luck.',
    accent: 'border-primary-500',
  },
  {
    label: 'Competitive Player',
    headline: 'Turn personal bests into a weekly chase.',
    body:
      'Improve reaction time, climb live leaderboards, and compete for weekly badges without pay-to-win shortcuts.',
    proof: 'Best for score chasers, daily challenge players, and friends who trade screenshots.',
    accent: 'border-secondary-500',
  },
  {
    label: 'Math-Curious Student',
    headline: 'Math practice that feels like a game first.',
    body:
      'Divisibility turns into pattern recognition through quick decisions, visual cues, and repeated wins.',
    proof: 'Best for students, parents, and anyone rebuilding math confidence.',
    accent: 'border-emerald-500',
  },
];

const PLAN_SUMMARY = [
  {
    name: 'Free',
    description: 'Full falling-squares gameplay, saved progress, and leaderboard access with fair ad placement.',
  },
  {
    name: 'Remove Ads',
    description: 'A one-time upgrade for players who want uninterrupted focus.',
  },
  {
    name: 'Premium Content',
    description: 'Future challenge modes and content when the catalog is ready.',
  },
];

function FallingSquaresMock() {
  return (
    <div className="bg-white rounded-xl shadow-2xl border border-gray-200 p-5 w-full max-w-sm">
      <div className="flex items-center justify-between text-xs font-semibold text-gray-500 mb-4">
        <span>Level 6</span>
        <span>Score 1,840</span>
        <span>Next 0.82s</span>
      </div>
      <div className="relative h-64 rounded-lg bg-linear-to-b from-surface-start to-surface-end overflow-hidden border border-gray-200">
        <div className="absolute inset-0 grid grid-cols-10">
          {BUCKETS.map((bucket, index) => (
            <div key={`${bucket}-${index}`} className="border-r border-white/40 last:border-r-0" />
          ))}
        </div>
        <div
          className="absolute top-20 rounded-lg bg-secondary-600 text-white shadow-lg flex items-center justify-center text-2xl font-bold"
          style={{
            width: `${100 / BUCKETS.length}%`,
            height: '48px',
            left: `${(ACTIVE_LANE / BUCKETS.length) * 100}%`,
          }}
        >
          {FALLING_VALUE}
        </div>
        <div className="absolute left-3 right-3 bottom-16 h-3 rounded-full bg-white/70 overflow-hidden">
          <div className="h-full w-[72%] bg-primary-600" />
        </div>
        <div className="absolute left-0 right-0 bottom-0 grid grid-cols-10 gap-1 p-2">
          {BUCKETS.map((bucket, index) => {
            const isDead = bucket === 0;
            const isMatch = !isDead && FALLING_VALUE % bucket === 0;
            const isActive = index === ACTIVE_LANE;
            return (
              <div
                key={`${bucket}-bucket`}
                className={`h-12 rounded-md flex items-center justify-center text-sm font-bold shadow ${
                  isDead
                    ? 'bg-red-100 text-red-700'
                    : isActive
                    ? 'bg-emerald-500 text-white'
                    : isMatch
                    ? 'bg-emerald-100 text-emerald-800'
                    : 'bg-white text-gray-600'
                }`}
              >
                {isDead ? 'Dead' : bucket}
              </div>
            );
          })}
        </div>
      </div>
      <div className="mt-4 rounded-lg bg-gray-900 text-white px-4 py-3">
        <p className="text-sm font-semibold">Land 18 in bucket 6</p>
        <p className="text-xs text-gray-300">18 % 6 = 0. Clean division scores 18 x 6 points.</p>
      </div>
    </div>
  );
}

const Hero: React.FC = () => {
  return (
    <>
      <SEOHead
        title="Modulo Squares - Falling Squares Math Puzzle"
        description="Guide falling numbered squares into divisor buckets. Score clean divisions, avoid the Dead bucket, and climb leaderboards. Free on iPhone."
        path=""
        jsonLd={APP_JSON_LD}
      />
      <section className="bg-white">
        <div className="container-max px-4 sm:px-6 lg:px-8 py-14 lg:py-20">
          <div className="grid lg:grid-cols-[1.05fr_0.95fr] gap-8 lg:gap-12 items-center">
            <div className="text-center lg:text-left lg:col-start-1 lg:row-start-1">
              <p className="text-sm font-semibold uppercase tracking-wide text-primary-700 mb-4">
                Falling squares math puzzle for iPhone
              </p>
              <h1 className="text-4xl md:text-6xl font-bold text-gray-950 mb-6">
                Catch the right divisor before the square drops.
              </h1>
              <p className="text-xl text-gray-600 mb-5 max-w-2xl">
                Modulo Squares turns divisibility into a fast, strategic arcade puzzle:
                guide each falling numbered square into a bucket that divides it evenly.
              </p>
              <p className="text-lg text-gray-600 mb-8 max-w-2xl">
                Clean landings score big, misses cost points, and each level raises the
                number range and drop speed.
              </p>
            </div>

            <div className="flex justify-center lg:col-start-2 lg:row-span-2">
              <FallingSquaresMock />
            </div>

            <div className="flex flex-col sm:flex-row gap-3 justify-center lg:justify-start lg:col-start-1 lg:row-start-2">
              <Link to="/download" className="btn-primary text-lg px-8 py-4 text-center">
                Download Free
              </Link>
              <Link to="/pricing" className="btn-secondary text-lg px-8 py-4 text-center">
                Compare Plans
              </Link>
            </div>
          </div>
        </div>
      </section>

      <section className="bg-gray-50 border-y border-gray-200">
        <div className="container-max px-4 sm:px-6 lg:px-8 py-14">
          <div className="max-w-3xl mb-10">
            <p className="text-sm font-semibold uppercase tracking-wide text-primary-700 mb-3">
              Built around real play styles
            </p>
            <h2 className="text-3xl md:text-4xl font-bold text-gray-950">
              Choose the reason you play. The game supports each one.
            </h2>
          </div>
          <div className="grid lg:grid-cols-3 gap-5">
            {PERSONAS.map((persona) => (
              <article
                key={persona.label}
                className={`bg-white border-t-4 ${persona.accent} rounded-lg p-6 shadow-sm`}
              >
                <p className="text-sm font-semibold text-gray-500 mb-3">{persona.label}</p>
                <h3 className="text-2xl font-bold text-gray-950 mb-3">{persona.headline}</h3>
                <p className="text-gray-600 mb-5">{persona.body}</p>
                <p className="text-sm font-medium text-gray-800">{persona.proof}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-white">
        <div className="container-max px-4 sm:px-6 lg:px-8 py-14">
          <div className="grid lg:grid-cols-[0.85fr_1.15fr] gap-10 items-start">
            <div>
              <p className="text-sm font-semibold uppercase tracking-wide text-primary-700 mb-3">
                Fair monetization
              </p>
              <h2 className="text-3xl md:text-4xl font-bold text-gray-950 mb-4">
                Free to start. Clear reasons to upgrade.
              </h2>
              <p className="text-lg text-gray-600 mb-6">
                The site should make the business model obvious: free players get the
                real game, paying players buy focus and future content, never power.
              </p>
              <Link to="/pricing" className="btn-primary inline-block">
                See Pricing
              </Link>
            </div>
            <div className="grid sm:grid-cols-3 gap-4">
              {PLAN_SUMMARY.map((plan) => (
                <div key={plan.name} className="border border-gray-200 rounded-lg p-5 bg-gray-50">
                  <h3 className="font-bold text-gray-950 mb-2">{plan.name}</h3>
                  <p className="text-sm text-gray-600">{plan.description}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>
    </>
  );
};

export default Hero;
