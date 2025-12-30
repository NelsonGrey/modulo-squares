const Hero: React.FC = () => {
  const scrollToDownload = () => {
    const element = document.getElementById('download');
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <section className="pt-16 bg-gradient-to-br from-primary-50 to-secondary-50 min-h-screen flex items-center">
      <div className="container-max">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Content */}
          <div className="text-center lg:text-left">
            <h1 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
              Master the Art of
              <span className="text-primary-600 block">Modulo Mathematics</span>
            </h1>
            <p className="text-xl text-gray-600 mb-8 max-w-2xl">
              Challenge your mind with Modulo Squares, the addictive puzzle game where every number counts.
              Slide, match, and conquer in this mathematical adventure available on mobile.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
              <button
                onClick={scrollToDownload}
                className="btn-primary text-lg px-8 py-4"
              >
                Download Now
              </button>
              <button
                onClick={() => {
                  const element = document.getElementById('features');
                  element?.scrollIntoView({ behavior: 'smooth' });
                }}
                className="btn-secondary text-lg px-8 py-4"
              >
                Learn More
              </button>
            </div>
          </div>

          {/* Visual */}
          <div className="relative">
            <div className="bg-white rounded-2xl shadow-2xl p-8 transform rotate-3 hover:rotate-0 transition-transform duration-300">
              <div className="grid grid-cols-4 gap-2">
                {/* Mock game board */}
                {Array.from({ length: 16 }, (_, i) => (
                  <div
                    key={i}
                    className={`aspect-square rounded-lg flex items-center justify-center font-bold text-lg ${
                      [2, 7, 10, 13].includes(i)
                        ? 'bg-primary-500 text-white'
                        : [3, 8, 11, 14].includes(i)
                        ? 'bg-secondary-500 text-white'
                        : 'bg-gray-100 text-gray-600'
                    }`}
                  >
                    {[2, 7, 10, 13].includes(i) && '2'}
                    {[3, 8, 11, 14].includes(i) && '3'}
                  </div>
                ))}
              </div>
              <div className="mt-4 text-center">
                <p className="text-sm text-gray-500">Score: 1,247</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;