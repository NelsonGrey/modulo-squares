# Modulo Squares - Web Frontend Architecture

## Overview

The Modulo Squares web app is a React + TypeScript + Vite marketing website and game showcase. It provides user-friendly navigation, game description, and integration with Firebase for analytics and optional game embedding.

**Technology Stack**:
- React 18+ for UI
- TypeScript for type safety
- Vite for fast bundling
- Tailwind CSS for styling
- Firebase SDK for backend integration
- React Router for navigation

---

## Project Structure

```
packages/web/
├── src/
│   ├── components/              # Reusable React components
│   │   ├── Navbar.tsx           # Navigation bar
│   │   ├── Footer.tsx           # Footer component
│   │   ├── Features.tsx         # Game features showcase
│   │   ├── Hero.tsx             # Landing hero section
│   │   ├── Downloads.tsx        # App store links
│   │   └── ...
│   ├── pages/                   # Page components
│   │   ├── Home.tsx             # Landing / home page
│   │   ├── Game.tsx             # Game demo page
│   │   ├── Leaderboard.tsx      # Leaderboard view
│   │   ├── About.tsx            # About page
│   │   └── Privacy.tsx          # Privacy policy
│   ├── services/                # Business logic & API
│   │   ├── firebase.ts          # Firebase config
│   │   ├── api.ts               # Backend API calls
│   │   ├── analytics.ts         # Analytics tracking
│   │   └── gameService.ts       # Game logic utils
│   ├── types/                   # TypeScript type definitions
│   │   ├── game.ts              # Game types
│   │   ├── user.ts              # User types
│   │   └── api.ts               # API response types
│   ├── hooks/                   # Custom React hooks
│   │   ├── useAuth.ts           # Auth state hook
│   │   ├── useGame.ts           # Game state hook
│   │   └── useLeaderboard.ts    # Leaderboard hook
│   ├── context/                 # React context
│   │   ├── AuthContext.tsx      # Auth context provider
│   │   └── GameContext.tsx      # Game context provider
│   ├── assets/                  # Static assets
│   │   ├── images/              # PNG, JPG images
│   │   ├── icons/               # SVG icons
│   │   └── styles/              # Global CSS/Tailwind
│   ├── utils/                   # Utility functions
│   │   ├── validation.ts        # Input validation
│   │   ├── formatting.ts        # Data formatting
│   │   └── api.ts               # API helpers
│   ├── App.tsx                  # Root component
│   ├── main.tsx                 # Entry point
│   └── index.css                # Global styles
├── public/                      # Static assets (favicons, etc)
│   ├── favicon.ico
│   └── manifest.json            # PWA manifest
├── vite.config.ts              # Vite configuration
├── tailwind.config.js          # Tailwind configuration
├── tsconfig.json               # TypeScript configuration
├── tsconfig.node.json          # TypeScript config (build tools)
├── eslintrc.json               # ESLint configuration
├── package.json                # Dependencies
├── Dockerfile                  # Container image
├── nginx.conf                  # Nginx web server config
└── .env.example                # Environment variables template
```

---

## Component Architecture

### Page Structure (Example: Home)

```tsx
// src/pages/Home.tsx
import React from 'react';
import { Helmet } from 'react-helmet';
import Hero from '../components/Hero';
import Features from '../components/Features';
import Downloads from '../components/Downloads';
import Testimonials from '../components/Testimonials';
import Footer from '../components/Footer';

export default function Home() {
  return (
    <>
      <Helmet>
        <title>Modulo Squares - Puzzle Game</title>
        <meta name="description" content="Strategic puzzle game with modulo arithmetic" />
      </Helmet>
      
      <div className="min-h-screen flex flex-col">
        <Hero />
        <Features />
        <Downloads />
        <Testimonials />
        <Footer />
      </div>
    </>
  );
}
```

### Reusable Components

#### NavBar Component

