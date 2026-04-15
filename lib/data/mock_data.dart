import 'package:flutter/material.dart';
import '../models/models.dart';

final List<Recipe> recipes = [
  Recipe(
    id: '1',
    name: 'Adobo Tofu',
    color: const Color(0xFF8B6914),
    emoji: '🥢',
    caloriesPerServing: 100,
    imageUrl: 'https://www.themealdb.com/images/media/meals/1529442605.jpg',
    tags: ['Tofu', 'Low Sodium Soy Sauce', 'Lime', 'Lemon', 'Cider Vinegar',
           'Peppercorns', 'Bay Leaves', 'Garlic', 'Canola Oil'],
    ingredients: [
      '400g extra-firm tofu or tokwa',
      '2-3 tbsp low sodium soy sauce',
      '2-3 tbsp lime, lemon, or cider vinegar',
      '4 dried bay leaves or laurel leaves',
      '10 cloves garlic, crushed or smashed',
      '1 medium red onion sliced into squares or strips',
      '½ cup vegetable stock or broth or just water',
      '3-4 tbsp Canola oil',
    ],
    directions: [
      'Prep your tofu to remove excess water. Slice into cubes or shapes of your choice.',
      'Heat a large non-stick pan or skillet. Pan-fry the tofu in oil until golden brown on all sides.',
      'Move the tofu to the side of the pan. Add onions, garlic, and peppercorns. Sauté 3-4 minutes.',
      'Add the bay leaves, soy sauce, vinegar, and vegetable broth. Mix well and bring to a boil.',
      'Leave the tofu to cook in the sauce for 10-15 minutes or until reduced.',
      'Serve hot with steamed rice.',
    ],
    nutritionFacts: const {
      'Total Fat':       NutritionFact(10, 13),
      'Saturated Fat':   NutritionFact(1, 5),
      'Cholesterol':     NutritionFact(0, 0),
      'Sodium':          NutritionFact(250, 11),
      'Total Carbs':     NutritionFact(8, 3),
      'Dietary Fiber':   NutritionFact(2, 7),
      'Sugars':          NutritionFact(1, 0),
      'Protein':         NutritionFact(10, 20),
      'Potassium':       NutritionFact(400, 9),
    },
  ),
  Recipe(
    id: '2',
    name: 'Sinigang Pork',
    color: const Color(0xFFC0522A),
    emoji: '🍲',
    caloriesPerServing: 88,
    imageUrl: 'https://www.themealdb.com/images/media/meals/1520084746.jpg',
    tags: ['Pork', 'Tamarind', 'Vegetables', 'Fish Sauce', 'Onion', 'Tomatoes'],
    ingredients: [
      '500g pork belly or ribs',
      '1 pack sinigang mix or 3-4 pieces tamarind',
      '1 medium onion quartered',
      '3 medium tomatoes quartered',
      '2 pieces long green chili',
      '1 bundle kangkong or spinach',
      '100g sitaw (string beans)',
      '1 medium radish sliced',
      'Fish sauce to taste',
      '6 cups water',
    ],
    directions: [
      'In a large pot, bring water to a boil. Add the pork and simmer for 45 minutes.',
      'Add onion and tomatoes. Continue simmering for 10 minutes.',
      'Add sinigang mix or tamarind. Stir and taste for sourness.',
      'Add radish and string beans. Cook for 5 minutes.',
      'Add kangkong or spinach and long green chili. Cook for 2-3 minutes.',
      'Season with fish sauce to taste. Serve hot with rice.',
    ],
    nutritionFacts: const {
      'Total Fat':       NutritionFact(18, 23),
      'Saturated Fat':   NutritionFact(6, 30),
      'Cholesterol':     NutritionFact(75, 25),
      'Sodium':          NutritionFact(580, 25),
      'Total Carbs':     NutritionFact(12, 4),
      'Dietary Fiber':   NutritionFact(3, 11),
      'Sugars':          NutritionFact(4, 0),
      'Protein':         NutritionFact(15, 30),
      'Potassium':       NutritionFact(520, 11),
    },
  ),
  Recipe(
    id: '3',
    name: 'Salmon Salad',
    color: const Color(0xFFE88040),
    emoji: '🥗',
    caloriesPerServing: 140,
    imageUrl: 'https://www.themealdb.com/images/media/meals/1548772327.jpg',
    tags: ['Salmon', 'Lettuce', 'Cucumber', 'Tomatoes', 'Olive Oil', 'Lemon'],
    ingredients: [
      '200g grilled salmon fillet',
      '2 cups mixed greens or romaine lettuce',
      '1 medium cucumber sliced',
      '1 cup cherry tomatoes halved',
      '¼ red onion thinly sliced',
      '2 tbsp olive oil',
      '1 tbsp lemon juice',
      'Salt and pepper to taste',
    ],
    directions: [
      'Grill or pan-sear salmon seasoned with salt and pepper for 4-5 minutes per side.',
      'Let salmon cool slightly then flake into large pieces.',
      'In a large bowl, combine lettuce, cucumber, tomatoes, and red onion.',
      'Whisk together olive oil, lemon juice, salt, and pepper to make dressing.',
      'Toss salad with dressing. Top with flaked salmon and serve.',
    ],
    nutritionFacts: const {
      'Total Fat':       NutritionFact(16, 21),
      'Saturated Fat':   NutritionFact(3, 15),
      'Cholesterol':     NutritionFact(60, 20),
      'Sodium':          NutritionFact(320, 14),
      'Total Carbs':     NutritionFact(8, 3),
      'Dietary Fiber':   NutritionFact(2, 7),
      'Sugars':          NutritionFact(4, 0),
      'Protein':         NutritionFact(22, 44),
      'Potassium':       NutritionFact(620, 13),
    },
  ),
  Recipe(
    id: '4',
    name: 'Pancit Canton',
    color: const Color(0xFFB8860B),
    emoji: '🍜',
    caloriesPerServing: 160,
    imageUrl: 'https://www.themealdb.com/images/media/meals/uwxqwy1484826554.jpg',
    tags: ['Noodles', 'Pork', 'Vegetables', 'Soy Sauce', 'Oyster Sauce'],
    ingredients: [
      '200g pancit canton noodles',
      '150g pork belly thinly sliced',
      '100g shrimp peeled',
      '1 cup cabbage shredded',
      '1 carrot julienned',
      '1 cup snap peas',
      '3 cloves garlic minced',
      '1 medium onion sliced',
      '3 tbsp soy sauce',
      '2 tbsp oyster sauce',
      '2 cups chicken broth',
      '2 tbsp cooking oil',
    ],
    directions: [
      'Heat oil in a large wok or pan over high heat.',
      'Sauté garlic and onion until fragrant, about 2 minutes.',
      'Add pork and cook until no longer pink, about 3 minutes.',
      'Add shrimp and cook until pink, about 2 minutes.',
      'Add chicken broth, soy sauce, and oyster sauce. Bring to a boil.',
      'Add noodles and toss to coat. Cook until noodles absorb most of the liquid.',
      'Add vegetables and toss until cooked but still crisp. Serve with calamansi.',
    ],
    nutritionFacts: const {
      'Total Fat':       NutritionFact(9, 12),
      'Saturated Fat':   NutritionFact(2, 10),
      'Cholesterol':     NutritionFact(55, 18),
      'Sodium':          NutritionFact(780, 34),
      'Total Carbs':     NutritionFact(42, 15),
      'Dietary Fiber':   NutritionFact(3, 11),
      'Sugars':          NutritionFact(3, 0),
      'Protein':         NutritionFact(14, 28),
      'Potassium':       NutritionFact(380, 8),
    },
  ),
  Recipe(
    id: '5',
    name: 'Mung Bean Soup',
    color: const Color(0xFF4A7C4E),
    emoji: '🥣',
    caloriesPerServing: 120,
    imageUrl: 'https://www.themealdb.com/images/media/meals/ml0karr1608782081.jpg',
    tags: ['Mung Beans', 'Pork', 'Garlic', 'Onion', 'Fish Sauce', 'Spinach'],
    ingredients: [
      '1 cup mung beans (monggo)',
      '150g pork belly or ground pork',
      '3 cloves garlic minced',
      '1 medium onion diced',
      '2 medium tomatoes diced',
      '2 cups malunggay leaves or spinach',
      '4 cups water',
      '2 tbsp fish sauce',
    ],
    directions: [
      'Cook mung beans in water for 30-40 minutes until soft.',
      'In a separate pan, sauté garlic, onion, and tomatoes in oil.',
      'Add pork and cook until browned, about 5 minutes.',
      'Add the pork mixture to the cooked mung beans.',
      'Season with fish sauce, salt, and pepper.',
      'Add malunggay or spinach and cook for 2-3 more minutes. Serve hot.',
    ],
    nutritionFacts: const {
      'Total Fat':       NutritionFact(5, 6),
      'Saturated Fat':   NutritionFact(1, 5),
      'Cholesterol':     NutritionFact(25, 8),
      'Sodium':          NutritionFact(480, 21),
      'Total Carbs':     NutritionFact(30, 11),
      'Dietary Fiber':   NutritionFact(8, 29),
      'Sugars':          NutritionFact(2, 0),
      'Protein':         NutritionFact(10, 20),
      'Potassium':       NutritionFact(560, 12),
    },
  ),
  Recipe(
    id: '6',
    name: 'Lumpia Sariwa',
    color: const Color(0xFF5A8C3E),
    emoji: '🌯',
    caloriesPerServing: 90,
    imageUrl: 'https://www.themealdb.com/images/media/meals/xxrxux1503510175.jpg',
    tags: ['Vegetables', 'Pork', 'Shrimp', 'Wrapper', 'Garlic Sauce'],
    ingredients: [
      '8 fresh lumpia wrappers',
      '100g pork giniling (ground)',
      '50g shrimp peeled',
      '1 cup bean sprouts',
      '1 cup cabbage shredded',
      '1 carrot shredded',
      '50g tofu cubed and fried',
      '3 cloves garlic minced',
      '1 medium onion diced',
      '2 tbsp soy sauce',
      'Lettuce leaves for lining',
    ],
    directions: [
      'Sauté garlic and onion in oil until fragrant.',
      'Add pork and cook until browned.',
      'Add shrimp and cook until pink.',
      'Add all vegetables and tofu. Stir-fry for 3-4 minutes.',
      'Season with soy sauce and salt. Let the filling cool.',
      'Line each wrapper with lettuce, add filling, then wrap tightly.',
      'Serve with sweet garlic sauce on top.',
    ],
    nutritionFacts: const {
      'Total Fat':       NutritionFact(4, 5),
      'Saturated Fat':   NutritionFact(1, 5),
      'Cholesterol':     NutritionFact(40, 13),
      'Sodium':          NutritionFact(340, 15),
      'Total Carbs':     NutritionFact(22, 8),
      'Dietary Fiber':   NutritionFact(3, 11),
      'Sugars':          NutritionFact(5, 0),
      'Protein':         NutritionFact(8, 16),
      'Potassium':       NutritionFact(310, 7),
    },
  ),
  Recipe(
    id: '7',
    name: 'Papaya Salad',
    color: const Color(0xFFE8A020),
    emoji: '🥗',
    caloriesPerServing: 75,
    imageUrl: 'https://www.themealdb.com/images/media/meals/llcbn01574ldoy1574.jpg',
    tags: ['Green Papaya', 'Tomatoes', 'Fish Sauce', 'Lime', 'Chili', 'Peanuts'],
    ingredients: [
      '2 cups green papaya shredded',
      '1 cup cherry tomatoes halved',
      '2 tbsp fish sauce',
      '2 tbsp lime juice',
      '1 tsp sugar',
      '2 cloves garlic minced',
      '1-2 Thai chilis (optional)',
      '2 tbsp roasted peanuts crushed',
    ],
    directions: [
      'Peel and shred green papaya using a box grater or mandoline.',
      'Soak shredded papaya in cold water for 10 minutes. Drain well.',
      'In a bowl, mix fish sauce, lime juice, sugar, and garlic.',
      'Toss papaya and tomatoes with the dressing.',
      'Add chilis if using. Garnish with crushed peanuts and serve.',
    ],
    nutritionFacts: const {
      'Total Fat':       NutritionFact(4, 5),
      'Saturated Fat':   NutritionFact(1, 5),
      'Cholesterol':     NutritionFact(0, 0),
      'Sodium':          NutritionFact(490, 21),
      'Total Carbs':     NutritionFact(18, 7),
      'Dietary Fiber':   NutritionFact(3, 11),
      'Sugars':          NutritionFact(10, 0),
      'Protein':         NutritionFact(3, 6),
      'Potassium':       NutritionFact(290, 6),
    },
  ),
  Recipe(
    id: '8',
    name: 'Corn Soup',
    color: const Color(0xFFD4A017),
    emoji: '🌽',
    caloriesPerServing: 100,
    imageUrl: 'https://www.themealdb.com/images/media/meals/v8ywws1572182311.jpg',
    tags: ['Corn', 'Chicken', 'Egg', 'Garlic', 'Ginger', 'Sesame Oil'],
    ingredients: [
      '2 cups sweet corn kernels',
      '150g chicken breast minced',
      '2 eggs beaten',
      '3 cloves garlic minced',
      '1 inch ginger minced',
      '4 cups chicken broth',
      '2 tbsp cornstarch mixed with 3 tbsp water',
      '1 tsp sesame oil',
    ],
    directions: [
      'Bring chicken broth to a boil in a medium pot.',
      'Add garlic, ginger, and corn. Cook for 5 minutes.',
      'Add minced chicken and stir to separate. Cook 3 minutes.',
      'Stir in cornstarch mixture until soup thickens.',
      'Slowly drizzle beaten eggs while stirring to create egg ribbons.',
      'Season with sesame oil, salt, and white pepper. Garnish with green onions.',
    ],
    nutritionFacts: const {
      'Total Fat':       NutritionFact(5, 6),
      'Saturated Fat':   NutritionFact(1, 5),
      'Cholesterol':     NutritionFact(80, 27),
      'Sodium':          NutritionFact(520, 23),
      'Total Carbs':     NutritionFact(24, 9),
      'Dietary Fiber':   NutritionFact(2, 7),
      'Sugars':          NutritionFact(6, 0),
      'Protein':         NutritionFact(12, 24),
      'Potassium':       NutritionFact(340, 7),
    },
  ),
];

