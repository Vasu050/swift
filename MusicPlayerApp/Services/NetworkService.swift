import Foundation
import Combine

class NetworkService {
    private let session = URLSession.shared
    
    func fetch(url: String) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: url) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .mapError { NetworkError.networkError($0) }
            .eraseToAnyPublisher()
    }
    
    func fetch<T: Codable>(url: String, type: T.Type) -> AnyPublisher<T, Error> {
        return fetch(url: url)
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.invalidData
                }
            }
            .eraseToAnyPublisher()
    }
} 