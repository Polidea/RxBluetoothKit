import Foundation

enum Result<T, E> {
    case success(T)
    case error(E)
}

extension Result {
    func mapSucces<R>(_ conversion: (T) -> R) -> Result<R, E> {
        switch self {
        case let .success(value):
            return .success(conversion(value))
        case let .error(error):
            return .error(error)
        }
    }

    func mapError<D>(_ conversion: (E) -> D) -> Result<T, D> {
        switch self {
        case let .success(value):
            return .success(value)
        case let .error(error):
            return .error(conversion(error))
        }
    }

    func mapBoth<R, D>(_ left: (T) -> R, right: (E) -> D) -> Result<R, D> {
        switch self {
        case let .success(value):
            return .success(left(value))
        case let .error(error):
            return .error(right(error))
        }
    }
}
