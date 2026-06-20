import { useState } from 'react';
import SEOHead from '../components/SEOHead';

const TOPICS = [
  'Bug Report',
  'Account / Login',
  'Leaderboard Issue',
  'Purchase / In-App',
  'Feature Request',
  'Other',
];

type Status = 'idle' | 'sending' | 'sent' | 'error';

const Support: React.FC = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [topic, setTopic] = useState('');
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState<Status>('idle');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !email || !topic || !message) return;

    try {
      const subject = encodeURIComponent(`[${topic}] Support Request from ${name}`);
      const body = encodeURIComponent(
        `Name: ${name}\nEmail: ${email}\nTopic: ${topic}\n\n${message}`
      );
      window.location.href = `mailto:support@modulosquares.com?subject=${subject}&body=${body}`;
      setStatus('sent');
    } catch {
      setStatus('error');
    }
  };

  return (
    <>
      <SEOHead
        title="Support"
        description="Get help with Modulo Squares. Report bugs, ask questions, or share feedback — our support team typically responds within 24 hours."
        path="/support"
      />
      <div className="bg-white">
        <div className="max-w-2xl mx-auto px-6 py-12">

          <h1 className="text-3xl font-bold text-gray-900 mb-2">Support</h1>
          <p className="text-gray-500 mb-10">
            We typically respond within 24 hours. You can also reach us directly at{' '}
            <a href="mailto:support@modulosquares.com" className="text-primary-600 hover:underline">
              support@modulosquares.com
            </a>
            .
          </p>

          {status === 'sent' ? (
            <div className="rounded-xl bg-green-50 border border-green-200 p-8 text-center">
              <div className="text-4xl mb-4">✅</div>
              <h2 className="text-xl font-semibold text-green-900 mb-2">Your email client is ready</h2>
              <p className="text-green-700 mb-6">
                Your message has been pre-filled. Just hit Send in your email app and we'll get back to you shortly.
              </p>
              <button
                onClick={() => { setStatus('idle'); setName(''); setEmail(''); setTopic(''); setMessage(''); }}
                className="text-sm font-medium text-green-700 hover:text-green-900 underline"
              >
                Send another message
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="grid sm:grid-cols-2 gap-6">
                <div>
                  <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">
                    Name
                  </label>
                  <input
                    id="name"
                    type="text"
                    value={name}
                    onChange={e => setName(e.target.value)}
                    required
                    placeholder="Your name"
                    className="w-full rounded-lg border border-gray-300 px-4 py-3 text-gray-900 placeholder-gray-400 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
                  />
                </div>
                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
                    Email
                  </label>
                  <input
                    id="email"
                    type="email"
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                    required
                    placeholder="you@example.com"
                    className="w-full rounded-lg border border-gray-300 px-4 py-3 text-gray-900 placeholder-gray-400 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="topic" className="block text-sm font-medium text-gray-700 mb-1">
                  Topic
                </label>
                <select
                  id="topic"
                  value={topic}
                  onChange={e => setTopic(e.target.value)}
                  required
                  className="w-full rounded-lg border border-gray-300 px-4 py-3 text-gray-900 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 bg-white"
                >
                  <option value="" disabled>Select a topic…</option>
                  {TOPICS.map(t => (
                    <option key={t} value={t}>{t}</option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-1">
                  Message
                </label>
                <textarea
                  id="message"
                  value={message}
                  onChange={e => setMessage(e.target.value)}
                  required
                  rows={6}
                  placeholder="Describe your issue or question in as much detail as possible…"
                  className="w-full rounded-lg border border-gray-300 px-4 py-3 text-gray-900 placeholder-gray-400 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 resize-none"
                />
              </div>

              {status === 'error' && (
                <p className="text-sm text-red-600">
                  Something went wrong. Please email us directly at{' '}
                  <a href="mailto:support@modulosquares.com" className="underline">
                    support@modulosquares.com
                  </a>
                  .
                </p>
              )}

              <button
                type="submit"
                className="w-full bg-primary-600 hover:bg-primary-700 text-white font-semibold py-4 px-6 rounded-xl transition-colors"
              >
                Send Message
              </button>
            </form>
          )}
        </div>
      </div>
    </>
  );
};

export default Support;