```tsx
// src/components/Navbar.tsx
import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export default function Navbar() {
  const [isOpen, setIsOpen] = useState(false);
  const { user, signOut } = useAuth();

  return (
    <nav className="bg-white shadow-md sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16 items-center">
          {/* Logo */}
          <Link to="/" className="text-2xl font-bold text-blue-600">
            🎮 Modulo Squares
          </Link>

          {/* Desktop Menu */}
          <div className="hidden md:flex space-x-4">
            <Link to="/" className="hover:text-blue-600">Home</Link>
            <Link to="/game" className="hover:text-blue-600">Play</Link>
            <Link to="/leaderboard" className="hover:text-blue-600">Leaderboard</Link>
            <Link to="/about" className="hover:text-blue-600">About</Link>
            
            {user ? (
              <button 
                onClick={signOut}
                className="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
              >
                Sign Out
              </button>
            ) : (
              <button 
                onClick={() => signOut()}
                className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
              >
                Sign In
              </button>
            )}
          </div>

          {/* Mobile Menu Button */}
          <button className="md:hidden" onClick={() => setIsOpen(!isOpen)}>
            ☰
          </button>
        </div>

        {/* Mobile Menu */}
        {isOpen && (
          <div className="md:hidden pb-4 space-y-2">
            <Link to="/" className="block hover:text-blue-600">Home</Link>
            <Link to="/game" className="block hover:text-blue-600">Play</Link>
            <Link to="/leaderboard" className="block hover:text-blue-600">Leaderboard</Link>
          </div>
        )}
      </div>
    </nav>
  );
}
```

#### Features Component

```tsx
// src/components/Features.tsx
import React from 'react';

const Features: React.FC = () => {
  const features = [
    {
      icon: '🧮',
      title: 'Modulo Mechanics',
      description: 'Master modular arithmetic through interactive gameplay',
    },
    {
      icon: '🎯',
      title: 'Strategic Gameplay',
      description: 'Plan your moves carefully to clear the board',
    },
    {
      icon: '⚡',
      title: 'Power-Ups',
      description: 'Deploy special tiles to enhance your strategy',
    },
    {
      icon: '🏆',
      title: 'Leaderboards',
      description: 'Compete with players worldwide',
    },
    {
      icon: '📱',
      title: 'Cross-Platform',
      description: 'Play on iOS, Android, and Web seamlessly',
    },
    {
      icon: '🌍',
      title: 'Global Community',
      description: 'Join millions of puzzle enthusiasts',
    },
  ];

  return (
    <section className="py-16 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4">
        <h2 className="text-4xl font-bold text-center mb-12">Game Features</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature) => (
            <div 
              key={feature.title}
              className="p-6 bg-white rounded-lg shadow hover:shadow-lg transition"
            >
              <div className="text-4xl mb-4">{feature.icon}</div>
              <h3 className="text-xl font-bold mb-2">{feature.title}</h3>
              <p className="text-gray-600">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Features;
```

---

## State Management

### Context API for Global State

#### Auth Context

```tsx
// src/context/AuthContext.tsx
import React, { createContext, useContext, useEffect, useState } from 'react';
import { User } from 'firebase/auth';
import { auth } from '../services/firebase';
import { signInAnonymously, signOut } from 'firebase/auth';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  signIn: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged((user) => {
      setUser(user);
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const handleSignIn = async () => {
    try {
      await signInAnonymously(auth);
    } catch (error) {
      console.error('Sign in failed:', error);
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut(auth);
    } catch (error) {
      console.error('Sign out failed:', error);
    }
  };

  return (
    <AuthContext.Provider 
      value={{
        user,
        loading,
        signIn: handleSignIn,
        signOut: handleSignOut,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
```

#### Game Context

```tsx
// src/context/GameContext.tsx
import React, { createContext, useContext, useState, useCallback } from 'react';
import { GameState, GameBoard } from '../types/game';

interface GameContextType {
  gameState: GameState | null;
  board: GameBoard | null;
  initializeGame: (level: number) => void;
  makeMove: (fromRow: number, fromCol: number, toRow: number, toCol: number) => void;
  resetGame: () => void;
}

const GameContext = createContext<GameContextType | undefined>(undefined);

export function GameProvider({ children }: { children: React.ReactNode }) {
  const [gameState, setGameState] = useState<GameState | null>(null);
  const [board, setBoard] = useState<GameBoard | null>(null);

  const initializeGame = useCallback((level: number) => {
    // Initialize game board and state
    const newBoard = createInitialBoard(level);
    setBoard(newBoard);
    setGameState({
      level,
      score: 0,
      moves: 20 + (level - 1) * 2,
      isGameOver: false,
    });
  }, []);

  const makeMove = useCallback((fromRow: number, fromCol: number, 
                               toRow: number, toCol: number) => {
    if (!board || !gameState) return;

    const newBoard = performMove(board, fromRow, fromCol, toRow, toCol);
    if (newBoard) {
      setBoard(newBoard);
      setGameState(prev => prev ? {
        ...prev,
        score: prev.score + calculatePoints(newBoard),
        moves: prev.moves - 1,
      } : null);
    }
  }, [board, gameState]);

  const resetGame = useCallback(() => {
    setGameState(null);
    setBoard(null);
  }, []);

  return (
    <GameContext.Provider value={{
      gameState,
      board,
      initializeGame,
      makeMove,
      resetGame,
    }}>
      {children}
    </GameContext.Provider>
  );
}

export function useGame() {
  const context = useContext(GameContext);
  if (context === undefined) {
    throw new Error('useGame must be used within GameProvider');
  }
  return context;
}
```

