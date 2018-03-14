import Foundation
import UIKit

protocol UpdatableCell {

    associatedtype ModelDataType

    func update(with item: ModelDataType)
}