import { Link } from 'react-router-dom';
import SEOHead from './SEOHead';

const APP_JSON_LD = {
  '@context': 'https://schema.org',
  '@type': 'MobileApplication',
  name: 'Modulo Squares',
  description: 'Guide falling numbers into the right divisor buckets. Score, level up, and climb the global leaderboard.',
  applicationCategory: 'GameApplication',
  genre: 'Puzzle',
  operatingSystem: 'iOS, Android',
  offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
  aggregateRating: { '@type': 'AggregateRating', ratingValue: '5', ratingCount: '1' },
  url: 'https://modulosquares.com',
};

const BUCKETS = [2, 3, 4, 5, 6];
const FALLING_VALUE = 12;
const ACTIVE_LANE = 2; // 0-based, lands in bucket ÷4

const Hero: React.FC = () => {
  return (
    <>
    <SEOHead
      title="Modulo Squares — Falling Number Puzzle Game"
      description="Guide falling numbers into the right divisor buckets. Score, level up, and climb the global leaderboard. Free on iOS and Android."
      path=""
      jsonLd={APP_JSON_LD}
    />
    <section className="py-16 bg-linear-to-br from-primary-50 to-secondary-50">
      <div className="container-max">
        <div className="grid lg:grid-cols-2 gap-12 items-center">

          {/* Copy */}
          <div className="text-center lg:text-left">
            <h1 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
              Numbers Fall.
              <span className="text-primary-600 block">You Choose Where.</span>
            </h1>
            <p className="text-xl text-gray-600 mb-4 max-w-2xl">
              Each round, a number drops from the top. Slide it left or right — or tap Drop to send it instantly — and land it in a bucket whose value divides it evenly.
            </p>
            <p className="text-xl text-gray-600 mb-8 max-w-2xl">
              Score with every clean division. Miss and you lose points. Level up as speed and range increase.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
              <Link to="/download" className="btn-primary text-lg px-8 py-4 text-center">
                Download Free
              </Link>
              <Link to="/how-it-works" className="btn-secondary text-lg px-8 py-4 text-center">
                How It Works
              </Link>
            </div>
          </div>

          {/* Game mock */}
          <div className="flex justify-center">
            <div
              className="rounded-2xl shadow-2xl p-6 w-72"
              style={{ background: 'linear-gradient(to bottom, #eceff1, #cfd8dc)' }}
            >
              {/* Score bar */}
              <div className="flex justify-between text-xs font-semibold text-gray-500 mb-3 px-1">
                <span>Level: 3</span>
                <span>Score: 840</span>
                <span>Best: 1 247</span>
              </div>

              {/* Fall lanes */}
              <div className="relative" style={{ height: '160px' }}>
                <div className="absolute inset-0 flex">
                  {BUCKETS.map((_, i) => (
                    <div
                      key={i}
                      className="flex-1 border-r border-gray-300/40 last:border-r-0"
                    />
                  ))}
                </div>

                {/* Falling tile */}
                <div
                  className="absolute flex items-center justify-center rounded-lg font-bold text-white text-xl shadow-lg"
                  style={{
                    width: `${100 / BUCKETS.length}%`,
                    height: '44px',
                    left: `${(ACTIVE_LANE / BUCKETS.length) * 100}%`,
                    top: '60px',
                    backgroundColor: '#5c6bc0',
                  }}
                >
                  {FALLING_VALUE}
                </div>
              </div>

              {/* Buckets */}
              <div className="flex gap-1 mt-1">
                {BUCKETS.map((divisor, i) => {
                  const isMatch = FALLING_VALUE % divisor === 0;
                  const isActive = i === ACTIVE_LANE;
                  return (
                    <div
                      key={i}
                      className="flex-1 rounded-lg py-3 flex items-center justify-center font-bold text-sm shadow"
                      style={{
                        backgroundColor: isActive
                          ? '#4caf50'
                          : isMatch
                          ? '#a5d6a7'
                          : '#e0e0e0',
                        color: isActive || isMatch ? '#1b5e20' : '#616161',
                      }}
                    >
                      ÷{divisor}
                    </div>
                  );
                })}
              </div>

              {/* Controls hint */}
              <div className="flex gap-1 mt-3">
                {['←', 'Drop', '→'].map((label) => (
                  <div
                    key={label}
                    className={`rounded-lg py-2 text-center text-xs font-semibold text-gray-700 bg-white shadow ${label === 'Drop' ? 'flex-2' : 'flex-1'}`}
                  >
                    {label}
                  </div>
                ))}
              </div>
            </div>
          </div>

        </div>
      </div>
    </section>
    </>
  );
};

export default Hero;
