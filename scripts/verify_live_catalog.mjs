import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { deleteApp, initializeApp } from 'firebase/app';
import { collection, getDocs, getFirestore, orderBy, query, terminate, where } from 'firebase/firestore';
import { loadSeedData, projectRoot } from './seed_data_lib.mjs';

const configPath = path.join(projectRoot, 'config', 'firebase.local.json');
const config = JSON.parse(await readFile(configPath, 'utf8'));
if (config.FIREBASE_PROJECT_ID !== 'muenee-pj') throw new Error('Local Firebase config is not for muenee-pj.');

const app = initializeApp({
  apiKey: config.FIREBASE_API_KEY,
  appId: config.FIREBASE_ANDROID_APP_ID,
  messagingSenderId: config.FIREBASE_MESSAGING_SENDER_ID,
  projectId: config.FIREBASE_PROJECT_ID,
  storageBucket: config.FIREBASE_STORAGE_BUCKET,
});
const firestore = getFirestore(app);
const [restaurantsSnapshot, menusSnapshot, seed] = await Promise.all([
  getDocs(query(collection(firestore, 'restaurants'), where('isActive', '==', true), orderBy('name'))),
  getDocs(query(collection(firestore, 'menu_items'), where('isActive', '==', true))),
  loadSeedData(),
]);
const expectedRestaurants = seed.restaurantsDocument.restaurants.map((item) => item.id).sort();
const expectedMenus = seed.menuItemsDocument.menuItems.map((item) => item.id).sort();
const actualRestaurants = restaurantsSnapshot.docs.map((item) => item.id).sort();
const actualMenus = menusSnapshot.docs.map((item) => item.id).sort();
if (JSON.stringify(actualRestaurants) !== JSON.stringify(expectedRestaurants)) throw new Error('Public restaurant query does not match the seed IDs.');
if (JSON.stringify(actualMenus) !== JSON.stringify(expectedMenus)) throw new Error('Public menu query does not match the seed IDs.');
console.log(`Public live-client verification passed: ${actualRestaurants.length} active restaurants and ${actualMenus.length} active menus are readable from muenee-pj.`);
await terminate(firestore);
await deleteApp(app);
