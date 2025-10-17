import React from 'react';

const Download: React.FC = () => {
  return (
    <section id="download" className="section-padding bg-gray-50">
      <div className="container-max">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
            Download Modulo Squares
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Available now on iOS and Android. Start your mathematical journey today!
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          {/* iOS Download */}
          <div className="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="text-center">
              <div className="w-16 h-16 bg-black rounded-2xl flex items-center justify-center mx-auto mb-6">
                <span className="text-white text-2xl">📱</span>
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-4">iOS App Store</h3>
              <p className="text-gray-600 mb-6">
                Optimized for iPhone and iPad with seamless iCloud sync and Apple Game Center integration.
              </p>
              <button className="w-full bg-black text-white font-semibold py-4 px-6 rounded-xl hover:bg-gray-800 transition-colors flex items-center justify-center space-x-2">
                <span>Download on the</span>
                <span className="font-bold">App Store</span>
              </button>
            </div>
          </div>

          {/* Android Download */}
          <div className="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-shadow duration-300">
            <div className="text-center">
              <div className="w-16 h-16 bg-green-600 rounded-2xl flex items-center justify-center mx-auto mb-6">
                <span className="text-white text-2xl">🤖</span>
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-4">Google Play Store</h3>
              <p className="text-gray-600 mb-6">
                Available for all Android devices with Google Play Games integration and cross-device sync.
              </p>
              <button className="w-full bg-green-600 text-white font-semibold py-4 px-6 rounded-xl hover:bg-green-700 transition-colors flex items-center justify-center space-x-2">
                <span>Get it on</span>
                <span className="font-bold">Google Play</span>
              </button>
            </div>
          </div>
        </div>

        <div className="mt-16 text-center">
          <div className="bg-white rounded-xl p-8 shadow-lg">
            <h3 className="text-xl font-semibold text-gray-900 mb-4">
              System Requirements
            </h3>
            <div className="grid md:grid-cols-2 gap-6 text-left max-w-2xl mx-auto">
              <div>
                <h4 className="font-semibold text-gray-900 mb-2">iOS</h4>
                <ul className="text-gray-600 space-y-1">
                  <li>• iOS 12.0 or later</li>
                  <li>• iPhone, iPad, or iPod touch</li>
                  <li>• 100MB free storage</li>
                </ul>
              </div>
              <div>
                <h4 className="font-semibold text-gray-900 mb-2">Android</h4>
                <ul className="text-gray-600 space-y-1">
                  <li>• Android 8.0 or later</li>
                  <li>• Phone or tablet</li>
                  <li>• 100MB free storage</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Download;