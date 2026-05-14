import Foundation

struct APIClient {
    private let baseURL: URL
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.withoutEscapingSlashes]
    }

    func request<Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil,
        responseType: Response.Type
    ) async throws -> Response {
        let request = try makeRequest(endpoint: endpoint, body: body)
        let (data, response) = try await perform(request)
        return try decode(data: data, response: response)
    }

    func requestWithoutResponse(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil
    ) async throws {
        let request = try makeRequest(endpoint: endpoint, body: body)
        let (_, response) = try await perform(request)
        _ = try validate(responseData: Data(), response: response)
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await urlSession.data(for: request)
        } catch {
            throw AppError.transport(error.localizedDescription)
        }
    }

    private func makeRequest(endpoint: APIEndpoint, body: Encodable?) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw AppError.badURL
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let url = components.url else {
            throw AppError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encodeEncodable(body)
        }

        return request
    }

    private func decode<Response: Decodable>(data: Data, response: URLResponse) throws -> Response {
        let validData = try validate(responseData: data, response: response)
        do {
            return try decoder.decode(Response.self, from: validData)
        } catch {
            throw AppError.decoding(error.localizedDescription)
        }
    }

    private func validate(responseData: Data, response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.transport("Некорректный HTTP-ответ")
        }

        switch httpResponse.statusCode {
        case 200 ... 299:
            return responseData
        case 400, 404:
            let backendError = (try? decoder.decode(ErrorDTO.self, from: responseData))?.message ?? "Ошибка запроса"
            throw AppError.backend(message: backendError)
        case 409:
            if let conflict = try? decoder.decode(ProductDeleteConflictDTO.self, from: responseData) {
                throw AppError.productInUse(
                    message: conflict.message,
                    dishes: conflict.dishes.map { RelatedDish(id: $0.id, name: $0.name) }
                )
            }
            throw AppError.backend(message: "Конфликт данных")
        default:
            throw AppError.unknownStatus(httpResponse.statusCode)
        }
    }

    private func encodeEncodable(_ value: Encodable) throws -> Data {
        let wrapped = AnyEncodable(value)
        do {
            return try encoder.encode(wrapped)
        } catch {
            throw AppError.transport("Не удалось сформировать тело запроса")
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encodeClosure = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
