import test from 'node:test';
import assert from 'node:assert/strict';
import { loadSeedData, summarizeSeedData, validateSeedData } from '../../scripts/seed_data_lib.mjs';

test('checked-in seed data satisfies the Phase 5 contract', async () => {
  const data = await loadSeedData();
  assert.deepEqual(validateSeedData(data), []);
  assert.deepEqual(summarizeSeedData(data), { restaurants: 10, menuItems: 30, verifiedPrices: 15, unverifiedPrices: 15 });
});

test('validator rejects broken foreign keys and unsupported confidence', async () => {
  const data = structuredClone(await loadSeedData());
  data.menuItemsDocument.menuItems[0].restaurantId = 'missing-restaurant';
  data.menuItemsDocument.menuItems[1].price.confidence = 'certain';
  const errors = validateSeedData(data);
  assert.ok(errors.some((error) => error.includes('unknown restaurantId')));
  assert.ok(errors.some((error) => error.includes('invalid price confidence')));
});

test('validator rejects stale verified prices and duplicate Place IDs', async () => {
  const data = structuredClone(await loadSeedData());
  data.menuItemsDocument.menuItems[0].price.verifiedAt = '2026-07-01T00:00:00Z';
  data.restaurantsDocument.restaurants[1].googlePlaceId = data.restaurantsDocument.restaurants[0].googlePlaceId;
  const errors = validateSeedData(data);
  assert.ok(errors.some((error) => error.includes('at most 30 days old')));
  assert.ok(errors.some((error) => error.includes('duplicate Google Place ID')));
});
