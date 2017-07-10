Pod::Spec.new do |s|
  s.name     = 'SCDragController'
  s.version  = '1.2.1'
  s.platform = :ios
  s.ios.deployment_target = '8.0'

  s.summary  = 'Generic component meant to aid the development of drag & drop behaviors.'
  s.homepage = 'https://github.com/stefanceriu/SCDragController'
  s.author   = { 'Stefan Ceriu' => 'stefan.ceriu@yahoo.com' }
  s.social_media_url = 'https://twitter.com/stefanceriu'
  s.source   = { :git => 'https://github.com/stefanceriu/SCDragController.git', :tag => "v#{s.version}" }
  s.license      = { :type => 'MIT License', :file => 'LICENSE' }
  s.source_files = 'SCDragController/*'
  s.requires_arc = true
  s.frameworks = 'UIKit'
  s.screenshots = ["https://dl.dropboxusercontent.com/u/12748201/Recordings/SCDragController/SCDragController.gif"]
end