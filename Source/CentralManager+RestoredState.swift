import Foundation
import RxSwift

/// Closure that receives `RestoredState` as a parameter
public typealias OnWillRestoreState = (RestoredState) -> Void

extension CentralManager {

    convenience init(queue: DispatchQueue = .main,
                     options: [String: AnyObject]? = nil,
                     onWillRestoreState: OnWillRestoreState? = nil) {
        self.init(queue: queue, options: options)
        if let onWillRestoreState = onWillRestoreState {
            listenOnWillRestoreState(onWillRestoreState)
        }
    }

    /// Emits `RestoredState` instance, when state of `CentralManager` has been restored,
    /// Should only be called once in the lifetime of the app
    /// - returns: Observable which emits next events state has been restored
    func listenOnWillRestoreState(_ handler: @escaping OnWillRestoreState) {
        _ = delegateWrapper
            .willRestoreState
            .take(1)
            .flatMap { [weak self] dict -> Observable<RestoredState> in
                guard let strongSelf = self else { throw BluetoothError.destroyed }
                return .just(RestoredState(restoredStateDictionary: dict, centralManager: strongSelf))
            }
            .subscribe(onNext: { handler($0) })
    }
}