final List<String> allIngredients = [
  'Chicken', 'Pork', 'Beef', 'Garlic', 'Bay Leaves', 'Vinegar', 'Soy Sauce',
  'Peppercorn', 'Okra', 'Salt', 'Onion', 'Ground Black Pepper', 'Noodles',
  'Tomato Sauce', 'Liver Spread', 'Chili Flakes', 'Potatoes', 'Cabbage',
  'Green Onions', 'Bell Peppers', 'Bok Choy', 'Carrots', 'Oyster Sauce',
  'Cornstarch', 'Eggplant', 'String Beans', 'Tofu', 'Mung Beans', 'Spinach',
  'Shrimp', 'Fish Sauce', 'Tamarind', 'Coconut Milk', 'Ginger',
];

final List<DietPlan> dietPlans = [
  DietPlan(
    id: '1',
    name: 'Mediterranean Diet',
    emoji: '🫒',
    color: const Color(0xFF3D7A48),
    imageUrl: 'https://www.themealdb.com/images/media/meals/llcbn01574ldoy1574.jpg',
    description:
        'Mediterranean Diet is a diet where you will eat more lower-calorie foods and healthy fats.\n\n'
        '• Lots of vegetables, fruit, beans, lentils and nuts\n'
        '• A good amount of whole grains, like whole grain bread, pasta and brown rice\n'
        '• Plenty of olive oil on food\n'
        '• A good amount of fish, especially fish rich in omega-3 fatty acids',
    foods: [
      'Acorn Squash', 'Artichokes', 'Arugula', 'Asparagus', 'Beet Greens',
      'Broccoli', 'Butternut Squash', 'Cabbage', 'Brussels Sprouts', 'Celery',
      'Collard Greens', 'Cucumber', 'Eggplant', 'Kale', 'Leeks', 'Lentils',
      'Mushrooms', 'Mustard Greens', 'Onions', 'Peppers', 'Potatoes', 'Radishes',
      'Squash', 'Sweet Potatoes', 'Swiss Chard', 'Tomatoes', 'Turnips', 'Zucchini',
      'Apples', 'Avocados', 'Bananas', 'Blueberries', 'Cherries', 'Dates',
      'Figs', 'Grapes', 'Lemon', 'Mango', 'Oranges', 'Peaches', 'Pears',
      'Strawberries', 'Watermelon', 'Almonds', 'Cashews', 'Flaxseed',
      'Walnuts', 'Black Beans', 'Chickpeas', 'Kidney Beans',
    ],
  ),
  DietPlan(
    id: '2',
    name: 'DASH Diet',
    emoji: '🫀',
    color: const Color(0xFF2196F3),
    imageUrl: 'https://www.themealdb.com/images/media/meals/1520084746.jpg',
    description:
        'The DASH Diet (Dietary Approaches to Stop Hypertension) is designed to help treat or prevent high blood pressure.\n\n'
        '• Rich in fruits and vegetables\n'
        '• Includes whole grains and fat-free or low-fat dairy\n'
        '• Includes lean meats, poultry, fish\n'
        '• Limits foods high in saturated fats',
    foods: [
      'Apples', 'Apricots', 'Bananas', 'Blueberries', 'Grapes', 'Oranges',
      'Grapefruit', 'Mangoes', 'Peaches', 'Pineapples', 'Strawberries',
      'Asparagus', 'Beans', 'Beets', 'Broccoli', 'Carrots', 'Corn', 'Eggplant',
      'Green Peas', 'Kale', 'Potatoes', 'Squash', 'Sweet Potatoes', 'Tomatoes',
      'Low-fat Milk', 'Low-fat Cheese', 'Low-fat Yogurt', 'Chicken Breast',
      'Salmon', 'Tuna', 'Turkey', 'Almonds', 'Mixed Nuts',
    ],
  ),
  DietPlan(
    id: '3',
    name: 'Veganism Diet',
    emoji: '🌱',
    color: const Color(0xFF4CAF50),
    imageUrl: 'https://www.themealdb.com/images/media/meals/1548772327.jpg',
    description:
        'A vegan diet excludes all animal products and is rich in plant-based foods.\n\n'
        '• All fruits and vegetables\n'
        '• Legumes such as peas, beans, and lentils\n'
        '• Nuts and seeds\n'
        '• Whole grain breads and pastas\n'
        '• Dairy alternatives like soy milk and coconut milk',
    foods: [
      'Tofu', 'Tempeh', 'Seitan', 'Lentils', 'Chickpeas', 'Black Beans',
      'Edamame', 'Nuts', 'Seeds', 'Almond Milk', 'Soy Milk', 'Oat Milk',
      'Quinoa', 'Brown Rice', 'Oats', 'Wheat Bread', 'Avocado', 'Berries',
      'Bananas', 'Apples', 'Oranges', 'Spinach', 'Kale', 'Broccoli',
      'Sweet Potatoes', 'Bell Peppers', 'Mushrooms',
    ],
  ),
  DietPlan(
    id: '4',
    name: 'Flexitarian Diet',
    emoji: '🥦',
    color: const Color(0xFFFF9800),
    imageUrl: 'https://www.themealdb.com/images/media/meals/uwxqwy1484826554.jpg',
    description:
        'Flexitarianism is a mostly vegetarian diet that allows occasional meat and animal products.\n\n'
        '• Primarily plant-based foods\n'
        '• Occasional animal products\n'
        '• Emphasis on protein from plant sources\n'
        '• Flexible enough to include all foods in moderation',
    foods: [
      'Tofu', 'Legumes', 'Eggs', 'Dairy', 'Chicken', 'Fish', 'Quinoa',
      'Vegetables', 'Fruits', 'Whole Grains', 'Nuts', 'Seeds', 'Lentils',
      'Beans', 'Greek Yogurt', 'Low-fat Milk', 'Turkey', 'Salmon',
    ],
  ),
];

List<ScheduledMeal> initialScheduledMeals() =>
    scheduledMealsForDate(DateTime.now());

/// Returns 4 meals (Breakfast/Lunch/Snacks/Dinner) for the given [date],
/// rotating through available recipes so each day shows different foods.
List<ScheduledMeal> scheduledMealsForDate(DateTime date) {
  final base = DateTime(2024, 1, 1);
  final offset = date.difference(base).inDays.abs();
  final n = recipes.length;
  return [
    ScheduledMeal(
        mealType: 'Breakfast',
        recipe: recipes[offset % n],
        time: '8:00 AM'),
    ScheduledMeal(
        mealType: 'Lunch',
        recipe: recipes[(offset + 2) % n],
        time: '12:00 PM'),
    ScheduledMeal(
        mealType: 'Snacks',
        recipe: recipes[(offset + 4) % n],
        time: '3:00 PM'),
    ScheduledMeal(
        mealType: 'Dinner',
        recipe: recipes[(offset + 6) % n],
        time: '7:00 PM'),
  ];
}
