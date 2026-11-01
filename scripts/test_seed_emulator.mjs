import { spawnSync } from 'node:child_process';

const args = ['scripts/seed_firestore.mjs', '--write', '--emulator', '--project', 'demo-muenee-pj'];
const first = spawnSync(process.execPath, args, { encoding: 'utf8', env: process.env });
process.stdout.write(first.stdout);
process.stderr.write(first.stderr);
if (first.status !== 0) throw new Error(`Initial emulator seed failed with exit code ${first.status}.`);

const second = spawnSync(process.execPath, args, { encoding: 'utf8', env: process.env });
if (second.status === 0 || !second.stderr.includes('Create-only seed refused')) {
  process.stdout.write(second.stdout);
  process.stderr.write(second.stderr);
  throw new Error('A repeated seed did not fail with the create-only guard.');
}
console.log('Repeated seed was safely refused before any overwrite.');
