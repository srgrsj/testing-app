import Foundation
import Combine

@MainActor
final class ProductEditorViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var photosText: String = ""
    @Published var caloriesText: String = ""
    @Published var proteinsText: String = ""
    @Published var fatsText: String = ""
    @Published var carbsText: String = ""
    @Published var composition: String = ""
    @Published var category: ProductCategory = .meat
    @Published var preparation: PreparationStatus = .needsCooking
    @Published var selectedFlags: Set<FeatureFlag> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let editingProduct: Product?
    private let useCases: CatalogUseCases

    init(editingProduct: Product?, useCases: CatalogUseCases) {
        self.editingProduct = editingProduct
        self.useCases = useCases

        if let editingProduct {
            name = editingProduct.name
            photosText = editingProduct.photos.joined(separator: "\n")
            caloriesText = String(format: "%.1f", editingProduct.calories)
            proteinsText = String(format: "%.1f", editingProduct.proteins)
            fatsText = String(format: "%.1f", editingProduct.fats)
            carbsText = String(format: "%.1f", editingProduct.carbs)
            composition = editingProduct.composition ?? ""
            category = editingProduct.category
            preparation = editingProduct.preparation
            selectedFlags = editingProduct.flags
        }
    }

    var title: String {
        editingProduct == nil ? "Новый продукт" : "Редактировать продукт"
    }

    func toggleFlag(_ flag: FeatureFlag) {
        if selectedFlags.contains(flag) {
            selectedFlags.remove(flag)
        } else {
            selectedFlags.insert(flag)
        }
    }

    func save() async -> Bool {
        errorMessage = nil
        isLoading = true

        let payload = ProductUpsertPayload(
            name: name,
            photos: photosText
                .split(separator: "\n")
                .map(String.init)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty },
            calories: Double(caloriesText.replacingOccurrences(of: ",", with: ".")),
            proteins: Double(proteinsText.replacingOccurrences(of: ",", with: ".")),
            fats: Double(fatsText.replacingOccurrences(of: ",", with: ".")),
            carbs: Double(carbsText.replacingOccurrences(of: ",", with: ".")),
            composition: composition.isEmpty ? nil : composition,
            category: category,
            preparation: preparation,
            flags: selectedFlags
        )

        do {
            if let editingProduct {
                _ = try await useCases.products.update(editingProduct.id, payload)
            } else {
                _ = try await useCases.products.create(payload)
            }
            isLoading = false
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isLoading = false
            return false
        }
    }
}
