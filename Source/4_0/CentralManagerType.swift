import Foundation
import CoreBluetooth
import RxSwift

protocol CentralManagerType: ManagerType {

    associatedtype P

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String:Any]?)

    func connect(_ peripheral: P, options: [String:Any]?)

    func cancelPeripheralConnection(_ peripheral: P)

    func stopScan()

    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> Observable<[P]>

    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> Observable<[P]>
}
