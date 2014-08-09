Pod::Spec.new do |s|
  s.name         = 'cocos2d'
  s.license      = 'MIT'
  s.version      = '3.0.0'
  s.summary      = 'cocos2d for iPhone is a framework for building 2D games'
  s.description  = 'cocos2d for iPhone is a framework for building 2D games, demos, and other graphical/interactive applications for iPod Touch, iPhone, iPad and Mac. It is based on the cocos2d design but instead of using python it, uses Objective-C.'
  s.homepage     = 'http://www.cocos2d-iphone.org'
  s.author = {
    'Ricardo Quesada' => 'ricardoquesada@gmail.com'
  }
  s.dependencies = {
    'ObjectAL-for-iPhone' => []
  }
  s.source = {
    :git => 'https://github.com/RobotsAndPencils/cocos2d-iphone.git',
    :submodules => true
  }
	s.requires_arc = true
	s.platform     = :ios, '6.0'
  s.libraries = 'z'
  s.frameworks = 'OpenGLES'
  s.source_files = [
    'cocos2d/*.{h,m,c}',
		'cocos2d/Support/*.{h,m,c}',
		'cocos2d/Platforms/**/*.{h,m,c}',
		'cocos2d-ui/**/*.{h,m,c}'
  ]
	s.header_mappings_dir = 'cocos2d'
  s.subspec 'ObjectiveChipmunk' do |oc|
		oc.source_files = [
	    'external/Chipmunk/src/**/*.{c,h}',
			'external/Chipmunk/include/**/*.{c,h}',
      'external/Chipmunk/objectivec/**/*.{m,h}',
      'external/Chipmunk/objectivec/src/*.{m,h}'
	  ]
    oc.public_header_files = [
      'external/Chipmunk/include/**/*.h',
      'external/Chipmunk/objectivec/include/**/*.h',
      'external/Chipmunk/xcode/libGLEW/include/**/*.h',
      'external/Chipmunk/xcode/libglfw/include/**/*.h'
    ]
		oc.header_mappings_dir = 'external'
		oc.requires_arc = false
		oc.xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/Headers/cocos2d/Chipmunk/include/" "$(PODS_ROOT)/Headers/cocos2d/Chipmunk/objectivec/include/"' }
  end
	s.subspec 'kazmath' do |k|
  	k.source_files = 'external/kazmath/**/*.{c,h}'
  	k.public_header_files = 'external/kazmath/include/*.h'
  	k.header_mappings_dir = 'external/kazmath/include'
  end
end
