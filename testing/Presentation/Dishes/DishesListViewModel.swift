import Foundation
import Combine

@MainActor
final class DishesListViewModel: ObservableObject {
    @Published var dishes: [Dish] = []
    @Published var filters = DishListFilters()
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
            dishes = try await useCases.dishes.list(query)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    func deleteDish(id: String) async {
        do {
            try await useCases.dishes.delete(id)
            await load()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
