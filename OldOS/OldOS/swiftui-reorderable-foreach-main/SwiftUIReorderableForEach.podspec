Pod::Spec.new do |s|
  s.name             = 'SwiftUIReorderableForEach'
  s.version          = '1.0.0'
  s.summary          = 'Drag & drop to reorder items in SwiftUI.'
  s.homepage         = 'https://github.com/globulus/swiftui-reorderable-foreach'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Gordan Glavaš' => 'gordan.glavas@gmail.com' }
  s.source           = { :git => 'https://github.com/globulus/swiftui-reorderable-foreach.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/SwiftUIReorderableForEach/**/*'
end
