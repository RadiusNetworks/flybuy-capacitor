Pod::Spec.new do |s|
  s.name = 'FlybuyCapacitor'
  s.version = '0.2.0'
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

  # Vendored from https://github.com/RadiusNetworks/flybuy-ios @ tag 2.13.3
  # (no CocoaPods podspec exists upstream)
  s.vendored_frameworks = 'ios/Frameworks/FlyBuy.xcframework',
                          'ios/Frameworks/FlyBuyPickup.xcframework',
                          'ios/Frameworks/FlyBuyNotify.xcframework',
                          'ios/Frameworks/FlyBuyLiveStatus.xcframework'
end