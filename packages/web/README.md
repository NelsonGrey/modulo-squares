# Modulo Squares Web

A promotional website for the Modulo Squares mobile game, built with React, TypeScript, and Tailwind CSS.

## Overview

This website serves as a landing page for the Modulo Squares puzzle game, available on iOS and Android. It provides information about the game mechanics, features, and download links for the mobile apps.

## Features

- **Responsive Design**: Mobile-first design that works on all devices
- **Smooth Scrolling**: Navigation with smooth scroll behavior
- **Game Showcase**: Visual representation of the game board
- **Download Links**: Prominent call-to-action buttons for app stores
- **Feature Highlights**: Detailed explanation of game mechanics
- **Modern UI**: Clean, professional design with Tailwind CSS

## Tech Stack

- **React 18** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool and dev server
- **Tailwind CSS** - Utility-first CSS framework
- **ESLint** - Code linting

## Development

### Prerequisites

- Node.js 18+
- npm or yarn

### Installation

```bash
# Install dependencies
npm install
```

### Development Server

```bash
# Start development server
npm run dev
```

The development server will start at `http://localhost:3000`

### Build for Production

```bash
# Build for production
npm run build
```

### Preview Production Build

```bash
# Preview production build locally
npm run preview
```

### Linting

```bash
# Run ESLint
npm run lint
```

## Project Structure

```
src/
├── components/          # React components
│   ├── Navigation.tsx   # Header navigation
│   ├── Hero.tsx         # Hero section
│   ├── Features.tsx     # Features showcase
│   ├── Download.tsx     # Download section
│   └── Footer.tsx       # Footer
├── App.tsx             # Main app component
├── main.tsx            # App entry point
└── index.css           # Global styles
```

## Deployment

The website is configured for deployment to Firebase Hosting. Use the root-level scripts:

```bash
# Build and deploy web
npm run deploy:web

# Or from root directory
npm run build:web
```

## Design System

### Colors

- **Primary**: Blue (#0EA5E9) - Used for CTAs and accents
- **Secondary**: Yellow (#EAB308) - Used for highlights and secondary actions
- **Gray Scale**: Standard gray palette for text and backgrounds

### Typography

- **Font Family**: Inter (system font stack fallback)
- **Headings**: Bold weights for hierarchy
- **Body**: Regular weight for readability

### Components

- **Buttons**: Primary and secondary variants with hover states
- **Cards**: Rounded corners with subtle shadows
- **Sections**: Consistent padding and spacing

## Contributing

1. Follow the existing code style
2. Use TypeScript for type safety
3. Ensure responsive design works on mobile
4. Test builds before committing
5. Update this README for significant changes