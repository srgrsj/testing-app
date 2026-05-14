import Foundation
import Combine

@MainActor
final class DishDetailViewModel: ObservableObject {
    @Published var dish: Dish?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let dishId: String
    private let useCases: CatalogUseCases

    init(dishId: String, useCases: CatalogUseCases) {
        self.dishId = dishId
        self.useCases = useCases
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            dish = try await useCases.dishes.get(dishId)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}
