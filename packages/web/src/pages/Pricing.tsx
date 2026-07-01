import { Link } from 'react-router-dom';
import SEOHead from '../components/SEOHead';

const plans = [
  {
    name: 'Free',
    price: '$0',
    audience: 'For new players and casual puzzle sessions.',
    cta: 'Download Free',
    href: '/download',
    featured: false,
    features: [
      'Full falling-squares gameplay',
      'Saved scores when signed in',
      'Global and weekly leaderboards',
      'Ads outside active puzzle play',
    ],
  },
  {
    name: 'Remove Ads',
    price: '$2.99',
    audience: 'For focused players who want uninterrupted sessions.',
    cta: 'Start Free First',
    href: '/download',
    featured: true,
    features: [
      'Everything in Free',
      'One-time purchase',
      'Removes ad placements',
      'No score or leaderboard advantage',
    ],
  },
  {
    name: 'Premium Content',
    price: 'Planned',
    audience: 'For players who want more challenge after mastering the base game.',
    cta: 'Follow Updates',
    href: '/download',
    featured: false,
    features: [
      'Future challenge modes',
      'Additional challenge content',
      'No pay-to-win mechanics',
      'Scope announced before release',
    ],
  },
];

const personaFit = [
  {
    persona: 'Puzzle Enthusiast',
    recommendation: 'Start Free, then use Remove Ads if the game becomes a daily break.',
  },
  {
    persona: 'Competitive Player',
    recommendation: 'Free has the leaderboard loop. Remove Ads only improves focus between attempts.',
  },
  {
    persona: 'Math-Curious Student',
    recommendation: 'Free is enough to learn divisibility patterns. Upgrades should never create pressure.',
  },
];

export default function Pricing() {
  return (
    <>
      <SEOHead
        title="Pricing"
        description="Compare Modulo Squares plans. Play falling-squares gameplay free, remove ads with a one-time purchase, and see how future premium content will stay fair."
        path="/pricing"
      />
      <section className="section-padding bg-white">
        <div className="container-max">
          <div className="max-w-3xl mb-12">
            <p className="text-sm font-semibold uppercase tracking-wide text-primary-700 mb-3">
              Plans and upgrades
            </p>
            <h1 className="text-3xl md:text-5xl font-bold text-gray-950 mb-4">
              Play the real game free. Pay only for focus or future content.
            </h1>
            <p className="text-xl text-gray-600">
              Modulo Squares should be easy to trust: no pay-to-win boosts, no hidden
              gameplay lockout, and clear upgrade reasons before a player spends.
            </p>
          </div>

          <div className="grid lg:grid-cols-3 gap-5 mb-14">
            {plans.map((plan) => (
              <article
                key={plan.name}
                className={`rounded-lg border p-6 flex flex-col ${
                  plan.featured
                    ? 'border-primary-600 shadow-xl bg-primary-50'
                    : 'border-gray-200 bg-white shadow-sm'
                }`}
              >
                {plan.featured && (
                  <p className="text-xs font-bold uppercase tracking-wide text-primary-700 mb-3">
                    Best for daily players
                  </p>
                )}
                <h2 className="text-2xl font-bold text-gray-950">{plan.name}</h2>
                <p className="text-4xl font-bold text-gray-950 mt-3">{plan.price}</p>
                <p className="text-gray-600 mt-3 mb-6">{plan.audience}</p>
                <ul className="space-y-3 text-sm text-gray-700 mb-8 flex-1">
                  {plan.features.map((feature) => (
                    <li key={feature} className="flex gap-3">
                      <span className="mt-1 h-2 w-2 rounded-full bg-emerald-500 shrink-0" />
                      <span>{feature}</span>
                    </li>
                  ))}
                </ul>
                <Link
                  to={plan.href}
                  className={plan.featured ? 'btn-primary text-center' : 'btn-secondary text-center'}
                >
                  {plan.cta}
                </Link>
              </article>
            ))}
          </div>

          <div className="grid lg:grid-cols-[0.8fr_1.2fr] gap-8 items-start">
            <div>
              <h2 className="text-2xl font-bold text-gray-950 mb-3">
                Which plan fits each player?
              </h2>
              <p className="text-gray-600">
                The plan story should reinforce the persona story. Each group needs a
                different reason to believe the game respects their time and money.
              </p>
            </div>
            <div className="grid gap-4">
              {personaFit.map((item) => (
                <article key={item.persona} className="border border-gray-200 rounded-lg p-5 bg-gray-50">
                  <h3 className="font-bold text-gray-950 mb-1">{item.persona}</h3>
                  <p className="text-gray-600">{item.recommendation}</p>
                </article>
              ))}
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
