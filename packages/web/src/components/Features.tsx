import { Link } from 'react-router-dom';
import SEOHead from './SEOHead';

const steps = [
  {
    title: 'Read the falling square',
    description:
      'A numbered square drops from the top. Scan the value, the bucket row, and the timer pressure.',
  },
  {
    title: 'Choose a lane',
    description:
      'Move left or right, or tap Drop, to land the square in a bucket before time runs out.',
  },
  {
    title: 'Score clean division',
    description:
      'If the falling value divides evenly by the bucket value, you score. A remainder costs points.',
  },
  {
    title: 'Fill the level meter',
    description:
      'Fill 100 squares to complete a level. Each new level increases the number range and drop speed.',
  },
];

const benefits = [
  {
    title: 'Simple rule, real depth',
    description:
      'Divisibility gives every landing a predictable result, so progress comes from pattern recognition under pressure.',
  },
  {
    title: 'Short sessions',
    description:
      'Fast rounds and quick restarts make a five-minute break feel satisfying.',
  },
  {
    title: 'Learning without lectures',
    description:
      'Players practice factors, remainders, and divisibility through decisions, feedback, and repeated wins.',
  },
  {
    title: 'Competition with guardrails',
    description:
      'Leaderboards reward skill and persistence. Upgrades are for focus and content, not score advantages.',
  },
];

const Features: React.FC = () => {
  return (
    <>
      <SEOHead
        title="How It Works"
        description="Learn how to play Modulo Squares. Guide falling numbered squares into divisor buckets, score clean divisions, avoid the Dead bucket, and level up."
        path="/how-it-works"
      />
      <section className="section-padding bg-white">
        <div className="container-max">
          <div className="max-w-3xl mb-12">
            <p className="text-sm font-semibold uppercase tracking-wide text-primary-700 mb-3">
              How the puzzle works
            </p>
            <h1 className="text-3xl md:text-5xl font-bold text-gray-950 mb-4">
              Guide each falling square into the right bucket.
            </h1>
            <p className="text-xl text-gray-600">
              Modulo Squares is easy to start because the rule is consistent:
              if the bucket divides the falling number evenly, you score.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-5 mb-16">
            {steps.map((step, index) => (
              <article key={step.title} className="bg-gray-50 border border-gray-200 rounded-lg p-6">
                <div className="w-9 h-9 rounded-lg bg-primary-600 text-white flex items-center justify-center font-bold mb-5">
                  {index + 1}
                </div>
                <h2 className="text-xl font-bold text-gray-950 mb-3">{step.title}</h2>
                <p className="text-gray-600">{step.description}</p>
              </article>
            ))}
          </div>

          <div className="grid lg:grid-cols-[0.9fr_1.1fr] gap-10 items-start">
            <div className="bg-gray-900 text-white rounded-lg p-7">
              <h2 className="text-2xl font-bold mb-4">Example landing</h2>
              <p className="text-gray-300 mb-5">
                Land an 18 square in the 6 bucket. Since 18 % 6 is 0, the
                landing scores. If there is a remainder, the miss costs points.
              </p>
              <div className="grid grid-cols-3 gap-2 text-center font-bold">
                <div className="rounded-lg bg-white text-gray-900 p-4">18</div>
                <div className="rounded-lg bg-primary-500 text-white p-4">into</div>
                <div className="rounded-lg bg-white text-gray-900 p-4">6</div>
                <div className="col-span-3 rounded-lg bg-emerald-500 text-white p-4">
                  18 % 6 = 0, clean division
                </div>
              </div>
            </div>

            <div className="grid sm:grid-cols-2 gap-5">
              {benefits.map((benefit) => (
                <article key={benefit.title} className="border border-gray-200 rounded-lg p-6">
                  <h2 className="text-xl font-bold text-gray-950 mb-3">{benefit.title}</h2>
                  <p className="text-gray-600">{benefit.description}</p>
                </article>
              ))}
            </div>
          </div>

          <div className="mt-14 bg-primary-50 border border-primary-100 rounded-lg p-8 text-center">
            <h2 className="text-2xl font-bold text-gray-950 mb-3">
              Ready to test the pattern?
            </h2>
            <p className="text-lg text-gray-600 mb-6">
              Download free on iPhone, then decide later whether an ad-free upgrade is worth it.
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

export default Features;
