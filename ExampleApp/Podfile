source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

def shared_pods
  pod 'RxSwift', '~> 4.0'
  pod 'RxCocoa', '~> 4.0'
end

def rx_bluetooth_kit
  pod 'RxBluetoothKit', '~> 5.0'
end

target 'ExampleApp' do
  shared_pods
  rx_bluetooth_kit
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
    # Configure Pod targets for Xcode 8 compatibility
      config.build_settings['SWIFT_VERSION'] = '4.0'
    end
  end
end