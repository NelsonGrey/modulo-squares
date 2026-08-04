import { Link } from 'react-router';
import SEOHead from '../components/SEOHead';

const USES = [
  {
    title: 'Clocks and calendars',
    body: "A 12-hour clock is modular arithmetic you already use daily: 9 hours after 8 o'clock isn't 17 o'clock, it's 5 o'clock, because time wraps around every 12. That wraparound — 17 mod 12 = 5 — is the entire concept.",
  },
  {
    title: 'Cryptography',
    body: 'Modern encryption, including the RSA algorithm that secures a huge share of internet traffic, is built on modular exponentiation — raising numbers to a power and reducing the result modulo a very large number. Every HTTPS connection you use leans on this.',
  },
  {
    title: 'Hash tables',
    body: 'Software that needs to store and find data quickly (databases, caches, programming language dictionaries) commonly picks a storage slot by taking a value modulo the table size. It is one of the simplest ways to spread data evenly across a fixed number of buckets — coincidentally, the same idea as this game.',
  },
  {
    title: 'Check digits',
    body: 'The last digit of an ISBN, and the validation logic behind credit card numbers (the Luhn algorithm), both work by computing a weighted sum and checking it against a fixed modulus. It is how systems catch a single mistyped digit before it causes real damage.',
  },
  {
    title: 'Music theory',
    body: 'Pitches repeat every 12 semitones — a C is a C whether it is high or low. Musicians call this "octave equivalence," but it is modular arithmetic with a modulus of 12, the same structure as a clock.',
  },
];

const ModularArithmeticExplained: React.FC = () => {
  return (
    <>
      <SEOHead
        title="What Is Modular Arithmetic?"
        description="A plain-language explanation of modular arithmetic — what the mod operator means, worked examples, where it shows up in cryptography, hashing, and calendars, and how Modulo Squares turns it into a game."
        path="/modular-arithmetic-explained"
      />
      <section className="section-padding bg-white">
        <div className="container-max max-w-3xl">
          <p className="text-sm font-semibold uppercase tracking-wide text-primary-700 mb-3">
            The math behind the game
          </p>
          <h1 className="text-3xl md:text-5xl font-bold text-gray-950 mb-6">
            What is modular arithmetic?
          </h1>
          <p className="text-xl text-gray-600 mb-10">
            Modular arithmetic is arithmetic that wraps around instead of counting up
            forever. Once a value reaches a fixed limit — the "modulus" — it resets back
            to zero, the same way a clock resets after 12. It shows up constantly in
            computing and cryptography, and it happens to be the entire mechanic behind
            this game.
          </p>

          <h2 className="text-2xl font-bold text-gray-950 mb-4">
            The mod operator, in plain terms
          </h2>
          <p className="text-gray-700 mb-4">
            When you see <code className="bg-gray-100 px-1.5 py-0.5 rounded text-sm">a mod n</code> (often
            written <code className="bg-gray-100 px-1.5 py-0.5 rounded text-sm">a % n</code> in
            code), it means: divide <em>a</em> by <em>n</em>, and keep only the
            remainder. Nothing more than that.
          </p>
          <div className="bg-gray-900 text-white rounded-lg p-6 mb-4 font-mono text-sm space-y-1">
            <p>15 mod 4 = 3 <span className="text-gray-400">// 15 ÷ 4 = 3 remainder 3</span></p>
            <p>20 mod 5 = 0 <span className="text-gray-400">// 20 ÷ 5 = 4 remainder 0 (divides evenly)</span></p>
            <p>7 mod 12 = 7 <span className="text-gray-400">// 7 is already less than 12, so it's unchanged</span></p>
          </div>
          <p className="text-gray-700 mb-10">
            When the remainder is exactly 0, that means <em>n</em> divides <em>a</em> evenly
            — <em>a</em> is a multiple of <em>n</em>. That single case, remainder zero, is
            the entire rule this game is built around: a falling number belongs in a
            bucket exactly when that number mod the bucket's value equals zero.
          </p>

          <h2 className="text-2xl font-bold text-gray-950 mb-4">
            Where it actually shows up
          </h2>
          <div className="space-y-6 mb-10">
            {USES.map((u) => (
              <article key={u.title} className="border-l-4 border-primary-500 pl-5">
                <h3 className="font-bold text-gray-950 mb-1">{u.title}</h3>
                <p className="text-gray-700">{u.body}</p>
              </article>
            ))}
          </div>

          <h2 className="text-2xl font-bold text-gray-950 mb-4">
            Try it yourself
          </h2>
          <p className="text-gray-700 mb-3">
            Before the next section, work these out — they're exactly the calculations
            the game asks you to make instantly, just without a timer:
          </p>
          <ul className="list-disc list-inside text-gray-700 space-y-1 mb-4">
            <li>23 mod 5 = ?</li>
            <li>36 mod 6 = ?</li>
            <li>44 mod 9 = ?</li>
          </ul>
          <p className="text-gray-700 mb-10">
            <span className="font-semibold">Answers:</span> 23 mod 5 = 3 (23 ÷ 5 is 4
            remainder 3). 36 mod 6 = 0 (36 is a clean multiple of 6 — this one "scores").
            44 mod 9 = 8 (9 × 4 = 36, and 44 − 36 = 8).
          </p>

          <h2 className="text-2xl font-bold text-gray-950 mb-4">
            How the game turns this into a puzzle
          </h2>
          <p className="text-gray-700 mb-10">
            Modulo Squares gives every falling number a set of live buckets, each
            labeled with a divisor. Land the number in a bucket where the remainder is
            zero, and it scores a clean division; land it anywhere else and you take a
            penalty. Play enough rounds and the calculation stops being a calculation —
            you start recognizing multiples of 6, 7, and 9 on sight the same way you
            recognize a clock reading "9:00" without counting hour marks. That
            recognition is the actual skill the <Link to="/strategy-guide" className="text-primary-700 font-semibold hover:underline">strategy guide</Link> is
            about building.
          </p>

          <div className="bg-primary-50 border border-primary-100 rounded-lg p-8 text-center">
            <h2 className="text-2xl font-bold text-gray-950 mb-3">
              Put it into practice
            </h2>
            <p className="text-lg text-gray-600 mb-6">
              Read the <Link to="/how-it-works" className="text-primary-700 font-semibold hover:underline">game mechanics</Link>,
              then try landing a few clean divisions yourself.
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

export default ModularArithmeticExplained;
