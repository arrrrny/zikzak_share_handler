#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint zikzak_share_handler.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'zikzak_share_handler_ios'
  s.version          = '0.0.16'
  s.summary          = 'iOS implementation of the zikzak_share_handler plugin.'
  s.description      = <<-DESC
  iOS implementation of the zikzak_share_handler plugin.
                       DESC
  s.homepage         = 'https://zikzak.wtf'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ZikZak AI' => 'developer@zikzak.wtf' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'zikzak_share_handler_ios_models'
  s.subspec 'zikzak_share_handler_ios_models' do |ss|
    ss.source_files = './Models/Classes/**/*'
    ss.public_header_files = './Models/Classes/**/*.h'
  end
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
