Pod::Spec.new do |s|
  s.name             = 'zikzak_share_handler_macos_models'
  s.version          = '0.0.31'
  s.summary          = 'Shared code for zikzak_share_handler_macos plugin.'
  s.description      = <<-DESC
  Shared code for zikzak_share_handler_macos plugin so main app and share extension targets can use it.
                       DESC
  s.homepage         = 'https://zikzak.wtf'
  s.author           = { 'ZikZak AI' => 'developer@zikzak.wtf' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
