import Foundation
import Combine

@MainActor
final class AppContainer: ObservableObject {
    let useCases: CatalogUseCases

    init() {
        let baseURL = URL(string: ProcessInfo.processInfo.environment["CATALOG_API_BASE_URL"] ?? "http://127.0.0.1:8080")!
        let client = APIClient(baseURL: baseURL)
        let productRepository = ProductRepositoryImpl(client: client)
        let dishRepository = DishRepositoryImpl(client: client)
        let apiInfoRepository = ApiInfoRepositoryImpl(client: client)

        self.useCases = CatalogUseCases.live(
            productRepository: productRepository,
            dishRepository: dishRepository,
            apiInfoRepository: apiInfoRepository
        )
    }
}
