import Foundation

struct ProductUpsertPayload {
    var name: String?
    var photos: [String]?
    var calories: Double?
    var proteins: Double?
    var fats: Double?
    var carbs: Double?
    var composition: String?
    var category: ProductCategory?
    var preparation: PreparationStatus?
    var flags: Set<FeatureFlag>?
}

struct DishIngredientInput: Equatable {
    var productId: String
    var quantity: Double
}

struct DishUpsertPayload {
    var name: String?
    var photos: [String]?
    var calories: Double?
    var proteins: Double?
    var fats: Double?
    var carbs: Double?
    var ingredients: [DishIngredientInput]?
    var portionSize: Double?
    var category: DishCategory?
    var flags: Set<FeatureFlag>?
}

struct ProductListFilters: Equatable {
    var category: ProductCategory?
    var preparation: PreparationStatus?
    var flags: Set<FeatureFlag> = []
    var search: String?
    var sortBy: ProductSortField = .name
    var sortOrder: SortOrder = .asc
}

struct DishListFilters: Equatable {
    var category: DishCategory?
    var flags: Set<FeatureFlag> = []
    var search: String?
}

struct ApiInfo: Equatable {
    let name: String
    let version: String
}
