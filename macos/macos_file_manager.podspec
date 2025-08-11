Pod::Spec.new do |s|
  s.name             = 'macos_file_manager'
  s.version          = '0.0.1'
  s.summary          = 'A macOS file manager with custom webview integration.'
  s.description      = <<-DESC
A macOS file manager application with custom webview integration for enhanced web content display.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.dependency 'WebKit'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end