import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { GeoPoint, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { createHash } from 'node:crypto';
import { loadSeedData, summarizeSeedData, validateSeedData } from './seed_data_lib.mjs';

const hasFlag = (name) => process.argv.includes(name);
const readOption = (name) => {
  const index = process.argv.indexOf(name);
  return index < 0 || index === process.argv.length - 1 ? undefined : process.argv[index + 1];
};

const write = hasFlag('--write');
const preflight = hasFlag('--preflight');
const verify = hasFlag('--verify');
const emulator = hasFlag('--emulator');
const live = hasFlag('--live');
const projectId = readOption('--project');
const confirmedProject = readOption('--confirm-project');

if (emulator && live) throw new Error('Choose either --emulator or --live, not both.');
if ([write, preflight, verify].filter(Boolean).length > 1) throw new Error('Choose only one of --write, --preflight, or --verify.');
if ((write || preflight || verify) && !emulator && !live) throw new Error('A Firestore connection requires --emulator or --live.');
if (emulator && !['127.0.0.1:8080', 'localhost:8080'].includes(process.env.FIRESTORE_EMULATOR_HOST)) {
  throw new Error('Emulator writes require FIRESTORE_EMULATOR_HOST on local port 8080.');
}
if (live) {
  if (!write && !preflight && !verify) throw new Error('Live mode requires --write, --preflight, or --verify.');
  if (!projectId || confirmedProject !== projectId) throw new Error('Live mode requires matching --project and --confirm-project values.');
  if (process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Refusing live mode while FIRESTORE_EMULATOR_HOST is set.');
}

const data = await loadSeedData();
const errors = validateSeedData(data);
if (errors.length > 0) throw new Error(`Seed validation failed:\n${errors.map((error) => `- ${error}`).join('\n')}`);
const summary = summarizeSeedData(data);
const digest = createHash('sha256').update(JSON.stringify(data)).digest('hex').slice(0, 16);
console.log(`Validated ${summary.restaurants} restaurants and ${summary.menuItems} menus (digest ${digest}).`);
if (!write && !preflight && !verify) {
  console.log('Dry run only. No Firestore connection or write was attempted.');
  process.exit(0);
}
if (!projectId) throw new Error('--project is required for a write.');

const app = getApps()[0] ?? initializeApp({ projectId, ...(live ? { credential: applicationDefault() } : {}) });
const firestore = getFirestore(app);
const stamp = (value) => Timestamp.fromDate(new Date(value));
const restaurantDocument = (item) => ({
  schemaVersion: item.schemaVersion,
  name: item.name.trim(),
  googlePlaceId: item.googlePlaceId,
  location: new GeoPoint(item.location.latitude, item.location.longitude),
  address: item.address.trim(),
  ...(item.rating === undefined ? {} : { rating: item.rating }),
  verificationStatus: item.verificationStatus,
  isActive: item.isActive,
  createdAt: stamp(item.createdAt),
  updatedAt: stamp(item.updatedAt),
});
const menuDocument = (item) => ({
  schemaVersion: item.schemaVersion,
  restaurantId: item.restaurantId,
  name: item.name.trim(),
  price: {
    amount: item.price.amount,
    confidence: item.price.confidence,
    ...(item.price.source === undefined ? {} : { source: item.price.source }),
    ...(item.price.verifiedAt === undefined ? {} : { verifiedAt: stamp(item.price.verifiedAt) }),
  },
  nutrition: item.nutrition,
  tags: item.tags,
  ingredients: item.ingredients,
  allergens: item.allergens,
  ingredientsKnown: item.ingredientsKnown,
  allergensKnown: item.allergensKnown,
  vegetarianConfirmed: item.vegetarianConfirmed,
  halalConfirmed: item.halalConfirmed,
  isActive: item.isActive,
  createdAt: stamp(item.createdAt),
  updatedAt: stamp(item.updatedAt),
});
const writes = [
  ...data.restaurantsDocument.restaurants.map((item) => ({ ref: firestore.collection('restaurants').doc(item.id), value: restaurantDocument(item) })),
  ...data.menuItemsDocument.menuItems.map((item) => ({ ref: firestore.collection('menu_items').doc(item.id), value: menuDocument(item) })),
];

const existing = await firestore.getAll(...writes.map(({ ref }) => ref));
const conflicts = existing.filter((snapshot) => snapshot.exists).map((snapshot) => snapshot.ref.path);
const normalize = (value) => {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (value instanceof GeoPoint) return { latitude: value.latitude, longitude: value.longitude };
  if (Array.isArray(value)) return value.map(normalize);
  if (value && typeof value === 'object') return Object.fromEntries(Object.keys(value).sort().map((key) => [key, normalize(value[key])]));
  return value;
};
if (verify) {
  const mismatches = [];
  for (let index = 0; index < writes.length; index += 1) {
    const snapshot = existing[index];
    if (!snapshot.exists || JSON.stringify(normalize(snapshot.data())) !== JSON.stringify(normalize(writes[index].value))) mismatches.push(writes[index].ref.path);
  }
  if (mismatches.length > 0) throw new Error(`Live seed verification found ${mismatches.length} missing or mismatched document(s). First mismatch: ${mismatches[0]}`);
  console.log(`Read-only verification passed for ${projectId}: all ${writes.length} documents match the version-controlled seed. No write was attempted.`);
  process.exit(0);
}
if (preflight) {
  console.log(`Read-only preflight passed for ${projectId}: ${writes.length} target paths checked, ${conflicts.length} existing. No write was attempted.`);
  if (conflicts.length > 0) console.log(`First existing target: ${conflicts[0]}`);
  process.exit(conflicts.length === 0 ? 0 : 2);
}
if (conflicts.length > 0) throw new Error(`Create-only seed refused because ${conflicts.length} target document(s) already exist. No write was attempted. First conflict: ${conflicts[0]}`);

const batch = firestore.batch();
for (const { ref, value } of writes) batch.create(ref, value);
await batch.commit();
const verification = await firestore.getAll(...writes.map(({ ref }) => ref));
const missing = verification.filter((snapshot) => !snapshot.exists).map((snapshot) => snapshot.ref.path);
if (missing.length > 0) throw new Error(`Seed commit returned but ${missing.length} target document(s) are missing.`);
console.log(`Created and verified ${writes.length} Firestore documents in ${emulator ? 'the local emulator' : projectId}. No document was updated or deleted.`);
