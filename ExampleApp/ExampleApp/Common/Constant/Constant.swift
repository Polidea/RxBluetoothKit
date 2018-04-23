import UIKit

struct Constant {

    struct Constraints {
        static let horizontalSmall: CGFloat = 8.0

        static let horizontalDefault: CGFloat = 16.0

        static let verticalSmall: CGFloat = 8.0

        static let verticalDefault: CGFloat = 16.0

        static let verticalMedium: CGFloat = 20.0

        static let navigationBarHeight: CGFloat = 64.0

        static let smallWidth: CGFloat = 32.0

        static let smallHeight: CGFloat = 32.0
    }

    struct ImageRepo {
        static let bluetooth: UIImage = UIImage(named: "bluetooth")!

        static let bluetoothService: UIImage = UIImage(named: "bluetooth-service")!
    }

    struct Strings {
        static let defaultDispatchQueueLabel = "com.polidea.rxbluetoothkit.timer"

        static let scanResultSectionTitle = "Scan Results"
        static let startScanning = "Start scanning"
        static let stopScanning = "Stop scanning"
        static let scanning = "Scanning..."
        static let servicesSectionTitle = "Discovered Services"
        static let characteristicsSectionTitle = "Discovered Characteristics"

        static let titleWrite = "Write"
        static let titleSuccess = "Success"
        static let titleRead = "Read"
        static let titleCancel = "Cancel"
        static let titleWriteValue = "Write value"
        static let titleOk = "OK"
        static let titleError = "Error"

        static let turnOffNotifications = "Turn OFF Notification"
        static let connect = "Connect"
        static let connected = "Connected"
        static let disconnect = "Disconnect"
        static let disconnected = "Disconnected"
        static let turnOnNotifications = "Turn ON Notification"
        static let hexValue = "Specify value in HEX to write"
        static let titleChooseAction = "Choose action"
        static let successfulWroteTo = "Successfully wrote value to:"
    }
}
