#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint zikzak_share_handler.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
    s.name             = 'zikzak_share_handler_macos'
    s.version          = '0.0.1'
    s.summary          = 'macos implementation of the zikzak_share_handler plugin.'
    s.description      = <<-DESC
    macos implementation of the zikzak_share_handler plugin.
                         DESC
    s.homepage         = 'https://zikzak.wtf'
    s.license          = { :file => '../LICENSE' }
    s.author           = { 'ZikZak AI' => 'developer@zikzak.wtf' }
    s.source           = { :path => '.' }
    s.source_files = 'Classes/**/*'
    s.dependency 'FlutterMacOS'
  
    s.platform = :osx, '10.11'
    s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
    s.swift_version = '5.0'
  
  end
