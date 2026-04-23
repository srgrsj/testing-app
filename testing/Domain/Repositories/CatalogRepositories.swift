import Foundation

protocol ProductRepository {
    func list(filters: ProductListFilters) async throws -> [Product]
    func get(id: String) async throws -> Product
    func create(payload: ProductUpsertPayload) async throws -> Product
    func update(id: String, payload: ProductUpsertPayload) async throws -> Product
    func delete(id: String) async throws
}

protocol DishRepository {
    func list(filters: DishListFilters) async throws -> [Dish]
    func get(id: String) async throws -> Dish
    func create(payload: DishUpsertPayload) async throws -> Dish
    func update(id: String, payload: DishUpsertPayload) async throws -> Dish
    func delete(id: String) async throws
}

protocol ApiInfoRepository {
    func fetchApiInfo() async throws -> ApiInfo
}
