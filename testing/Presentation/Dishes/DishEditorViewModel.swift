import Foundation
import Combine

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
    @Published var photosText: String = ""
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

    private let editingDish: Dish?
    private let useCases: CatalogUseCases
    private var cancellables: Set<AnyCancellable> = []
    private var isApplyingAutoNutrition = false
    private var editedNutritionFields: Set<NutritionField> = []

    init(editingDish: Dish?, useCases: CatalogUseCases) {
        self.editingDish = editingDish
        self.useCases = useCases

        if let editingDish {
            name = editingDish.name
            photosText = editingDish.photos.joined(separator: "\n")
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
        }

        setupAutoNutritionDrafting()
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
            photos: photosText
                .split(separator: "\n")
                .map(String.init)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty },
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

    private func recalculateAvailableFlags() {
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
}
