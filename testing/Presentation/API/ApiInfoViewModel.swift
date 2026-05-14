import Foundation
import Combine

@MainActor
final class ApiInfoViewModel: ObservableObject {
    @Published var apiInfo: ApiInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let useCase: ApiInfoUseCase

    init(useCase: ApiInfoUseCase) {
        self.useCase = useCase
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            apiInfo = try await useCase.fetch()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}
