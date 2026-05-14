import Foundation
import Combine
import SwiftUI

@MainActor
final class ProductEditorViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var photos: [String] = []
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
    @Published var showingPhotoURLInput = false
    @Published var photoURLInput: String = ""

    private let editingProduct: Product?
    private let useCases: CatalogUseCases

    init(editingProduct: Product?, useCases: CatalogUseCases) {
        self.editingProduct = editingProduct
        self.useCases = useCases

        if let editingProduct {
            name = editingProduct.name
            photos = editingProduct.photos
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

    func addPhotoFromURL(_ url: String) {
        addPhotoString(url)
        photoURLInput = ""
        showingPhotoURLInput = false
    }

    func addPhotoDataURL(_ dataURL: String) {
        addPhotoString(dataURL)
    }

    private func addPhotoString(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !photos.contains(trimmed) {
            photos.append(trimmed)
        }
    }

    func removePhoto(at index: Int) {
        guard index >= 0 && index < photos.count else { return }
        photos.remove(at: index)
    }

    func save() async -> Bool {
        errorMessage = nil
        isLoading = true

        let payload = ProductUpsertPayload(
            name: name,
            photos: photos,
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
