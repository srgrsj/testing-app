import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem] = []
}

enum CatalogEndpoint {
    static func apiInfo() -> APIEndpoint {
        APIEndpoint(path: "/", method: .get)
    }

    static func products(filters: ProductListFilters) -> APIEndpoint {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "sortBy", value: filters.sortBy.rawValue),
            URLQueryItem(name: "order", value: filters.sortOrder.rawValue)
        ]

        if let category = filters.category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
        }
        if let preparation = filters.preparation {
            queryItems.append(URLQueryItem(name: "preparation", value: preparation.rawValue))
        }
        if !filters.flags.isEmpty {
            queryItems.append(URLQueryItem(name: "flags", value: filters.flags.map(\.rawValue).sorted().joined(separator: ",")))
        }
        if let search = filters.search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        return APIEndpoint(path: "/api/products", method: .get, queryItems: queryItems)
    }

    static func product(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/products/\(id)", method: .get)
    }

    static func createProduct() -> APIEndpoint {
        APIEndpoint(path: "/api/products", method: .post)
    }

    static func updateProduct(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/products/\(id)", method: .put)
    }

    static func deleteProduct(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/products/\(id)", method: .delete)
    }

    static func dishes(filters: DishListFilters) -> APIEndpoint {
        var queryItems: [URLQueryItem] = []

        if let category = filters.category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
        }
        if !filters.flags.isEmpty {
            queryItems.append(URLQueryItem(name: "flags", value: filters.flags.map(\.rawValue).sorted().joined(separator: ",")))
        }
        if let search = filters.search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        return APIEndpoint(path: "/api/dishes", method: .get, queryItems: queryItems)
    }

    static func dish(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/dishes/\(id)", method: .get)
    }

    static func createDish() -> APIEndpoint {
        APIEndpoint(path: "/api/dishes", method: .post)
    }

    static func updateDish(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/dishes/\(id)", method: .put)
    }

    static func deleteDish(id: String) -> APIEndpoint {
        APIEndpoint(path: "/api/dishes/\(id)", method: .delete)
    }
}
