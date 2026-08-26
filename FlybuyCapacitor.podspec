Pod::Spec.new do |s|
  s.name = 'FlybuyCapacitor'
  s.version = '0.1.5'
  s.summary = 'Capacitor plugin wrapping the Flybuy SDK by Radius Networks'
  s.license = 'MIT'
  s.homepage = 'https://github.com/RadiusNetworks/flybuy-capacitor'
  s.author = 'Radius Networks'
  s.source = { :git => 'https://github.com/RadiusNetworks/flybuy-capacitor.git', :tag => "v#{s.version}" }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.exclude_files = 'ios/Plugin/**/*.example.swift'
  s.ios.deployment_target = '13.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.9'

  # Flybuy SDK is distributed by Radius Networks via Swift Package Manager only —
  # there is no published CocoaPods spec for FlyBuyPickup/FlyBuyNotify/FlyBuyPresence
  # (confirmed: no .podspec in https://github.com/RadiusNetworks/flybuy-ios, and
  # `pod spec lint` fails with "Unable to find a specification" when these are
  # declared). Add the SPM package directly in Xcode instead:
  #   https://github.com/RadiusNetworks/flybuy-ios
  # and select the modules your app needs (FlyBuyPickup, FlyBuyNotify, etc.)
  # — this works fine alongside a CocoaPods-managed host app; Xcode supports both
  # dependency managers in the same project.
end