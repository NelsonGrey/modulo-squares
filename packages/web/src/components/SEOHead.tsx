import { Helmet } from 'react-helmet-async';

const SITE_NAME = 'Modulo Squares';
const BASE_URL = 'https://modulosquares.com';
const DEFAULT_IMAGE = `${BASE_URL}/android-chrome-512x512.png`;

interface SEOHeadProps {
  title: string;
  description: string;
  path?: string;
  image?: string;
  jsonLd?: Record<string, unknown>;
}

const SEOHead: React.FC<SEOHeadProps> = ({
  title,
  description,
  path = '',
  image = DEFAULT_IMAGE,
  jsonLd,
}) => {
  const canonical = `${BASE_URL}${path}`;
  const fullTitle = path === '' ? title : `${title} — ${SITE_NAME}`;

  return (
    <Helmet>
      <title>{fullTitle}</title>
      <meta name="description" content={description} />
      <link rel="canonical" href={canonical} />

      {/* Open Graph */}
      <meta property="og:type" content="website" />
      <meta property="og:site_name" content={SITE_NAME} />
      <meta property="og:title" content={fullTitle} />
      <meta property="og:description" content={description} />
      <meta property="og:url" content={canonical} />
      <meta property="og:image" content={image} />
      <meta property="og:image:width" content="512" />
      <meta property="og:image:height" content="512" />

      {/* Twitter Card */}
      <meta name="twitter:card" content="summary" />
      <meta name="twitter:title" content={fullTitle} />
      <meta name="twitter:description" content={description} />
      <meta name="twitter:image" content={image} />

      {/* JSON-LD structured data */}
      {jsonLd && (
        <script type="application/ld+json">
          {JSON.stringify(jsonLd)}
        </script>
      )}
    </Helmet>
  );
};

export default SEOHead;
