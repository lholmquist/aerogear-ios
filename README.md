# aerogear-ios [![Build Status](https://travis-ci.org/aerogear/aerogear-ios.png)](https://travis-ci.org/aerogear/aerogear-ios)

iOS/Objective-C client library implementation for AeroGear!

The AeroGear iOS client lib is based on the [AFNetworking](https://github.com/AFNetworking/AFNetworking/) library.

The project requires [CocoaPods](http://cocoapods.org/) for dependency management;

## API docs

The API is documented [here](http://aerogear.org/docs/specs/aerogear-ios/). 

## iOS Cookbook

Some basic usages are documented [here](http://aerogear.org/docs/guides/iOSCookbook/).

## Getting started

Open the _AeroGear-iOS.xcworkspace_ in Xcode, if you want to get the project...

## Tutorial

We also have a little page for [getting started](http://aerogear.org/docs/guides/GetStartedwithAeroGearandXcode/) with Xcode and the library!

### Note on running Unit Tests
There is an issue when running unit tests on the iOS 6 simulator and in particular when you switch live from another iOS version (e.g. iOS 7). It turns out that the keychain access is broken, resulting in test failures whenever a method tries to access the keychain. A workaround for this is to File->Exit the emulator and re-run the tests on iOS 6. We are continue investigating the cause of this issue (see discussion on [Apple forum](https://devforums.apple.com/message/919209) for more information)

### Code coverage

To get the code covered by tests, follow these steps:
1. Run the tests like so:
`xctool -workspace AeroGear-iOS.xcworkspace -sdk iphonesimulator -scheme AeroGear-iOS -configuration CodeCoverage clean test`
2. Verify that the command generated `.gcno` and `.gcda` files in `~/Library/Developer/Xcode/DerivedData/AeroGear-iOS-{generated sequence}/Build/Intermediates/AeroGear-iOS.build/CodeCoverage-iphonesimulator/AeroGear-iOS.build/Objects-normal/i386`
3. Open those `.gcda` and `.gcno` files in [CoverStory](https://code.google.com/p/coverstory/)