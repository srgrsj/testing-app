import Foundation
import Combine
import SwiftUI

@MainActor
final class DishEditorViewModel: ObservableObject {
    enum NutritionField {
        case calories
        case proteins
        case fats
        case carbs
    }

    struct IngredientDraft: Identifiable, Equatable {
        let id = UUID()
        var productId: String
        var quantity: Double
    }

    @Published var name: String = ""
    @Published var photos: [String] = []
    @Published var caloriesText: String = ""
    @Published var proteinsText: String = ""
    @Published var fatsText: String = ""
    @Published var carbsText: String = ""
    @Published var portionSizeText: String = "100"
    @Published var category: DishCategory = .second
    @Published var selectedFlags: Set<FeatureFlag> = []
    @Published private(set) var availableFlags: Set<FeatureFlag> = []
    @Published var ingredients: [IngredientDraft] = []
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingPhotoURLInput = false
    @Published var photoURLInput: String = ""

    private let editingDish: Dish?
    private let useCases: CatalogUseCases
    private var cancellables: Set<AnyCancellable> = []
    private var isApplyingAutoNutrition = false
    private var editedNutritionFields: Set<NutritionField> = []
    private var categorySetManually = false
    private var isProcessingMacro = false

    init(editingDish: Dish?, useCases: CatalogUseCases) {
        self.editingDish = editingDish
        self.useCases = useCases

        if let editingDish {
            name = editingDish.name
            photos = editingDish.photos
            caloriesText = String(format: "%.1f", editingDish.calories)
            proteinsText = String(format: "%.1f", editingDish.proteins)
            fatsText = String(format: "%.1f", editingDish.fats)
            carbsText = String(format: "%.1f", editingDish.carbs)
            portionSizeText = String(format: "%.1f", editingDish.portionSize)
            category = editingDish.category
            selectedFlags = editingDish.flags
            ingredients = editingDish.ingredients.map {
                IngredientDraft(productId: $0.productId, quantity: $0.quantity)
            }
            categorySetManually = true
        }

        setupAutoNutritionDrafting()
        setupNameMacroExtraction()
    }

    var title: String {
        editingDish == nil ? "Новое блюдо" : "Редактировать блюдо"
    }