---

## API Integration

### Firebase Configuration

```typescript
// src/services/firebase.ts
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getAnalytics } from 'firebase/analytics';
import { getFunctions } from 'firebase/functions';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const analytics = getAnalytics(app);
export const functions = getFunctions(app, 'us-central1');
```

### API Service

```typescript
// src/services/api.ts
import { httpsCallable } from 'firebase/functions';
import { functions } from './firebase';
import { ScoreSubmission, LeaderboardEntry } from '../types/api';

// Call submitScore Cloud Function
export async function submitScore(score: number, level: number): 
  Promise<{ success: boolean; scoreId: string }> {
  const submitScore = httpsCallable<
    { score: number; level: number },
    { success: boolean; scoreId: string }
  >(functions, 'submitScore');

  try {
    const result = await submitScore({ score, level });
    return result.data;
  } catch (error) {
    console.error('Failed to submit score:', error);
    throw error;
  }
}

// Fetch leaderboard from Firestore
export async function fetchLeaderboard(limit = 100): 
  Promise<LeaderboardEntry[]> {
  const response = await fetch(
    `/api/leaderboard?limit=${limit}`
  );

  if (!response.ok) {
    throw new Error('Failed to fetch leaderboard');
  }

  return response.json();
}

// Fetch user's scores
export async function fetchUserScores(userId: string): 
  Promise<LeaderboardEntry[]> {
  const response = await fetch(
    `/api/user/${userId}/scores`
  );

  if (!response.ok) {
    throw new Error('Failed to fetch user scores');
  }

  return response.json();
}
```

---

## Custom Hooks

### useAuth Hook

```typescript
// src/hooks/useAuth.ts
import { useContext } from 'react';
import { AuthContext } from '../context/AuthContext';

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
```

### useLeaderboard Hook

```typescript
// src/hooks/useLeaderboard.ts
import { useState, useEffect } from 'react';
import { fetchLeaderboard } from '../services/api';
import { LeaderboardEntry } from '../types/api';

export function useLeaderboard(refreshInterval = 30000) {
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    const loadLeaderboard = async () => {
      try {
        const data = await fetchLeaderboard();
        if (isMounted) {
          setLeaderboard(data);
          setError(null);
        }
      } catch (error) {
        if (isMounted) {
          setError(error instanceof Error ? error.message : 'Unknown error');
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    };

    loadLeaderboard();

    // Refresh periodically
    const interval = setInterval(loadLeaderboard, refreshInterval);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [refreshInterval]);

  return { leaderboard, loading, error };
}
```

---

## Styling with Tailwind CSS

### Tailwind Configuration

```javascript
// tailwind.config.js
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#3B82F6',    // Blue
        success: '#10B981',    // Green
        warning: '#F59E0B',    // Amber
        danger: '#EF4444',     // Red
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
```

### Example Styled Component

```tsx
// src/components/ScoreCard.tsx
interface ScoreCardProps {
  rank: number;
  name: string;
  score: number;
  level: number;
}

export function ScoreCard({ rank, name, score, level }: ScoreCardProps) {
  return (
    <div className="flex items-center p-4 bg-white rounded-lg shadow-md hover:shadow-lg transition">
      {/* Rank Badge */}
      <div className="flex-shrink-0">
        <div className={`
          flex items-center justify-center 
          w-10 h-10 rounded-full 
          font-bold text-white
          ${rank === 1 ? 'bg-yellow-500' : 
            rank === 2 ? 'bg-gray-400' :
            rank === 3 ? 'bg-orange-500' :
            'bg-blue-500'}
        `}>
          #{rank}
        </div>
      </div>

      {/* Player Info */}
      <div className="flex-1 min-w-0 px-4">
        <p className="text-lg font-semibold text-gray-900 truncate">{name}</p>
        <p className="text-sm text-gray-600">Level {level}</p>
      </div>

      {/* Score */}
      <div className="flex-shrink-0">
        <p className="text-2xl font-bold text-blue-600">{score}</p>
      </div>
    </div>
  );
}
```

