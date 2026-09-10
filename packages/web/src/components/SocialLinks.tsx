import { SOCIAL_LINKS } from '../shared/socialLinks';

interface SocialLinksProps {
  /** Heading shown above the icons */
  label?: string;
}

/**
 * Row of links to the official Modulo Squares social accounts.
 * (Replaces the former share-intent widget — these point at our own profiles.)
 */
const SocialLinks: React.FC<SocialLinksProps> = ({
  label = 'Follow Modulo Squares',
}) => (
  <div className="flex flex-col items-center gap-3">
    <p className="text-sm font-medium text-gray-500">{label}</p>
    <div className="flex items-center gap-2 flex-wrap justify-center">
      {SOCIAL_LINKS.map(({ label: name, href, icon }) => {
        const isMail = href.startsWith('mailto:');
        return (
          <a
            key={name}
            href={href}
            {...(isMail ? {} : { target: '_blank', rel: 'noopener noreferrer' })}
            title={name}
            aria-label={name}
            className="flex items-center justify-center w-10 h-10 rounded-lg border border-gray-200 text-gray-500 hover:border-primary-300 hover:text-primary-600 hover:bg-primary-50 transition-colors"
          >
            {icon}
          </a>
        );
      })}
    </div>
  </div>
);

export default SocialLinks;