    func loadProducts() async {
        do {
            products = try await useCases.products.list(ProductListFilters())
            if ingredients.isEmpty, let firstProduct = products.first {
                ingredients = [IngredientDraft(productId: firstProduct.id, quantity: 100)]
            }
            syncDerivedStateForCompositionChange()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func addIngredient() {
        guard let product = products.first else { return }
        ingredients.append(IngredientDraft(productId: product.id, quantity: 100))
        syncDerivedStateForCompositionChange()
    }

    func syncDerivedStateForCompositionChange() {
        recalculateAvailableFlags()
        recalculateNutritionDraft()
    }

    func markNutritionFieldEdited(_ field: NutritionField) {
        guard !isApplyingAutoNutrition else { return }
        editedNutritionFields.insert(field)
    }

    func recalculateNutritionDraft(forceOverride: Bool = false) {
        if forceOverride {
            editedNutritionFields.removeAll()
        }

        guard let draft = calculateDraftNutrition() else { return }

        isApplyingAutoNutrition = true
        defer { isApplyingAutoNutrition = false }

        if forceOverride || !editedNutritionFields.contains(.calories) {
            caloriesText = formatNutrition(draft.calories)
        }
        if forceOverride || !editedNutritionFields.contains(.proteins) {
            proteinsText = formatNutrition(draft.proteins)
        }
        if forceOverride || !editedNutritionFields.contains(.fats) {
            fatsText = formatNutrition(draft.fats)
        }
        if forceOverride || !editedNutritionFields.contains(.carbs) {
            carbsText = formatNutrition(draft.carbs)
        }
    }

    func removeIngredient(id: UUID) {
        ingredients.removeAll { $0.id == id }
        syncDerivedStateForCompositionChange()
    }

    func toggleFlag(_ flag: FeatureFlag) {
        guard availableFlags.contains(flag) else { return }
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

    func updateCategoryManually(_ newCategory: DishCategory) {
        category = newCategory
        categorySetManually = true
    }

    var categoryBinding: Binding<DishCategory> {
        Binding(
            get: { self.category },
            set: { newValue in
                self.category = newValue
                self.categorySetManually = true
            }
        )
    }

    func save() async -> Bool {
        errorMessage = nil
        isLoading = true

        if ingredients.isEmpty {
            errorMessage = "Добавьте хотя бы один ингредиент"
            isLoading = false
            return false
        }

        if ingredients.contains(where: { $0.quantity <= 0 || !$0.quantity.isFinite }) {
            errorMessage = "Количество каждого ингредиента должно быть больше 0"
            isLoading = false
            return false
        }

        let preparedIngredients = ingredients
            .filter { !$0.productId.isEmpty }
            .map { DishIngredientInput(productId: $0.productId, quantity: $0.quantity) }

        let payload = DishUpsertPayload(
            name: name,
            photos: photos,
            calories: Double(caloriesText.replacingOccurrences(of: ",", with: ".")),
            proteins: Double(proteinsText.replacingOccurrences(of: ",", with: ".")),
            fats: Double(fatsText.replacingOccurrences(of: ",", with: ".")),
            carbs: Double(carbsText.replacingOccurrences(of: ",", with: ".")),
            ingredients: preparedIngredients,
            portionSize: Double(portionSizeText.replacingOccurrences(of: ",", with: ".")),
            category: category,
            flags: selectedFlags
        )

        do {
            if let editingDish {
                _ = try await useCases.dishes.update(editingDish.id, payload)
            } else {
                _ = try await useCases.dishes.create(payload)
            }
            isLoading = false
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isLoading = false
            return false
        }
    }

    private struct NutritionDraft {
        let calories: Double
        let proteins: Double
        let fats: Double
        let carbs: Double
    }

    private func setupAutoNutritionDrafting() {
        Publishers.CombineLatest3($ingredients, $products, $portionSizeText)
            .sink { [weak self] _, _, _ in
                self?.recalculateNutritionDraft()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($ingredients, $products)
            .sink { [weak self] _, _ in
                self?.recalculateAvailableFlags()
            }
            .store(in: &cancellables)
    }

    private func setupNameMacroExtraction() {
        $name
            .sink { [weak self] _ in
                self?.processDishNameMacro()
            }
            .store(in: &cancellables)
    }

    private func recalculateAvailableFlags() {
        if products.isEmpty {
            // Preserve preloaded flags in edit mode until product catalog is available.
            availableFlags = selectedFlags
            return
        }

        let allowed = computeAvailableFlags()
        availableFlags = allowed
        selectedFlags = selectedFlags.intersection(allowed)
    }

    private func computeAvailableFlags() -> Set<FeatureFlag> {
        let productsById = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        let ingredientProducts = ingredients.compactMap { productsById[$0.productId] }

        guard !ingredientProducts.isEmpty else {
            return []
        }

        return Set(FeatureFlag.allCases.filter { flag in
            ingredientProducts.allSatisfy { $0.flags.contains(flag) }
        })
    }

    private func calculateDraftNutrition() -> NutritionDraft? {
        let productsById = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

        var totalCalories = 0.0
        var totalProteins = 0.0
        var totalFats = 0.0
        var totalCarbs = 0.0

        for ingredient in ingredients {
            guard ingredient.quantity > 0 else { continue }
            guard let product = productsById[ingredient.productId] else { continue }

            let factor = ingredient.quantity / 100.0
            totalCalories += product.calories * factor
            totalProteins += product.proteins * factor
            totalFats += product.fats * factor
            totalCarbs += product.carbs * factor
        }

        guard totalCalories > 0 || totalProteins > 0 || totalFats > 0 || totalCarbs > 0 else {
            return nil
        }

        return NutritionDraft(
            calories: totalCalories,
            proteins: totalProteins,
            fats: totalFats,
            carbs: totalCarbs
        )
    }

    private func formatNutrition(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func processDishNameMacro() {
        guard !isProcessingMacro else { return }
        
        let macroResult = extractDishMacro(from: name)
        
        // Только обновляем, если на самом деле что-то изменилось
        if macroResult.cleanedName != name {
            isProcessingMacro = true
            name = macroResult.cleanedName
            isProcessingMacro = false
        }
        
        if let extractedCategory = macroResult.category, !categorySetManually {
            category = extractedCategory
        }
    }

    private func extractDishMacro(from input: String) -> (cleanedName: String, category: DishCategory?) {
        let macroPattern = "!(десерт|первое|второе|напиток|салат|суп|перекус)"
        guard let regex = try? NSRegularExpression(pattern: macroPattern, options: .caseInsensitive) else {
            return (cleanedName: input, category: nil)
        }

        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        guard let match = regex.firstMatch(in: input, options: [], range: range) else {
            return (cleanedName: input, category: nil)
        }

        guard let matchRange = Range(match.range, in: input) else {
            return (cleanedName: input, category: nil)
        }

        let macroText = String(input[matchRange]).lowercased()
        let category: DishCategory? = {
            switch macroText {
            case "!десерт": return .dessert
            case "!первое": return .first
            case "!второе": return .second
            case "!напиток": return .drink
            case "!салат": return .salad
            case "!суп": return .soup
            case "!перекус": return .snack
            default: return nil
            }
        }()

        let beforeMacro = String(input[..<matchRange.lowerBound])
        let afterMacro = String(input[matchRange.upperBound...])
        let cleanedName = (beforeMacro + afterMacro)
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        return (cleanedName: cleanedName, category: category)
    }
}
