/// Centralized emoji constants for the entire app.
/// All emojis should be referenced from here for consistency.
class AppEmojis {
  AppEmojis._();

  // Outcome emojis
  static const outcomeSuccess = '\u{1F60A}'; // 😊
  static const outcomePartial = '\u{1F642}'; // 🙂
  static const outcomeFailed = '\u{1F622}'; // 😢
  static const outcomeDefault = '\u{1F373}'; // 🍳

  // Streak celebration emojis
  static const streakLegendary = '\u{1F451}'; // 👑 30+ days
  static const streakAmazing = '\u{1F31F}'; // 🌟 14+ days
  static const streakGreat = '\u{1F525}'; // 🔥 7+ days
  static const streakNice = '\u{2728}'; // ✨ 3+ days
  static const streakStarted = '\u{1F3AF}'; // 🎯 started
  static const streakIndicator = '\u{1F525}'; // 🔥

  // Recipe metadata emojis
  static const recipeOriginal = '\u{1F4CC}'; // 📌
  static const recipeVariant = '\u{1F504}'; // 🔄
  static const recipeFeatured = '\u{2B50}'; // ⭐
  static const recipeLog = '\u{1F4F7}'; // 📷
  static const recipeBasedOn = '\u{1F4CD}'; // 📍

  // Ingredient category emojis
  static const ingredientMain = '\u{1F969}'; // 🥩
  static const ingredientSecondary = '\u{1F96C}'; // 🥬
  static const ingredientSeasoning = '\u{1F336}\u{FE0F}'; // 🌶️

  // Misc
  static const trending = '\u{1F525}'; // 🔥
}
