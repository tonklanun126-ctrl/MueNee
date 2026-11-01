import '../../profile/models/food_preferences.dart';
import 'menu_preview.dart';

// Fictional fixtures for the settings preview. Never use as restaurant seed data.
List<MenuPreview> sampleMenus(DateTime now) => [
  MenuPreview(
    id: 'sample-pork',
    name: 'ข้าวกะเพราหมู (ตัวอย่าง)',
    price: MenuPrice(
      amount: 55,
      confidence: PriceConfidence.verified,
      verifiedAt: now.subtract(const Duration(days: 3)),
      source: 'ใบเมนูจำลองสำหรับทดสอบ',
    ),
    ingredients: {FoodIngredient.pork},
    allergens: {FoodAllergen.soy, FoodAllergen.wheat, FoodAllergen.fish},
    ingredientsKnown: true,
    allergensKnown: true,
  ),
  MenuPreview(
    id: 'sample-vegetarian',
    name: 'ข้าวผัดเห็ดและเต้าหู้ (ตัวอย่าง)',
    price: MenuPrice(
      amount: 50,
      confidence: PriceConfidence.verified,
      verifiedAt: now.subtract(const Duration(days: 5)),
      source: 'ใบเมนูจำลองสำหรับทดสอบ',
    ),
    ingredients: {FoodIngredient.mushroom},
    allergens: {FoodAllergen.soy, FoodAllergen.wheat},
    ingredientsKnown: true,
    allergensKnown: true,
    vegetarianConfirmed: true,
  ),
  const MenuPreview(
    id: 'sample-chicken',
    name: 'ข้าวไก่อบฮาลาล (ตัวอย่าง)',
    price: MenuPrice(
      amount: 65,
      confidence: PriceConfidence.estimated,
      source: 'ราคาสมมติสำหรับทดสอบ',
    ),
    ingredients: {FoodIngredient.chicken, FoodIngredient.coriander},
    allergens: {FoodAllergen.soy, FoodAllergen.wheat},
    ingredientsKnown: true,
    allergensKnown: true,
    halalConfirmed: true,
  ),
  MenuPreview(
    id: 'sample-beef',
    name: 'ข้าวเนื้อผัด (ตัวอย่าง)',
    price: MenuPrice(
      amount: 70,
      confidence: PriceConfidence.verified,
      verifiedAt: now.subtract(const Duration(days: 45)),
      source: 'ใบเมนูจำลองเก่าสำหรับทดสอบ',
    ),
    ingredients: {FoodIngredient.beef},
    allergens: {FoodAllergen.soy, FoodAllergen.wheat},
    ingredientsKnown: true,
    allergensKnown: true,
  ),
  const MenuPreview(
    id: 'sample-egg',
    name: 'ข้าวไข่เจียว (ตัวอย่าง)',
    price: MenuPrice(amount: 40, confidence: PriceConfidence.unverified),
    ingredients: {FoodIngredient.egg},
    allergens: {FoodAllergen.egg},
    ingredientsKnown: true,
    allergensKnown: true,
    vegetarianConfirmed: true,
  ),
  const MenuPreview(
    id: 'sample-unknown',
    name: 'เมนูพิเศษ ข้อมูลส่วนผสมยังไม่ครบ (ตัวอย่าง)',
    price: MenuPrice(amount: 60, confidence: PriceConfidence.unverified),
  ),
];
