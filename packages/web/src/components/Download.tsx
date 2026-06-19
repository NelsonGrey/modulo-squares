import SEOHead from './SEOHead';

const Download: React.FC = () => {
  return (
    <>
    <SEOHead
      title="Download Free"
      description="Download Modulo Squares free on the App Store and Google Play. Guide falling numbers into divisor buckets — a fresh math puzzle for iOS and Android."
      path="/download"
    />
    <section className="section-padding bg-gray-50">
      <div className="container-max">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
            Download Modulo Squares
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Free to download on iOS and Android. Sign in to sync your scores and compete on global leaderboards.
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          {/* iOS */}
          <div className="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="text-center">
              <div className="w-16 h-16 bg-black rounded-2xl flex items-center justify-center mx-auto mb-6">
                <svg viewBox="0 0 24 24" className="w-8 h-8 fill-white">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-4">iOS</h3>
              <p className="text-gray-600 mb-6">
                For iPhone and iPad. Requires iOS 16 or later.
              </p>
              <a
                href="#"
                className="block w-full bg-black text-white font-semibold py-4 px-6 rounded-xl hover:bg-gray-800 transition-colors text-center"
                aria-label="Download on the App Store"
              >
                Download on the App Store
              </a>
            </div>
          </div>

          {/* Android */}
          <div className="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="text-center">
              <div className="w-16 h-16 bg-secondary-600 rounded-2xl flex items-center justify-center mx-auto mb-6">
                <svg viewBox="0 0 24 24" className="w-8 h-8 fill-white">
                  <path d="M17.523 15.341l1.893-3.278a.4.4 0 0 0-.146-.547l-1.921-1.109a7.017 7.017 0 0 0-.635-1.094l.765-2.175a.4.4 0 0 0-.25-.506l-3.454-1.215a.4.4 0 0 0-.503.247l-.766 2.175a6.92 6.92 0 0 0-1.27.001L10.47 5.664a.4.4 0 0 0-.503-.248L6.513 6.633a.4.4 0 0 0-.249.506l.765 2.175a7.01 7.01 0 0 0-.635 1.094L4.474 11.516a.4.4 0 0 0-.147.547l1.894 3.278a.4.4 0 0 0 .547.146l1.921-1.108a6.945 6.945 0 0 0 1.27 0l.766 2.175a.4.4 0 0 0 .503.248l3.454-1.216a.4.4 0 0 0 .249-.506l-.765-2.175a7.01 7.01 0 0 0 .635-1.094l1.921 1.109a.4.4 0 0 0 .547-.147l-.247-.428zM12 14a2 2 0 1 1 0-4 2 2 0 0 1 0 4z" />
                </svg>
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-4">Android</h3>
              <p className="text-gray-600 mb-6">
                For phones and tablets. Requires Android 8.0 or later.
              </p>
              <a
                href="#"
                className="block w-full bg-secondary-600 text-white font-semibold py-4 px-6 rounded-xl hover:bg-secondary-700 transition-colors text-center"
                aria-label="Get it on Google Play"
              >
                Get it on Google Play
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
    </>
  );
};

export default Download;
