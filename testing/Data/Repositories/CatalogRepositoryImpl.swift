import Foundation

struct ProductRepositoryImpl: ProductRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func list(filters: ProductListFilters) async throws -> [Product] {
        let response: [ProductDTO] = try await client.request(
            CatalogEndpoint.products(filters: filters),
            responseType: [ProductDTO].self
        )
        return response.map { $0.toDomain() }
    }

    func get(id: String) async throws -> Product {
        let response: ProductDTO = try await client.request(CatalogEndpoint.product(id: id), responseType: ProductDTO.self)
        return response.toDomain()
    }

    func create(payload: ProductUpsertPayload) async throws -> Product {
        let response: ProductDTO = try await client.request(
            CatalogEndpoint.createProduct(),
            body: payload.toDTO(),
            responseType: ProductDTO.self
        )
        return response.toDomain()
    }

    func update(id: String, payload: ProductUpsertPayload) async throws -> Product {
        let response: ProductDTO = try await client.request(
            CatalogEndpoint.updateProduct(id: id),
            body: payload.toDTO(),
            responseType: ProductDTO.self
        )
        return response.toDomain()
    }

    func delete(id: String) async throws {
        try await client.requestWithoutResponse(CatalogEndpoint.deleteProduct(id: id))
    }
}

struct DishRepositoryImpl: DishRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func list(filters: DishListFilters) async throws -> [Dish] {
        let response: [DishDTO] = try await client.request(CatalogEndpoint.dishes(filters: filters), responseType: [DishDTO].self)
        return response.map { $0.toDomain() }
    }

    func get(id: String) async throws -> Dish {
        let response: DishDTO = try await client.request(CatalogEndpoint.dish(id: id), responseType: DishDTO.self)
        return response.toDomain()
    }

    func create(payload: DishUpsertPayload) async throws -> Dish {
        let response: DishDTO = try await client.request(
            CatalogEndpoint.createDish(),
            body: payload.toDTO(),
            responseType: DishDTO.self
        )
        return response.toDomain()
    }

    func update(id: String, payload: DishUpsertPayload) async throws -> Dish {
        let response: DishDTO = try await client.request(
            CatalogEndpoint.updateDish(id: id),
            body: payload.toDTO(),
            responseType: DishDTO.self
        )
        return response.toDomain()
    }

    func delete(id: String) async throws {
        try await client.requestWithoutResponse(CatalogEndpoint.deleteDish(id: id))
    }
}

struct ApiInfoRepositoryImpl: ApiInfoRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchApiInfo() async throws -> ApiInfo {
        let response: ApiInfoDTO = try await client.request(CatalogEndpoint.apiInfo(), responseType: ApiInfoDTO.self)
        return ApiInfo(name: response.name, version: response.version)
    }
}
