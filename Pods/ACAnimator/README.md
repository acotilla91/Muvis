
# ACAnimator

[![Version](https://img.shields.io/cocoapods/v/ACAnimator.svg?style=flat)](https://cocoapods.org/pods/ACAnimator)
[![License](https://img.shields.io/cocoapods/l/ACAnimator.svg?style=flat)](https://cocoapods.org/pods/ACAnimator)
[![Platform](https://img.shields.io/cocoapods/p/ACAnimator.svg?style=flat)](https://cocoapods.org/pods/ACAnimator)

ACAnimator lets you animate almost anything on iOS or tvOS (including non-animatable properties). Can also be used to "animate" logical changes not just visual (e.g. fade in/out audio). It supports over 30 different easing functions and it uses `CADisplayLink` for optimal performance.

## Example

![Demo](https://github.com/acotilla91/ACAnimator/blob/master/ACAnimator-demo.gif)

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Usage

``` swift
// A random element
let box = UIView(frame: CGRect(x: 0, y: 200, width: 40, height: 40))
box.backgroundColor = .red
view.addSubview(box)

// Determine the target value
let targetX = UIScreen.main.bounds.width - box.frame.width

// Prepare and run the animation
let animator = ACAnimator(duration: 3.0, easeFunction: .expoInOut, animation: { (fraction, _, _) in
    // Calculate the proper value for the current "frame"
    let newValue = targetX * CGFloat(fraction)
    
    // Apply the new value
    box.transform = CGAffineTransform(translationX: newValue, y: 0)
    
    // NOTE: the `transform` property is animatable through UIKit or CoreAnimation, this example just showcases the equivalent implementation using ACAnimator.
})
animator.start()
```

## Installation

### CocoaPods

ACAnimator is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ACAnimator'
```

### Manual

Just drag the *ACAnimator.swift* file into your project.

## Author

acotilla91, acotilla91@gmail.com

## License

ACAnimator is available under the MIT license. See the LICENSE file for more info.
