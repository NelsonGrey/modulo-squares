import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import {
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const RULES_PATH = path.join(__dirname, '..', 'firestore.rules');

// `firebase emulators:exec` exports FIRESTORE_EMULATOR_HOST (e.g.
// "127.0.0.1:8080") to the script it runs. Fall back to the emulator's
// default host/port for anyone running vitest directly against an
// already-running emulator.
const [emulatorHost, emulatorPortRaw] = (
  process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'
).split(':');
const emulatorPort = Number(emulatorPortRaw ?? '8080');

let cachedEnv: RulesTestEnvironment | undefined;

/**
 * Creates (once) and returns the shared rules-unit-testing environment,
 * loading the real firestore.rules source from this package.
 */
export async function getTestEnv(): Promise<RulesTestEnvironment> {
  if (!cachedEnv) {
    cachedEnv = await initializeTestEnvironment({
      projectId: 'demo-modulo-squares-rules-test',
      firestore: {
        rules: readFileSync(RULES_PATH, 'utf8'),
        host: emulatorHost,
        port: emulatorPort,
      },
    });
  }
  return cachedEnv;
}
