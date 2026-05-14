import Foundation

struct DishIngredient: Identifiable, Equatable {
    let productId: String
    let productName: String
    let quantity: Double

    var id: String { "\(productId)-\(quantity)" }
}

struct Dish: Identifiable, Equatable {
    let id: String
    let name: String
    let photos: [String]
    let calories: Double
    let proteins: Double
    let fats: Double
    let carbs: Double
    let ingredients: [DishIngredient]
    let portionSize: Double
    let category: DishCategory
    let flags: Set<FeatureFlag>
    let createdAt: Date
    let updatedAt: Date?
}
