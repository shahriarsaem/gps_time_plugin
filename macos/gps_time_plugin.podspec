#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint gps_time_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'gps_time_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for accurate GPS-synced time on macOS.'
  s.description      = <<-DESC
    Provides trusted time extracted from GPS location fixes on macOS,
    helping avoid reliance on potentially manipulated or drifted device clocks.
  DESC
  s.homepage         = 'https://github.com/shahriarsaem/gps-time-native'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Shahriar Saem' => 'saemshahriar@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }
  s.swift_version = '5.0'
end
