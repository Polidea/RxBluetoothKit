import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

protocol CharacteristicsViewModelType {

    var characteristicsOutput: Observable<[Characteristic]> { get }

}
