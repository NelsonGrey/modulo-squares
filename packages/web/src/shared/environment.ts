// Resolves which deployment environment this web build is running in.
//
// Modulo Squares ships one web bundle per CI run (see ci-cd.yml `build-web`),
// with `VITE_ENVIRONMENT` baked in at build time — that wins whenever it is
// set. Only when it is absent (e.g. a bare local `vite dev`) does
// `resolveAppEnvironment` fall back to the Firebase project id, then the
// hostname, then Vite's mode.

const normalizeEnvironmentName = (value: string | undefined | null): string =>
  String(value || '')
    .trim()
    .toLowerCase();

export const inferEnvironmentFromProjectId = (
  projectId: string | undefined | null
): string => {
  const normalizedProjectId = normalizeEnvironmentName(projectId);

  if (normalizedProjectId === 'modulo-squares-dev') {
    return 'development';
  }

  if (normalizedProjectId === 'modulo-squares-staging') {
    return 'staging';
  }

  if (normalizedProjectId === 'modulo-squares-prod') {
    return 'production';
  }

  return '';
};

export const inferEnvironmentFromHostname = (
  hostname: string | undefined | null
): string => {
  const normalizedHostname = normalizeEnvironmentName(hostname);

  if (!normalizedHostname) {
    return '';
  }

  if (
    normalizedHostname === 'localhost' ||
    normalizedHostname === '127.0.0.1' ||
    normalizedHostname === '0.0.0.0'
  ) {
    return 'development';
  }

  if (normalizedHostname.includes('modulo-squares-dev')) {
    return 'development';
  }

  if (normalizedHostname.includes('modulo-squares-staging')) {
    return 'staging';
  }

  if (
    normalizedHostname.includes('modulo-squares-prod') ||
    normalizedHostname === 'modulo-squares.com' ||
    normalizedHostname === 'www.modulo-squares.com'
  ) {
    return 'production';
  }

  return '';
};

export const resolveAppEnvironment = ({
  explicitEnvironment,
  projectId,
  hostname,
  mode,
}: {
  explicitEnvironment?: string | null;
  projectId?: string | null;
  hostname?: string | null;
  mode?: string | null;
}): string => {
  const normalizedExplicitEnvironment =
    normalizeEnvironmentName(explicitEnvironment);
  if (normalizedExplicitEnvironment) {
    return normalizedExplicitEnvironment;
  }

  const inferredFromProjectId = inferEnvironmentFromProjectId(projectId);
  if (inferredFromProjectId) {
    return inferredFromProjectId;
  }

  const inferredFromHostname = inferEnvironmentFromHostname(hostname);
  if (inferredFromHostname) {
    return inferredFromHostname;
  }

  const normalizedMode = normalizeEnvironmentName(mode);
  if (normalizedMode === 'test') {
    return 'test';
  }

  if (normalizedMode === 'development') {
    return 'development';
  }

  return normalizedMode || 'development';
};

const currentHostname =
  typeof window !== 'undefined' ? window.location.hostname : '';

export const appEnvironment = resolveAppEnvironment({
  explicitEnvironment: import.meta.env.VITE_ENVIRONMENT,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  hostname: currentHostname,
  mode: import.meta.env.MODE,
});

export const isDevelopmentEnvironment = appEnvironment === 'development';
export const isStagingEnvironment = appEnvironment === 'staging';
export const isProductionEnvironment = appEnvironment === 'production';
