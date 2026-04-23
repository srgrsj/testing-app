import Foundation

struct ProductUseCases {
    let list: (ProductListFilters) async throws -> [Product]
    let get: (String) async throws -> Product
    let create: (ProductUpsertPayload) async throws -> Product
    let update: (String, ProductUpsertPayload) async throws -> Product
    let delete: (String) async throws -> Void
}

struct DishUseCases {
    let list: (DishListFilters) async throws -> [Dish]
    let get: (String) async throws -> Dish
    let create: (DishUpsertPayload) async throws -> Dish
    let update: (String, DishUpsertPayload) async throws -> Dish
    let delete: (String) async throws -> Void
}

struct ApiInfoUseCase {
    let fetch: () async throws -> ApiInfo
}

struct CatalogUseCases {
    let products: ProductUseCases
    let dishes: DishUseCases
    let apiInfo: ApiInfoUseCase
}

extension CatalogUseCases {
    static func live(
        productRepository: ProductRepository,
        dishRepository: DishRepository,
        apiInfoRepository: ApiInfoRepository
    ) -> CatalogUseCases {
        CatalogUseCases(
            products: ProductUseCases(
                list: { try await productRepository.list(filters: $0) },
                get: { try await productRepository.get(id: $0) },
                create: { try await productRepository.create(payload: $0) },
                update: { try await productRepository.update(id: $0, payload: $1) },
                delete: { try await productRepository.delete(id: $0) }
            ),
            dishes: DishUseCases(
                list: { try await dishRepository.list(filters: $0) },
                get: { try await dishRepository.get(id: $0) },
                create: { try await dishRepository.create(payload: $0) },
                update: { try await dishRepository.update(id: $0, payload: $1) },
                delete: { try await dishRepository.delete(id: $0) }
            ),
            apiInfo: ApiInfoUseCase(
                fetch: { try await apiInfoRepository.fetchApiInfo() }
            )
        )
    }
}
