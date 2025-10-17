import React from 'react';

const Features: React.FC = () => {
  const features = [
    {
      icon: '🧮',
      title: 'Modulo Mechanics',
      description: 'Master the art of modular arithmetic. Every move involves calculating remainders and strategic number placement.'
    },
    {
      icon: '🎯',
      title: 'Strategic Gameplay',
      description: 'Plan your moves carefully. Each tile placement affects the entire board and your scoring potential.'
    },
    {
      icon: '⚡',
      title: 'Power-Ups & Special Tiles',
      description: 'Unlock special tiles like multipliers, obstacles, and freeze effects to enhance your strategy.'
    },
    {
      icon: '🏆',
      title: 'Leaderboards',
      description: 'Compete with players worldwide. Climb the rankings and prove your mathematical prowess.'
    },
    {
      icon: '📱',
      title: 'Cross-Platform',
      description: 'Seamlessly sync your progress across iOS and Android devices with cloud save functionality.'
    },
    {
      icon: '🎨',
      title: 'Beautiful Design',
      description: 'Enjoy a clean, intuitive interface that focuses on gameplay while maintaining visual appeal.'
    }
  ];

  return (
    <section id="features" className="section-padding bg-white">
      <div className="container-max">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
            Why You'll Love Modulo Squares
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Experience the perfect blend of mathematical challenge and addictive gameplay
            in this unique puzzle adventure.
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
              <p className="text-gray-600">
                {feature.description}
              </p>
            </div>
          ))}
        </div>

        <div className="mt-16 text-center">
          <div className="bg-gradient-to-r from-primary-500 to-secondary-500 rounded-2xl p-8 text-white">
            <h3 className="text-2xl font-bold mb-4">
              Ready to Challenge Your Mind?
            </h3>
            <p className="text-lg mb-6 opacity-90">
              Join thousands of players who have discovered the joy of mathematical puzzles.
            </p>
            <button
              onClick={() => {
                const element = document.getElementById('download');
                element?.scrollIntoView({ behavior: 'smooth' });
              }}
              className="bg-white text-primary-600 font-semibold py-3 px-8 rounded-lg hover:bg-gray-50 transition-colors"
            >
              Get Started Now
            </button>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Features;