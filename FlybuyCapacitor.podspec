Pod::Spec.new do |s|
  s.name = 'FlybuyCapacitor'
  s.version = '0.1.0'
  s.summary = 'Capacitor plugin wrapping the Flybuy SDK by Radius Networks'
  s.license = 'MIT'
  s.homepage = 'https://github.com/RadiusNetworks/flybuy-capacitor'
  s.author = 'Radius Networks'
  s.source = { :git => 'https://github.com/RadiusNetworks/flybuy-capacitor.git', :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target = '14.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.9'

  # Flybuy SDK via Swift Package Manager is preferred, but for CocoaPods:
  # s.dependency 'FlyBuyPickup'
  # s.dependency 'FlyBuyNotify'
  # s.dependency 'FlyBuyPresence'
  #
  # NOTE: Radius Networks recommends adding the Flybuy SDK via Swift Package Manager
  # in Xcode rather than CocoaPods. Add the following SPM package to your host app:
  #   https://github.com/RadiusNetworks/flybuy-ios
  # and select the modules your app needs (FlyBuyPickup, FlyBuyNotify, etc.)
end
