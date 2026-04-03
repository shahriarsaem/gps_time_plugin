#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint gps_time_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'gps_time_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for accurate GPS-synced time on Android and iOS.'
  s.description      = <<-DESC
    Provides trusted time extracted from GPS location fixes, helping avoid reliance
    on potentially manipulated or drifted device clocks.
  DESC
  s.homepage         = 'https://github.com/shahriarsaem/gps_time_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Shahriar Saem' => 'shahriarsaem@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'

  # Privacy manifest for location API usage (required since Xcode 15 / iOS 17)
  s.resource_bundles = { 'gps_time_plugin_privacy' => ['Resources/PrivacyInfo.xcprivacy'] }
end
