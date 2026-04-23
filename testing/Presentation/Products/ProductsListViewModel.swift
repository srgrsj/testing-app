import Foundation
import Combine

@MainActor
final class ProductsListViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var filters = ProductListFilters()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    let useCases: CatalogUseCases

    init(useCases: CatalogUseCases) {
        self.useCases = useCases
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        var query = filters
        query.search = searchText.isEmpty ? nil : searchText

        do {
            products = try await useCases.products.list(query)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    func deleteProduct(id: String) async {
        do {
            try await useCases.products.delete(id)
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
