Pod::Spec.new do |s|
  s.name             = 'pangolin_content_sdk'
  s.version          = '1.0.1'
  s.summary          = 'Flutter wrapper for Pangolin Content SDK drama APIs.'
  s.description      = <<-DESC
Flutter wrapper for Pangolin Content SDK drama APIs on Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/owxo/PangolinContentSDK'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'pangolin_content_sdk contributors' => 'owxo@users.noreply.github.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'Ads-CN-Beta/BUAdSDK', '7.2.0.6'
  s.dependency 'Ads-CN-Beta/CSJMediation-Only', '7.2.0.6'
  s.dependency 'Ads-CN-Beta/BUAdLive', '7.2.0.6'
  s.dependency 'TTSDKFramework/LivePull', '1.46.2.7-premium'
  s.dependency 'TTSDKFramework/Player-SR', '1.46.2.7-premium'
  s.dependency 'PangrowthX/shortplay-beta', '2.9.0.5'
  s.platform = :ios, '12.0'
  s.static_framework = true
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'ENABLE_MODULE_VERIFIER' => 'NO',
    'CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER' => 'NO'
  }
end
