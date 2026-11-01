import assert from 'node:assert/strict';
import { after, before, beforeEach, test } from 'node:test';
import { readFile } from 'node:fs/promises';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { ref, uploadBytes, getBytes, deleteObject, listAll } from 'firebase/storage';

const projectId = 'demo-muenee-pj';
let environment;

const nutrition = {
  calories: 450,
  proteinGrams: 20,
  carbsGrams: 60,
  fatGrams: 14,
};

const profile = {
  schemaVersion: 1,
  displayName: 'Test owner',
  profile: {
    version: 1,
    age: 21,
    heightCm: 172,
    weightKg: 68,
    activityLevel: 'moderatelyActive',
  },
  preferences: {
    version: 1,
    restrictions: ['halalOnly'],
    dislikes: [],
    allergies: ['peanut'],
    hideDisliked: false,
  },
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
};

before(async () => {
  assert.equal(process.env.GCLOUD_PROJECT, projectId);
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8080');
  assert.equal(process.env.FIREBASE_STORAGE_EMULATOR_HOST, '127.0.0.1:9199');
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1', port: 8080,
      rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8'),
    },
    storage: {
      host: '127.0.0.1', port: 9199,
      rules: await readFile(new URL('../../storage.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'restaurants/active'), {
      schemaVersion: 1, isActive: true, name: 'Active restaurant',
    });
    await setDoc(doc(db, 'restaurants/inactive'), {
      schemaVersion: 1, isActive: false, name: 'Inactive restaurant',
    });
    await setDoc(doc(db, 'menu_items/active'), {
      schemaVersion: 1, restaurantId: 'active', isActive: true, name: 'Menu A',
    });
    await setDoc(doc(db, 'meal_logs/owner-meal'), {
      schemaVersion: 1,
      userId: 'owner',
      source: 'manual',
      foodName: 'Existing meal',
      nutrition,
      createdAt: new Date('2026-09-06T02:00:00Z'),
    });
    await uploadBytes(ref(context.storage(), 'fixtures/existing.txt'), new Uint8Array([1]));
  });
});

after(async () => { await environment?.cleanup(); });

test('public catalog exposes active documents but not inactive or unbounded lists', async () => {
  const db = environment.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(db, 'restaurants/active')));
  await assertFails(getDoc(doc(db, 'restaurants/inactive')));
  await assertSucceeds(getDocs(query(
    collection(db, 'restaurants'),
    where('isActive', '==', true),
    orderBy('name'),
  )));
  await assertSucceeds(getDocs(query(
    collection(db, 'menu_items'),
    where('restaurantId', '==', 'active'),
    where('isActive', '==', true),
    orderBy('name'),
  )));
  await assertFails(getDocs(collection(db, 'restaurants')));
  await assertFails(setDoc(doc(db, 'restaurants/client-write'), {
    schemaVersion: 1, isActive: true,
  }));
  await assertFails(updateDoc(doc(db, 'menu_items/active'), { name: 'Changed' }));
});

test('user documents are owner-only and validated', async () => {
  const owner = environment.authenticatedContext('owner').firestore();
  const stranger = environment.authenticatedContext('stranger').firestore();
  const ownerRef = doc(owner, 'users/owner');

  await assertSucceeds(setDoc(ownerRef, profile));
  await assertSucceeds(getDoc(ownerRef));
  await assertFails(getDoc(doc(stranger, 'users/owner')));
  await assertFails(getDocs(collection(owner, 'users')));
  await assertSucceeds(updateDoc(ownerRef, {
    displayName: 'Updated owner',
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ownerRef, {
    unexpectedField: true,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(owner, 'users/other'), profile));
  await assertSucceeds(deleteDoc(ownerRef));
});

test('meal logs require an authenticated matching owner and valid schema', async () => {
  const owner = environment.authenticatedContext('owner').firestore();
  const stranger = environment.authenticatedContext('stranger').firestore();
  const anonymous = environment.unauthenticatedContext().firestore();
  const newMeal = {
    schemaVersion: 1,
    userId: 'owner',
    source: 'food_scan',
    foodName: 'Test meal',
    nutrition,
    createdAt: serverTimestamp(),
  };

  await assertSucceeds(setDoc(doc(owner, 'meal_logs/new-meal'), newMeal));
  await assertFails(setDoc(doc(stranger, 'meal_logs/forged'), newMeal));
  await assertFails(setDoc(doc(anonymous, 'meal_logs/anonymous'), newMeal));
  await assertFails(setDoc(doc(owner, 'meal_logs/invalid-nutrition'), {
    ...newMeal,
    nutrition: { ...nutrition, calories: -1 },
  }));
  await assertSucceeds(setDoc(doc(owner, 'meal_logs/recommendation'), {
    ...newMeal,
    source: 'recommendation',
    menuId: 'menu-1',
    restaurantId: 'restaurant-1',
  }));
  await assertSucceeds(getDocs(query(
    collection(owner, 'meal_logs'),
    where('userId', '==', 'owner'),
    where('createdAt', '>=', new Date('2026-09-06T00:00:00Z')),
    where('createdAt', '<', new Date('2026-09-07T00:00:00Z')),
    orderBy('createdAt', 'desc'),
    limit(50),
  )));
  await assertFails(getDocs(collection(owner, 'meal_logs')));
  await assertFails(getDoc(doc(stranger, 'meal_logs/owner-meal')));
  await assertFails(updateDoc(doc(owner, 'meal_logs/owner-meal'), { userId: 'stranger' }));
  await assertSucceeds(deleteDoc(doc(owner, 'meal_logs/owner-meal')));
});

for (const signedIn of [false, true]) {
  const label = signedIn ? 'signed-in' : 'anonymous';
  const context = () => signedIn
    ? environment.authenticatedContext('owner')
    : environment.unauthenticatedContext();

  test(`Storage remains deny-all for ${label} access`, async () => {
    const storage = context().storage();
    await assertFails(getBytes(ref(storage, 'fixtures/existing.txt')));
    await assertFails(listAll(ref(storage, 'fixtures')));
    await assertFails(uploadBytes(ref(storage, `fixtures/${label}.txt`), new Uint8Array([1])));
    await assertFails(deleteObject(ref(storage, 'fixtures/existing.txt')));
  });
}
