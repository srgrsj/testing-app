import Foundation

struct Product: Identifiable, Equatable {
    let id: String
    let name: String
    let photos: [String]
    let calories: Double
    let proteins: Double
    let fats: Double
    let carbs: Double
    let composition: String?
    let category: ProductCategory
    let preparation: PreparationStatus
    let flags: Set<FeatureFlag>
    let createdAt: Date
    let updatedAt: Date?
}
