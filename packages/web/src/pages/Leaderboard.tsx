import { useEffect, useState } from 'react';
import SEOHead from '../components/SEOHead';
import { collection, orderBy, query, limit, onSnapshot } from 'firebase/firestore';
import { db } from '../firebase';

// Mirrors LeaderboardService.currentWeekId() in Dart
function currentWeekId(now = new Date()): number {
  const startOfYear = new Date(now.getFullYear(), 0, 1);
  const dayOfYear = Math.floor((now.getTime() - startOfYear.getTime()) / 86_400_000) + 1;
  const week = Math.floor((dayOfYear - 1) / 7) + 1;
  return now.getFullYear() * 100 + week;
}

const BADGE_TIERS: { maxRank: number; badge: string; color: string; bg: string }[] = [
  { maxRank: 1,  badge: 'Legend',    color: '#7c3aed', bg: '#ede9fe' },
  { maxRank: 3,  badge: 'Diamond',   color: '#0284c7', bg: '#e0f2fe' },
  { maxRank: 10, badge: 'Gold',      color: '#b45309', bg: '#fef3c7' },
  { maxRank: 25, badge: 'Silver',    color: '#4b5563', bg: '#f3f4f6' },
  { maxRank: 50, badge: 'Bronze',    color: '#92400e', bg: '#fde68a' },
];

function badgeForRank(rank: number) {
  return BADGE_TIERS.find(t => rank <= t.maxRank) ?? { badge: 'Contender', color: '#6b7280', bg: '#f9fafb' };
}

const MEDAL: Record<number, string> = { 1: '🥇', 2: '🥈', 3: '🥉' };

interface ScoreRow {
  name: string;
  score: number;
}

type Tab = 'global' | 'weekly';

function ScoreList({ rows, showBadge }: { rows: ScoreRow[]; showBadge?: boolean }) {
  if (rows.length === 0) {
    return (
      <div className="text-center py-16 text-gray-400">
        <p className="text-4xl mb-3">🏁</p>
        <p className="text-lg font-medium">No scores yet — be the first!</p>
      </div>
    );
  }

  return (
    <ol className="divide-y divide-gray-100">
      {rows.map((row, i) => {
        const rank = i + 1;
        const tier = showBadge ? badgeForRank(rank) : null;
        return (
          <li key={i} className="flex items-center gap-4 py-4 px-2">
            <span className="w-10 text-center text-lg font-bold text-gray-400 shrink-0">
              {MEDAL[rank] ?? `#${rank}`}
            </span>
            <span className="flex-1 font-medium text-gray-900 truncate">{row.name}</span>
            {tier && (
              <span
                className="text-xs font-semibold px-2 py-1 rounded-full shrink-0"
                style={{ color: tier.color, backgroundColor: tier.bg }}
              >
                {tier.badge}
              </span>
            )}
            <span className="text-primary-600 font-bold tabular-nums shrink-0">
              {row.score.toLocaleString()}
            </span>
          </li>
        );
      })}
    </ol>
  );
}

export default function Leaderboard() {
  const [tab, setTab] = useState<Tab>('global');
  const [globalScores, setGlobalScores] = useState<ScoreRow[]>([]);
  const [weeklyScores, setWeeklyScores] = useState<ScoreRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  const weekId = currentWeekId();

  useEffect(() => {
    setLoading(true);
    setError(false);

    const globalQ = query(
      collection(db, 'modulo_leaderboard'),
      orderBy('score', 'desc'),
      limit(50),
    );

    const weeklyQ = query(
      collection(db, `modulo_weekly_leaderboard/${weekId}/scores`),
      orderBy('score', 'desc'),
      limit(50),
    );

    const mapDocs = (snap: import('firebase/firestore').QuerySnapshot) =>
      snap.docs.map(d => {
        const data = d.data();
        const name = (data.playerName as string | undefined)?.trim() || d.id;
        return { name, score: (data.score as number) ?? 0 };
      });

    let globalDone = false;
    let weeklyDone = false;
    const tryDone = () => { if (globalDone && weeklyDone) setLoading(false); };

    const unsubGlobal = onSnapshot(
      globalQ,
      snap => { setGlobalScores(mapDocs(snap)); globalDone = true; tryDone(); },
      () => { setError(true); setLoading(false); },
    );

    const unsubWeekly = onSnapshot(
      weeklyQ,
      snap => { setWeeklyScores(mapDocs(snap)); weeklyDone = true; tryDone(); },
      () => { setError(true); setLoading(false); },
    );

    return () => { unsubGlobal(); unsubWeekly(); };
  }, [weekId]);

  return (
    <>
    <SEOHead
      title="Global Leaderboard"
      description="See the top Modulo Squares players worldwide. Compete weekly to earn Legend, Diamond, Gold, Silver, and Bronze badges. Updated live."
      path="/leaderboard"
    />
    <div className="container-max px-4 py-10 max-w-2xl">
      <h1 className="text-3xl font-bold text-gray-900 mb-1">Leaderboard</h1>
      <p className="text-gray-500 mb-8">Real scores from real players — updated live.</p>

      {/* Tabs */}
      <div className="flex gap-2 mb-8 border-b border-gray-200">
        {(['global', 'weekly'] as Tab[]).map(t => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`pb-3 px-4 text-sm font-semibold capitalize border-b-2 transition-colors ${
              tab === t
                ? 'border-primary-600 text-primary-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            {t === 'weekly' ? 'This Week' : 'All-Time'}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex justify-center py-16">
          <div className="w-10 h-10 border-4 border-primary-200 border-t-primary-600 rounded-full animate-spin" />
        </div>
      ) : error ? (
        <div className="text-center py-16 text-gray-500">
          <p className="text-4xl mb-3">⚠️</p>
          <p className="text-lg font-medium">Couldn't load scores right now.</p>
          <p className="text-sm mt-1">Check your connection and try again.</p>
        </div>
      ) : (
        <>
          {tab === 'global' && <ScoreList rows={globalScores} />}
          {tab === 'weekly' && <ScoreList rows={weeklyScores} showBadge />}
        </>
      )}

      {tab === 'weekly' && !loading && !error && (
        <p className="text-xs text-gray-400 text-center mt-6">
          Week {weekId % 100} of {Math.floor(weekId / 100)} · Badges awarded at week close
        </p>
      )}
    </div>
    </>
  );
}
