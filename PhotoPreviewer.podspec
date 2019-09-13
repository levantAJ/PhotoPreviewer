Pod::Spec.new do |s|
  s.name = 'PhotoPreviewer'
  s.version = '1.0'
  s.summary = 'Preview photos for iOS app'
  s.description = <<-DESC
  PhotoPreviewer written on Swift 5.0 by levantAJ
                       DESC
  s.homepage = 'https://github.com/levantAJ/PhotoPreviewer'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Tai Le' => 'sirlevantai@gmail.com' }
  s.source = { :git => 'https://github.com/levantAJ/PhotoPreviewer.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'
  s.source_files = 'PhotoPreviewer/**/*.{swift}'
  s.dependency 'SDWebImage'
end