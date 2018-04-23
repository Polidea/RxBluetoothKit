import Foundation

enum Result<T, E> {
    case success(T)
    case error(E)
}
