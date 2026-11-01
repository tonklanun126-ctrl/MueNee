import { createHash } from 'node:crypto';
import { loadSeedData, summarizeSeedData, validateSeedData } from './seed_data_lib.mjs';

const data = await loadSeedData();
const errors = validateSeedData(data);
if (errors.length > 0) {
  console.error(`Seed validation failed with ${errors.length} error(s):`);
  for (const error of errors) console.error(`- ${error}`);
  process.exitCode = 1;
} else {
  const summary = summarizeSeedData(data);
  const digest = createHash('sha256').update(JSON.stringify(data)).digest('hex').slice(0, 16);
  console.log(`Seed validation passed: ${summary.restaurants} restaurants, ${summary.menuItems} menus, ${summary.verifiedPrices} verified prices, ${summary.unverifiedPrices} unverified prices, digest ${digest}.`);
}
