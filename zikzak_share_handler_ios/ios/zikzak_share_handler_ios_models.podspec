#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'zikzak_share_handler_ios_models'
  s.version          = '0.0.34'
  s.summary          = 'Shared models for the zikzak_share_handler iOS share extension.'
  s.description      = <<-DESC
  Shared models for the zikzak_share_handler iOS share extension.
                       DESC
  s.homepage         = 'https://zuzu.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ZikZak AI' => 'developer@zuzu.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'zikzak_share_handler_ios/Sources/zikzak_share_handler_ios_models/**/*.swift'
  s.platform = :ios, '9.0'
  s.swift_version = '5.0'
end
