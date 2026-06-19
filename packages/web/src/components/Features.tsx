import { Link } from 'react-router-dom';
import SEOHead from './SEOHead';

const features = [
  {
    icon: '⬇️',
    title: 'Falling Numbers',
    description:
      'Each round a number drops from the top. Move it left or right before the timer expires — or tap Drop to send it down instantly.',
  },
  {
    icon: '➗',
    title: 'Divisibility Rules',
    description:
      'Land your number in a bucket whose value divides it evenly and score points equal to the bucket value. Wrong bucket? You lose points.',
  },
  {
    icon: '🏆',
    title: 'Global & Weekly Leaderboards',
    description:
      'Compete with players worldwide. Earn ranked badges — Legend, Diamond, Gold, Silver, and Bronze — on the weekly ladder.',
  },
  {
    icon: '📅',
    title: 'Daily Challenges',
    description:
      'A new challenge drops every day with its own leaderboard. Come back daily to set your best time and climb the ranks.',
  },
  {
    icon: '📈',
    title: 'Progressive Difficulty',
    description:
      'Every level the tile falls faster, the number range widens, and combos push your score further. How high can you climb?',
  },
  {
    icon: '👁',
    title: 'Visual Cues',
    description:
      'Toggle bucket highlights to see at a glance which buckets will accept your current number — great for learning, toggleable for challenge.',
  },
];

const Features: React.FC = () => {
  return (
    <>
    <SEOHead
      title="How It Works"
      description="Learn how to play Modulo Squares. Drop falling numbers into matching divisor buckets, score points, and level up as speed and difficulty increase."
      path="/how-it-works"
    />
    <section className="section-padding bg-white">
      <div className="container-max">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
            Simple to Learn. Hard to Put Down.
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            One mechanic, infinite depth. Guide falling numbers into the right buckets and watch your score climb.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <div
              key={index}
              className="bg-gray-50 rounded-xl p-6 hover:shadow-lg transition-shadow duration-300"
            >
              <div className="text-4xl mb-4">{feature.icon}</div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">
                {feature.title}
              </h3>
              <p className="text-gray-600">{feature.description}</p>
            </div>
          ))}
        </div>

        <div className="mt-16 text-center">
          <div className="bg-linear-to-r from-primary-500 to-secondary-500 rounded-2xl p-8 text-white">
            <h3 className="text-2xl font-bold mb-4">Ready to Test Your Division Skills?</h3>
            <p className="text-lg mb-6 opacity-90">
              Download free on iOS and Android. No ads in the game — just pure puzzle focus.
            </p>
            <Link
              to="/download"
              className="inline-block bg-white text-primary-600 font-semibold py-3 px-8 rounded-lg hover:bg-gray-50 transition-colors"
            >
              Get the App
            </Link>
          </div>
        </div>
      </div>
    </section>
    </>
  );
};

export default Features;
