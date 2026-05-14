import Foundation

enum ProductCategory: String, CaseIterable, Codable, Identifiable {
    case frozen = "Замороженный"
    case meat = "Мясной"
    case vegetables = "Овощи"
    case greens = "Зелень"
    case spices = "Специи"
    case grains = "Крупы"
    case canned = "Консервы"
    case liquid = "Жидкость"
    case sweets = "Сладости"

    var id: String { rawValue }
    var title: String { rawValue }
}

enum PreparationStatus: String, CaseIterable, Codable, Identifiable {
    case readyToEat = "Готовый к употреблению"
    case semiFinished = "Полуфабрикат"
    case needsCooking = "Требует приготовления"

    var id: String { rawValue }
    var title: String { rawValue }
}

enum DishCategory: String, CaseIterable, Codable, Identifiable {
    case dessert = "Десерт"
    case first = "Первое"
    case second = "Второе"
    case drink = "Напиток"
    case salad = "Салат"
    case soup = "Суп"
    case snack = "Перекус"

    var id: String { rawValue }
    var title: String { rawValue }
}

enum FeatureFlag: String, CaseIterable, Codable, Identifiable {
    case vegan = "Веган"
    case glutenFree = "Без глютена"
    case sugarFree = "Без сахара"

    var id: String { rawValue }
    var title: String { rawValue }
}

enum ProductSortField: String, CaseIterable, Codable, Identifiable {
    case name = "NAME"
    case calories = "CALORIES"
    case proteins = "PROTEINS"
    case fats = "FATS"
    case carbs = "CARBS"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name: return "Название"
        case .calories: return "Калории"
        case .proteins: return "Белки"
        case .fats: return "Жиры"
        case .carbs: return "Углеводы"
        }
    }
}

enum SortOrder: String, CaseIterable, Codable, Identifiable {
    case asc = "ASC"
    case desc = "DESC"

    var id: String { rawValue }
    var title: String { self == .asc ? "По возрастанию" : "По убыванию" }
}
