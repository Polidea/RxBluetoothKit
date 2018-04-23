import Foundation

protocol UpdatableCell {

    associatedtype ModelDataType

    func update(with item: ModelDataType)
}