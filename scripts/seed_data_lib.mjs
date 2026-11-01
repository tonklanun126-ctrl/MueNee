import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
export const projectRoot = path.resolve(scriptDirectory, '..');

const idPattern = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const placeIdPattern = /^ChIJ[A-Za-z0-9_-]{20,}$/;
const restaurantStatuses = new Set(['unverified', 'pending', 'verified']);
const priceConfidences = new Set(['verified', 'estimated', 'unverified']);
const ingredients = new Set([
  'pork', 'beef', 'chicken', 'fish', 'shellfish', 'egg', 'milk',
  'mushroom', 'coriander', 'offal',
]);
const allergens = new Set([
  'peanut', 'treeNuts', 'milk', 'egg', 'soy', 'wheat', 'fish',
  'shellfish', 'sesame',
]);

function requireCondition(condition, message, errors) {
  if (!condition) errors.push(message);
}

function validDate(value) {
  return typeof value === 'string' && !Number.isNaN(Date.parse(value));
}

function validHttpsUrl(value) {
  if (typeof value !== 'string') return false;
  try {
    return new URL(value).protocol === 'https:';
  } catch {
    return false;
  }
}

function distanceKm(first, second) {
  const radians = (degrees) => degrees * Math.PI / 180;
  const latitudeDelta = radians(second.latitude - first.latitude);
  const longitudeDelta = radians(second.longitude - first.longitude);
  const a = Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(radians(first.latitude)) * Math.cos(radians(second.latitude)) *
    Math.sin(longitudeDelta / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export async function loadSeedData(root = projectRoot) {
  const [restaurantText, menuText] = await Promise.all([
    readFile(path.join(root, 'data', 'restaurants.json'), 'utf8'),
    readFile(path.join(root, 'data', 'menu_items.json'), 'utf8'),
  ]);
  return {
    restaurantsDocument: JSON.parse(restaurantText),
    menuItemsDocument: JSON.parse(menuText),
  };
}

export function validateSeedData({ restaurantsDocument, menuItemsDocument }) {
  const errors = [];
  const restaurantList = restaurantsDocument?.restaurants;
  const menuList = menuItemsDocument?.menuItems;
  requireCondition(restaurantsDocument?.datasetVersion === 1, 'restaurants datasetVersion must be 1', errors);
  requireCondition(menuItemsDocument?.datasetVersion === 1, 'menu_items datasetVersion must be 1', errors);
  requireCondition(validDate(restaurantsDocument?.checkedAt), 'restaurants checkedAt must be an ISO date', errors);
  requireCondition(validDate(menuItemsDocument?.checkedAt), 'menu_items checkedAt must be an ISO date', errors);
  requireCondition(typeof menuItemsDocument?.nutritionNotice === 'string' && menuItemsDocument.nutritionNotice.includes('estimate'), 'nutritionNotice must disclose estimates', errors);
  requireCondition(Array.isArray(restaurantList), 'restaurants must be an array', errors);
  requireCondition(Array.isArray(menuList), 'menuItems must be an array', errors);
  if (!Array.isArray(restaurantList) || !Array.isArray(menuList)) return errors;

  requireCondition(restaurantList.length >= 10 && restaurantList.length <= 20, 'restaurant count must be 10-20', errors);
  const center = restaurantsDocument?.area?.center;
  const maxDistanceKm = restaurantsDocument?.area?.maxDistanceKm;
  requireCondition(Number.isFinite(center?.latitude) && Number.isFinite(center?.longitude), 'area center is invalid', errors);
  requireCondition(Number.isFinite(maxDistanceKm) && maxDistanceKm > 0, 'area maxDistanceKm is invalid', errors);

  const restaurantIds = new Set();
  const placeIds = new Set();
  for (const item of restaurantList) {
    const label = `restaurant ${item?.id ?? '<missing>'}`;
    requireCondition(item?.schemaVersion === 1, `${label}: schemaVersion must be 1`, errors);
    requireCondition(idPattern.test(item?.id ?? ''), `${label}: invalid id`, errors);
    requireCondition(!restaurantIds.has(item?.id), `${label}: duplicate id`, errors);
    restaurantIds.add(item?.id);
    requireCondition(typeof item?.name === 'string' && item.name.trim().length > 0, `${label}: name is required`, errors);
    requireCondition(placeIdPattern.test(item?.googlePlaceId ?? ''), `${label}: invalid Google Place ID`, errors);
    requireCondition(!placeIds.has(item?.googlePlaceId), `${label}: duplicate Google Place ID`, errors);
    placeIds.add(item?.googlePlaceId);
    requireCondition(Number.isFinite(item?.location?.latitude) && item.location.latitude >= -90 && item.location.latitude <= 90, `${label}: invalid latitude`, errors);
    requireCondition(Number.isFinite(item?.location?.longitude) && item.location.longitude >= -180 && item.location.longitude <= 180, `${label}: invalid longitude`, errors);
    if (center && Number.isFinite(item?.location?.latitude) && Number.isFinite(item?.location?.longitude) && Number.isFinite(maxDistanceKm)) {
      requireCondition(distanceKm(center, item.location) <= maxDistanceKm, `${label}: outside the ${maxDistanceKm} km MVP area`, errors);
    }
    requireCondition(typeof item?.address === 'string' && item.address.trim().length > 0, `${label}: address is required`, errors);
    requireCondition(item?.rating === undefined || (Number.isFinite(item.rating) && item.rating >= 0 && item.rating <= 5), `${label}: rating must be 0-5`, errors);
    requireCondition(restaurantStatuses.has(item?.verificationStatus), `${label}: invalid verificationStatus`, errors);
    requireCondition(typeof item?.isActive === 'boolean', `${label}: isActive must be boolean`, errors);
    requireCondition(validDate(item?.createdAt) && validDate(item?.updatedAt) && Date.parse(item.updatedAt) >= Date.parse(item.createdAt), `${label}: invalid timestamps`, errors);
    requireCondition(validHttpsUrl(item?.provenance?.sourceUrl), `${label}: provenance sourceUrl must use HTTPS`, errors);
    requireCondition(validDate(item?.provenance?.checkedAt), `${label}: provenance checkedAt is invalid`, errors);
  }

  const menuIds = new Set();
  const menusPerRestaurant = new Map([...restaurantIds].map((id) => [id, 0]));
  for (const item of menuList) {
    const label = `menu ${item?.id ?? '<missing>'}`;
    requireCondition(item?.schemaVersion === 1, `${label}: schemaVersion must be 1`, errors);
    requireCondition(idPattern.test(item?.id ?? ''), `${label}: invalid id`, errors);
    requireCondition(!menuIds.has(item?.id), `${label}: duplicate id`, errors);
    menuIds.add(item?.id);
    requireCondition(restaurantIds.has(item?.restaurantId), `${label}: unknown restaurantId`, errors);
    if (menusPerRestaurant.has(item?.restaurantId)) menusPerRestaurant.set(item.restaurantId, menusPerRestaurant.get(item.restaurantId) + 1);
    requireCondition(typeof item?.name === 'string' && item.name.trim().length > 0, `${label}: name is required`, errors);
    requireCondition(Number.isInteger(item?.price?.amount) && item.price.amount >= 0, `${label}: price amount must be non-negative integer baht`, errors);
    requireCondition(priceConfidences.has(item?.price?.confidence), `${label}: invalid price confidence`, errors);
    if (item?.price?.source !== undefined) requireCondition(validHttpsUrl(item.price.source), `${label}: price source must use HTTPS`, errors);
    if (item?.price?.confidence === 'verified') {
      requireCondition(validHttpsUrl(item.price.source), `${label}: verified price requires source`, errors);
      requireCondition(validDate(item.price.verifiedAt), `${label}: verified price requires verifiedAt`, errors);
      if (validDate(item.price.verifiedAt) && validDate(item.updatedAt)) {
        const ageDays = (Date.parse(item.updatedAt) - Date.parse(item.price.verifiedAt)) / 86400000;
        requireCondition(ageDays >= 0 && ageDays <= 30, `${label}: verified price evidence must be at most 30 days old`, errors);
      }
    } else {
      requireCondition(item?.price?.verifiedAt === undefined, `${label}: non-verified price must not have verifiedAt`, errors);
    }
    const nutrition = item?.nutrition;
    requireCondition(Number.isInteger(nutrition?.calories) && nutrition.calories >= 0 && nutrition.calories <= 10000, `${label}: invalid calories`, errors);
    for (const field of ['proteinGrams', 'carbsGrams', 'fatGrams']) requireCondition(Number.isFinite(nutrition?.[field]) && nutrition[field] >= 0 && nutrition[field] <= 1000, `${label}: invalid ${field}`, errors);
    requireCondition(Array.isArray(item?.tags) && item.tags.every((value) => typeof value === 'string' && value.trim()), `${label}: invalid tags`, errors);
    requireCondition(Array.isArray(item?.ingredients) && item.ingredients.every((value) => ingredients.has(value)), `${label}: invalid ingredients`, errors);
    requireCondition(Array.isArray(item?.allergens) && item.allergens.every((value) => allergens.has(value)), `${label}: invalid allergens`, errors);
    for (const field of ['ingredientsKnown', 'allergensKnown', 'vegetarianConfirmed', 'halalConfirmed', 'isActive']) requireCondition(typeof item?.[field] === 'boolean', `${label}: ${field} must be boolean`, errors);
    requireCondition(validDate(item?.createdAt) && validDate(item?.updatedAt) && Date.parse(item.updatedAt) >= Date.parse(item.createdAt), `${label}: invalid timestamps`, errors);
  }
  for (const [restaurantId, count] of menusPerRestaurant) requireCondition(count >= 3 && count <= 5, `restaurant ${restaurantId}: menu count must be 3-5, received ${count}`, errors);
  return errors;
}

export function summarizeSeedData(data) {
  const restaurants = data.restaurantsDocument.restaurants;
  const menuItems = data.menuItemsDocument.menuItems;
  return {
    restaurants: restaurants.length,
    menuItems: menuItems.length,
    verifiedPrices: menuItems.filter((item) => item.price.confidence === 'verified').length,
    unverifiedPrices: menuItems.filter((item) => item.price.confidence === 'unverified').length,
  };
}
