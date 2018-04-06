import XCTest
import RxTest
import RxSwift
import CoreBluetooth
@testable
import RxBluetoothKit

class CentralManagerTest_StateRestore: BaseCentralManagerTest {
    
    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let subscribeTime = TestScheduler.Defaults.subscribed
    
    func testRestoreStateCallbackCalling() {
        setUpProperties()
        var calledCount: Int = 0
        var restoredState: _RestoredState?
        manager = _CentralManager(
            centralManager: centralManagerMock,
            delegateWrapper: wrapperMock,
            peripheralProvider: providerMock,
            connector: connectorMock) { state in
                calledCount += 1
                restoredState = state
        }
        
        let dict = ["key": "value"]
        wrapperMock.willRestoreState.asObserver().onNext(dict)
        
        XCTAssertEqual(calledCount, 1, "should called provided clousure")
        XCTAssertNotNil(restoredState, "should return restored state")
        XCTAssertEqual(restoredState!.restoredStateData as! [String: String], dict, "restore state should have proper restored state data")
    }
}
