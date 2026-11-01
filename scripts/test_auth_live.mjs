// Explicitly authorized live acceptance only. No password/token is written or
// printed. Existing accounts are never modified by this signup probe.
import { readFile } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';
import { initializeApp, deleteApp } from 'firebase/app';
import {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  sendEmailVerification,
  sendPasswordResetEmail,
} from 'firebase/auth';

const [approval, email] = process.argv.slice(2);
if (approval !== '--create-authorized-test-account' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email ?? '')) {
  throw new Error('Usage: node scripts/test_auth_live.mjs --create-authorized-test-account <approved-email>');
}
const config = JSON.parse(await readFile(new URL('../config/firebase.local.json', import.meta.url), 'utf8'));
if (config.FIREBASE_PROJECT_ID !== 'muenee-pj' || process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error('Requires the approved live muenee-pj configuration without emulator overrides.');
}
const app = initializeApp({
  apiKey: config.FIREBASE_API_KEY,
  appId: config.FIREBASE_ANDROID_APP_ID,
  projectId: config.FIREBASE_PROJECT_ID,
});
const auth = getAuth(app);
auth.languageCode = 'th';
let temporaryPassword = `MueNee!${randomBytes(32).toString('base64url')}`;
try {
  await createUserWithEmailAndPassword(auth, email, temporaryPassword);
  console.log('PASS: authorized live test account created.');
  await signOut(auth);
  await signInWithEmailAndPassword(auth, email, temporaryPassword);
  temporaryPassword = '';
  console.log('PASS: live sign-out and password sign-in.');
  await sendEmailVerification(auth.currentUser);
  console.log('SENT: Firebase verification email requested. Mailbox receipt still requires user confirmation.');
  await sendPasswordResetEmail(auth, email);
  console.log('SENT: Firebase password reset email requested so the user can choose their own password.');
  await signOut(auth);
  console.log('PASS: final sign-out. PENDING: user verification/reset and Android process-restart session acceptance.');
} catch (error) {
  // SDK error codes only: no credentials, token-bearing URLs, or response bodies.
  console.error(`Live acceptance stopped: ${error.code ?? 'unexpected-error'}`);
  process.exitCode = 1;
} finally {
  temporaryPassword = '';
  await deleteApp(app);
}