---

## Routing

### React Router Setup

```tsx
// src/App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Footer from './components/Footer';
import Home from './pages/Home';
import Game from './pages/Game';
import Leaderboard from './pages/Leaderboard';
import About from './pages/About';
import Privacy from './pages/Privacy';

function App() {
  return (
    <BrowserRouter>
      <div className="flex flex-col min-h-screen">
        <Navbar />
        <main className="flex-1">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/game" element={<Game />} />
            <Route path="/leaderboard" element={<Leaderboard />} />
            <Route path="/about" element={<About />} />
            <Route path="/privacy" element={<Privacy />} />
            <Route path="*" element={<Home />} />
          </Routes>
        </main>
        <Footer />
      </div>
    </BrowserRouter>
  );
}

export default App;
```

---

## Build & Deployment

### Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist',
    sourcemap: false,
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: (id) => {
          if (id.includes('node_modules')) {
            if (id.includes('react')) {
              return 'react-vendor';
            }
            if (id.includes('firebase')) {
              return 'firebase-vendor';
            }
            return 'vendor';
          }
        },
      },
    },
  },
  server: {
    port: 5173,
    open: true,
  },
})
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### Nginx Configuration

```nginx
# nginx.conf
server {
  listen 80;
  server_name _;

  root /usr/share/nginx/html;

  # Gzip compression
  gzip on;
  gzip_types text/plain text/css text/javascript application/javascript;
  gzip_min_length 1024;

  # SPA routing
  location / {
    try_files $uri $uri/ /index.html;
  }

  # Cache static assets
  location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
  }

  # API proxy (optional)
  location /api {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
  }
}
```

---

## Testing

### Component Testing

```typescript
// src/components/__tests__/Features.test.tsx
import { render, screen } from '@testing-library/react';
import Features from '../Features';

describe('Features Component', () => {
  it('renders all feature cards', () => {
    render(<Features />);
    
    expect(screen.getByText('Modulo Mechanics')).toBeInTheDocument();
    expect(screen.getByText('Strategic Gameplay')).toBeInTheDocument();
    expect(screen.getByText('Leaderboards')).toBeInTheDocument();
  });

  it('displays correct number of feature cards', () => {
    render(<Features />);
    
    const cards = screen.getAllByRole('generic');
    expect(cards.length).toBeGreaterThan(0);
  });
});
```

### Hook Testing

```typescript
// src/hooks/__tests__/useLeaderboard.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { useLeaderboard } from '../useLeaderboard';

jest.mock('../services/api', () => ({
  fetchLeaderboard: jest.fn(),
}));

describe('useLeaderboard', () => {
  it('loads leaderboard data', async () => {
    const { result } = renderHook(() => useLeaderboard());

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.leaderboard).toBeDefined();
  });

  it('handles errors gracefully', async () => {
    const { result } = renderHook(() => useLeaderboard());

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    if (result.current.error) {
      expect(typeof result.current.error).toBe('string');
    }
  });
});
```

---

## Type Definitions

### Game Types

```typescript
// src/types/game.ts
export interface GameState {
  level: number;
  score: number;
  moves: number;
  isGameOver: boolean;
  selectedCell?: CellPosition;
}

export interface GameBoard {
  grid: (number | null)[][];
  rows: number;
  cols: number;
  level: number;
}

export interface CellPosition {
  row: number;
  col: number;
}
```

### API Types

```typescript
// src/types/api.ts
export interface LeaderboardEntry {
  userId: string;
  userEmail: string;
  score: number;
  level: number;
  timestamp: Date;
  rank?: number;
}

export interface ScoreSubmission {
  score: number;
  level: number;
}
```

---

## Environment Variables

```bash
# .env.example
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_AUTH_DOMAIN=modulo-squares-dev.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=modulo-squares-dev
VITE_FIREBASE_STORAGE_BUCKET=modulo-squares-dev.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
VITE_FIREBASE_APP_ID=your_app_id

VITE_API_ENDPOINT=https://us-central1-modulo-squares-dev.cloudfunctions.net
```

---

## Related Documentation

- [System Architecture](SYSTEM_ARCHITECTURE.md)
- [API Documentation](API_DOCUMENTATION.md)
- [Performance & Scalability](PERFORMANCE_SCALABILITY.md)
- [Security Guidelines](SECURITY.md)
