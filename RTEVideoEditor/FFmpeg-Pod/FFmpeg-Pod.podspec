#
# Be sure to run `pod lib lint FFMpegRTVE.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FFmpeg-Pod'
  s.version          = '4.1.0'
  s.summary          = 'A short description of FFmpeg-Pod.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/vedon/FFmpeg-Pod'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'vedon' => 'fuweidong@bytedance.com' }
  s.source           = { :git => 'https://github.com/vedon/FFmpeg-Pod.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  # s.vendored_libraries = 'FFmpeg-Pod/Classes/FFmpeg-iOS/lib/*.a'
  # s.frameworks = 'CoreMedia', 'VideoToolbox', 'AVFoundation'
  # s.libraries = 'iconv', 'bz2', 'z'

  s.header_mappings_dir = 'FFmpeg-Pod/Classes/FFmpeg-iOS/include/'
  s.public_header_files = 'FFmpeg-Pod/Classes/FFmpeg-iOS/include/'
  s.static_framework = true  
  s.vendored_library = 'FFmpeg-Pod/Classes/FFmpeg-iOS/lib/*.a'
  s.frameworks = 'CoreMedia', 'VideoToolbox', 'AVFoundation'
  s.libraries = 'iconv', 'bz2', 'z','c++'
  # s.resource_bundles = {
  #   'FFmpeg-Pod' => ['FFmpeg-Pod/Assets/*.png']
  # }

  s.subspec 'libavcodec' do |sp|
    sp.source_files = 'FFmpeg-Pod/Classes/FFmpeg-iOS/include/libavcodec/*.h'
  end
  s.subspec 'libavdevice' do |sp|
    sp.source_files = 'FFmpeg-Pod/Classes/FFmpeg-iOS/include/libavdevice/*.h'
  end

  s.subspec 'libavfilter' do |sp|
    sp.source_files = 'FFmpeg-Pod/Classes/FFmpeg-iOS/include/libavfilter/*.h'
  end
  s.subspec 'libavformat' do |sp|
    sp.source_files = 'FFmpeg-Pod/Classes/FFmpeg-iOS/include/libavformat/*.h'
  end
  s.subspec 'libavutil' do |sp|
    sp.source_files = 'FFmpeg-Pod/Classes/FFmpeg-iOS/include/libavutil/*.h'
  end
  s.subspec 'libswresample' do |sp|
    sp.source_files = 'FFmpeg-Pod/Classes/FFmpeg-iOS/include/libswresample/*.h'
  end
  s.subspec 'libswscale' do |sp|
    sp.source_files = 'FFmpeg-Pod/Classes/FFmpeg-iOS/include/libswscale/*.h'
  end
  
  
  # s.dependency 'AFNetworking', '~> 2.3'
end
