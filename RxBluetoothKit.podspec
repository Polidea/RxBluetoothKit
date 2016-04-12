Pod::Spec.new do |s|
  s.name             = "RxBluetoothKit"
  s.version          = "0.3.2"
  s.summary          = "Bluetooth library for RxSwift"

  s.description      = <<-DESC
  RxBluetoothKit is lightweight and easy to use Rx support for CoreBluetooth.
                       DESC

  s.homepage         = "https://github.com/polidea/RxBluetoothKit"
  s.license          = 'MIT'
  s.author           = { "Przemysław Lenart" => "przemek.lenart@polidea.com", "Kacper Harasim" => "kacper.harasim@polidea.com" }
  s.source           = { :git => "https://github.com/polidea/RxBluetoothKit.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/polidea'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/*.swift'
  s.frameworks   = 'CoreBluetooth'
  s.dependency 'RxSwift', '~> 2.0'
end
