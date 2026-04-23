import Foundation

enum AppError: LocalizedError, Equatable {
    case badURL
    case transport(String)
    case decoding(String)
    case backend(message: String)
    case productInUse(message: String, dishes: [RelatedDish])
    case unknownStatus(Int)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Неверный URL API"
        case let .transport(message):
            return message
        case let .decoding(message):
            return "Ошибка разбора ответа: \(message)"
        case let .backend(message):
            return message
        case let .productInUse(message, dishes):
            let dishNames = dishes.map(\.name).joined(separator: ", ")
            if dishNames.isEmpty {
                return message
            }
            return "\(message)\nИспользуется в: \(dishNames)"
        case let .unknownStatus(code):
            return "Неожиданный статус ответа: \(code)"
        }
    }
}

struct RelatedDish: Equatable {
    let id: String
    let name: String
}
