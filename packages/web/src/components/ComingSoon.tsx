import React from 'react';

const ComingSoon: React.FC = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center px-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8 text-center">
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">Coming Soon</h1>
          <p className="text-lg text-gray-600">
            We're working hard to bring you an amazing experience.
          </p>
        </div>

        <div className="space-y-4">
          <div className="animate-pulse">
            <div className="w-16 h-16 bg-blue-500 rounded-full mx-auto mb-4"></div>
            <div className="space-y-2">
              <div className="h-4 bg-gray-200 rounded w-3/4 mx-auto"></div>
              <div className="h-4 bg-gray-200 rounded w-1/2 mx-auto"></div>
            </div>
          </div>
        </div>

        <div className="mt-8 text-sm text-gray-500">
          <p>Stay tuned for updates!</p>
        </div>
      </div>
    </div>
  );
};

export default ComingSoon;