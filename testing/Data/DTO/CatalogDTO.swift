import Foundation

struct ApiInfoDTO: Codable {
    let name: String
    let version: String
}

struct ErrorDTO: Codable {
    let message: String
}

struct RelatedDishDTO: Codable {
    let id: String
    let name: String
}

struct ProductDeleteConflictDTO: Codable {
    let message: String
    let dishes: [RelatedDishDTO]
}

struct ProductDTO: Codable {
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
    let createdAt: String
    let updatedAt: String?
}

struct ProductUpsertDTO: Codable {
    let name: String?
    let photos: [String]?
    let calories: Double?
    let proteins: Double?
    let fats: Double?
    let carbs: Double?
    let composition: String?
    let category: ProductCategory?
    let preparation: PreparationStatus?
    let flags: Set<FeatureFlag>?
}

struct DishIngredientDTO: Codable {
    let productId: String
    let productName: String
    let quantity: Double
}

struct DishIngredientRequestDTO: Codable {
    let productId: String
    let quantity: Double
}

struct DishDTO: Codable {
    let id: String
    let name: String
    let photos: [String]
    let calories: Double
    let proteins: Double
    let fats: Double
    let carbs: Double
    let ingredients: [DishIngredientDTO]
    let portionSize: Double
    let category: DishCategory
    let flags: Set<FeatureFlag>
    let createdAt: String
    let updatedAt: String?
}

struct DishUpsertDTO: Codable {
    let name: String?
    let photos: [String]?
    let calories: Double?
    let proteins: Double?
    let fats: Double?
    let carbs: Double?
    let ingredients: [DishIngredientRequestDTO]?
    let portionSize: Double?
    let category: DishCategory?
    let flags: Set<FeatureFlag>?
}

extension ProductDTO {
    func toDomain() -> Product {
        Product(
            id: id,
            name: name,
            photos: photos,
            calories: calories,
            proteins: proteins,
            fats: fats,
            carbs: carbs,
            composition: composition,
            category: category,
            preparation: preparation,
            flags: flags,
            createdAt: DateParsing.parse(createdAt),
            updatedAt: updatedAt.map(DateParsing.parse)
        )
    }
}

extension DishDTO {
    func toDomain() -> Dish {
        Dish(
            id: id,
            name: name,
            photos: photos,
            calories: calories,
            proteins: proteins,
            fats: fats,
            carbs: carbs,
            ingredients: ingredients.map {
                DishIngredient(productId: $0.productId, productName: $0.productName, quantity: $0.quantity)
            },
            portionSize: portionSize,
            category: category,
            flags: flags,
            createdAt: DateParsing.parse(createdAt),
            updatedAt: updatedAt.map(DateParsing.parse)
        )
    }
}

extension ProductUpsertPayload {
    func toDTO() -> ProductUpsertDTO {
        ProductUpsertDTO(
            name: name,
            photos: photos,
            calories: calories,
            proteins: proteins,
            fats: fats,
            carbs: carbs,
            composition: composition,
            category: category,
            preparation: preparation,
            flags: flags
        )
    }
}

extension DishUpsertPayload {
    func toDTO() -> DishUpsertDTO {
        DishUpsertDTO(
            name: name,
            photos: photos,
            calories: calories,
            proteins: proteins,
            fats: fats,
            carbs: carbs,
            ingredients: ingredients?.map { DishIngredientRequestDTO(productId: $0.productId, quantity: $0.quantity) },
            portionSize: portionSize,
            category: category,
            flags: flags
        )
    }
}
