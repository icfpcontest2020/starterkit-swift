import Foundation

struct Server {
    let playerKey: String
    let url: URL

    private let session: URLSession

    static func make(arguments: [String]) throws -> Self {
        guard arguments.count > 2 else {
            throw ConfigError.invalidArguments(arguments)
        }
        guard let serverUrl = URL(string: arguments[1]) else {
            throw ConfigError.invalidServerUrl(arguments[1])
        }

        return Self(playerKey: arguments[2], url: serverUrl, session: .shared)
    }

    func performPost() -> Result<String, ResponseError> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = self.playerKey.data(using: .utf8)
        
        var result: Result<String, ResponseError>?
        let waiter = DispatchSemaphore(value: 0)
        let task = self.session.dataTask(with: request) { (data, response, error) in
            defer { waiter.signal() }

            if let error = error {
                result = .failure(.error(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                result = .failure(.nonHTTP)
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                result = .failure(.statusCodeFailed(httpResponse.statusCode))
                return
            }
            guard let data = data, let body = String(data: data, encoding: .utf8) else {
                result = .failure(.cantExtractBody)
                return
            }

            result = .success(body)
        }
        task.resume()

        waiter.wait()
        return result!
    }

    // MARK: - ConfigurationError

    enum ConfigError: Error {
        case invalidArguments([String])
        case invalidServerUrl(String)
    }

    // MARK: - ResponseError

    enum ResponseError: Error {
        case error(Error)
        case nonHTTP
        case statusCodeFailed(Int)
        case cantExtractBody
    }
}