#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint zikzak_share_handler_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'zikzak_share_handler_ios_models'
  s.version          = '0.0.9'
  s.summary          = 'Shared code for zikzak_share_handler_ios plugin.'
  s.description      = <<-DESC
  Shared code for zikzak_share_handler_ios plugin so main app and share extension targets can use it.
                       DESC
  s.homepage         = 'https://zikzak.wtf'
  # s.license          = { :file => '../LICENSE' }
  s.author           = { 'ZikZak AI' => 'developer@zikzak.wtf' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
