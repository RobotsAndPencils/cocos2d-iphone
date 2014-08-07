{
	"name": "cocos2d",
	"license": "MIT",
	"version": "3.1.0-alpha",
	"summary": "cocos2d for iPhone is a framework for building 2D games",
	"description": "cocos2d for iPhone is a framework for building 2D games, demos, and other graphical/interactive applications for iPod Touch, iPhone, iPad and Mac. It is based on the cocos2d design but instead of using python it, uses Objective-C.",
	"homepage": "http://www.cocos2d-iphone.org",
	"authors": {
		"Ricardo Quesada": "ricardoquesada@gmail.com",
		"Zynga Inc.": "https://zynga.com/"
	},
	"dependencies": {
		"ObjectAL-for-iPhone": [

		]
	},
	"source": {
		"git": "https://github.com/RobotsAndPencils/cocos2d-iphone.git",
		"tag": "rnp_v3.0",
		"submodules": true
	},
	"requires_arc": true,
	"platforms": {
		"osx": "10.8",
		"ios": "5.1.1"
	},
	"libraries": "z",
	"osx": {
		"frameworks": "OpenGL"
	},
	"ios": {
		"frameworks": "OpenGLES"
	},
	"source_files": [
		"cocos2d/*.{h,m,c}",
		"cocos2d/Support/*.{h,m,c}",
		"cocos2d/Platforms/**/*.{h,m,c}",
		"cocos2d-ui/**/*.{h,m,c}"
	],
	"header_mappings_dir": "cocos2d",
	"subspecs": [
		{
			"name": "ObjectiveChipmunk",
			"requires_arc": false,
			"source_files": [
				"external/Chipmunk/src/**/*.{c,h}",
				"external/Chipmunk/include/**/*.{c,h}",
				"external/Chipmunk/objectivec/**/*.{m,h}",
				"external/Chipmunk/objectivec/src/*.{m,h}"
			],
			"public_header_files": [
				"external/Chipmunk/include/**/*.h",
				"external/Chipmunk/objectivec/include/**/*.h",
				"external/Chipmunk/xcode/libGLEW/include/**/*.h",
				"external/Chipmunk/xcode/libglfw/include/**/*.h"
			],
			"header_mappings_dir": "external",
			"xcconfig": {
				"HEADER_SEARCH_PATHS": "\"$(PODS_ROOT)/Headers/cocos2d/Chipmunk/include/\" \"$(PODS_ROOT)/Headers/cocos2d/Chipmunk/objectivec/include/\""
			}
		}
	]
}