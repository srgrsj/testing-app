import Foundation
import Combine

@MainActor
final class ProductDetailViewModel: ObservableObject {
    @Published var product: Product?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productId: String
    private let useCases: CatalogUseCases

    init(productId: String, useCases: CatalogUseCases) {
        self.productId = productId
        self.useCases = useCases
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            product = try await useCases.products.get(productId)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}
