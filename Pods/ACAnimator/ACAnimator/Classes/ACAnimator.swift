//
//  ACAnimator.swift
//  Created by Alejandro Cotilla on 2/21/19.
//

import UIKit

public typealias ACAnimatorAnimation = (_ fraction: Double, _ elapsed: Double, _ duration: Double) -> Void
public typealias ACAnimatorCompletion = (_ finished: Bool) -> Void

public struct ACAnimatorOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let `repeat` = ACAnimatorOptions(rawValue: 1 << 0) // repeat animation indefinitely
    public static let autoreverse = ACAnimatorOptions(rawValue: 1 << 1) // if repeat, run animation back and forth
}

public enum ACAnimatorEaseFunction {
    /// No easing, no acceleration
    case linear
    
    /// Slight acceleration from zero to full speed
    case sineIn
    
    /// Slight deceleration at the end
    case sineOut
    
    /// Slight acceleration at beginning and slight deceleration at end
    case sineInOut
    
    /// Accelerating from zero velocity
    case quadIn
    
    /// Decelerating to zero velocity
    case quadOut
    
    /// Acceleration until halfway, then deceleration
    case quadInOut
    
    /// Accelerating from zero velocity
    case cubicIn
    
    /// Decelerating to zero velocity
    case cubicOut
    
    /// Acceleration until halfway, then deceleration
    case cubicInOut
    
    /// Accelerating from zero velocity
    case quartIn
    
    /// Decelerating to zero velocity
    case quartOut
    
    /// Acceleration until halfway, then deceleration
    case quartInOut
    
    /// Accelerating from zero velocity
    case quintIn
    
    /// Decelerating to zero velocity
    case quintOut
    
    /// Acceleration until halfway, then deceleration
    case quintInOut
    
    /// Accelerate exponentially until finish
    case expoIn
    
    /// Initial exponential acceleration slowing to stop
    case expoOut
    
    /// Exponential acceleration and deceleration
    case expoInOut
    
    /// Increasing velocity until stop
    case circIn
    
    /// Start fast, decreasing velocity until stop
    case circOut
    
    /// Fast increase in velocity, fast decrease in velocity
    case circInOut
    
    /// Slow movement backwards then fast snap to finish
    case backIn(magnitude: Double?)
    
    /// Fast snap to backwards point then slow resolve to finish
    case backOut(magnitude: Double?)
    
    /// Slow movement backwards, fast snap to past finish, slow resolve to finish
    case backInOut(magnitude: Double?)
    
    /// Bounces slowly then quickly to finish
    case elasticIn(magnitude: Double?)
    
    /// Fast acceleration, bounces to zero
    case elasticOut(magnitude: Double?)
    
    /// Slow start and end, two bounces sandwich a fast motion
    case elasticInOut(magnitude: Double?)
    
    /// Bounce increasing in velocity until completion
    case bounceIn
    
    /// Bounce to completion
    case bounceOut
    
    /// Bounce in and bounce out
    case bounceInOut
    
    // Functions based on: https://github.com/AndrewRayCode/easing-utils/blob/master/src/easing.js
    func apply(to t: Double) -> Double {
        switch self {
        case .sineIn:
            return -1.0 * cos(t * .pi / 2.0) + 1.0
        case .sineOut:
            return sin(t * .pi / 2.0)
        case .sineInOut:
            return -0.5 * (cos(.pi * t) - 1.0)
        case .quadIn:
            return t * t
        case .quadOut:
            return t * (2 - t)
        case .quadInOut:
            return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
        case .cubicIn:
            return t*t*t
        case .cubicOut:
            let t1 = t - 1
            return t1 * t1 * t1 + 1
        case .cubicInOut:
            return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
        case .quartIn:
            return t * t * t * t
        case .quartOut:
            let t1 = t - 1
            return 1 - t1 * t1 * t1 * t1
        case .quartInOut:
            let t1 = t - 1
            return t < 0.5 ? 8 * t * t * t * t : 1 - 8 * t1 * t1 * t1 * t1
        case .quintIn:
            return t * t * t * t * t
        case .quintOut:
            let t1 = t - 1
            return 1 + t1 * t1 * t1 * t1 * t1
        case .quintInOut:
            let t1 = t - 1
            return t < 0.5 ? 16 * t * t * t * t * t : 1 + 16 * t1 * t1 * t1 * t1 * t1
        case .expoIn:
            guard t != 0 else { return 0 }
            return pow(2, 10 * (t - 1))
        case .expoOut:
            guard t != 1 else { return 1 }
            return pow(2, -10 * t) + 1
        case .expoInOut:
            guard t != 0 && t != 1 else { return t }
            let scaledTime = t * 2
            let scaledTime1 = scaledTime - 1
            if scaledTime < 1 {
                return 0.5 * pow(2, 10 * scaledTime1)
            }
            return 0.5 * (-pow(2, -10 * scaledTime1) + 2)
        case .circIn:
            let scaledTime = t / 1
            return -1 * (sqrt(1 - scaledTime * t) - 1)
        case .circOut:
            let t1 = t - 1
            return sqrt( 1 - t1 * t1)
        case .circInOut:
            let scaledTime = t * 2
            let scaledTime1 = scaledTime - 2
            if scaledTime < 1 {
                return -0.5 * (sqrt(1 - scaledTime * scaledTime) - 1 )
            }
            return 0.5 * (sqrt(1 - scaledTime1 * scaledTime1) + 1)
        case .backIn(let magnitude):
            let magnitude = magnitude ?? 1.70158
            return t * t * ((magnitude + 1) * t - magnitude)
        case .backOut(let magnitude):
            let magnitude = magnitude ?? 1.70158
            let scaledTime = (t / 1) - 1
            return (scaledTime * scaledTime * ((magnitude + 1) * scaledTime + magnitude)) + 1
        case .backInOut(let magnitude):
            let magnitude = magnitude ?? 1.70158
            let scaledTime = t * 2
            let scaledTime2 = scaledTime - 2
            let s = magnitude * 1.525
            if (scaledTime < 1) {
                return 0.5 * scaledTime * scaledTime * (((s + 1) * scaledTime) - s)
            }
            return 0.5 * (scaledTime2 * scaledTime2 * ((s + 1) * scaledTime2 + s) + 2)
        case .elasticIn(let magnitude):
            guard t != 0 && t != 1 else { return t }
            let magnitude = magnitude ?? 0.7
            
            let scaledTime = t / 1
            let scaledTime1 = scaledTime - 1
            let p = 1 - magnitude
            let s = p / ( 2 * .pi ) * asin(1)
            
            return -(pow(2, 10 * scaledTime1) * sin((scaledTime1 - s) * (2 * .pi) / p))
        case .elasticOut(let magnitude):
            guard t != 0 && t != 1 else { return t }
            let magnitude = magnitude ?? 0.7
            
            let p = 1 - magnitude
            let scaledTime = t * 2
            let s = p / (2 * .pi) * asin(1)
            return (pow(2, -10 * scaledTime) * sin((scaledTime - s) * (2 * .pi) / p)) + 1
        case .elasticInOut(let magnitude):
            guard t != 0 && t != 1 else { return t }
            let magnitude = magnitude ?? 0.65
            
            let p = 1 - magnitude
            let scaledTime = t * 2
            let scaledTime1 = scaledTime - 1
            let s = p / (2 * .pi) * asin(1)
            if scaledTime < 1 {
                return -0.5 * (pow(2, 10 * scaledTime1) * sin((scaledTime1 - s) * (2 * .pi) / p))
            }
            
            return (pow(2, -10 * scaledTime1) * sin((scaledTime1 - s) * (2 * .pi) / p) * 0.5) + 1
        case .bounceIn:
            return 1 - ACAnimatorEaseFunction.bounceOut.apply(to: 1 - t)
        case .bounceOut:
            let scaledTime = t / 1
            if scaledTime < (1 / 2.75 ) {
                return 7.5625 * scaledTime * scaledTime
            }
            else if scaledTime < (2 / 2.75) {
                let scaledTime2 = scaledTime - (1.5 / 2.75)
                return (7.5625 * scaledTime2 * scaledTime2) + 0.75
            }
            else if (scaledTime < (2.5 / 2.75)) {
                let scaledTime2 = scaledTime - (2.25 / 2.75)
                return (7.5625 * scaledTime2 * scaledTime2) + 0.9375
            }
            else {
                let scaledTime2 = scaledTime - (2.625 / 2.75)
                return (7.5625 * scaledTime2 * scaledTime2) + 0.984375
            }
        case .bounceInOut:
            if t < 0.5 {
                return ACAnimatorEaseFunction.bounceOut.apply(to: t * 2) * 0.5
            }
            return (ACAnimatorEaseFunction.bounceOut.apply(to:(t * 2) - 1) * 0.5) + 0.5
        default:
            return t
        }
    }
}

public class ACAnimator: NSObject {
    
    private(set) var easeFunction: ACAnimatorEaseFunction = .linear
    private(set) var duration: CFTimeInterval = 0.0
    private(set) var elapsed: CFTimeInterval = 0.0
    private(set) var startTime: CFTimeInterval = 0.0
    
    private var options: ACAnimatorOptions = []
    private var reversed: Bool = false
    
    private var displayLink: CADisplayLink?
    
    private var animation: ACAnimatorAnimation!
    private var completion: ACAnimatorCompletion?
    
    var isRunning: Bool {
        return displayLink != nil
    }
    
    deinit {
        stop()
    }
    
    public init(duration: CFTimeInterval, easeFunction: ACAnimatorEaseFunction, animation: @escaping ACAnimatorAnimation, completion: ACAnimatorCompletion? = nil) {
        super.init()
        prepare(duration: duration, easeFunction: easeFunction, options: [], animation: animation, completion: completion)
    }
    
    public init(duration: CFTimeInterval, easeFunction: ACAnimatorEaseFunction, options: ACAnimatorOptions, animation: @escaping ACAnimatorAnimation, completion: ACAnimatorCompletion? = nil) {
        super.init()
        prepare(duration: duration, easeFunction: easeFunction, options: options, animation: animation, completion: completion)
    }
    
    private func prepare(duration: CFTimeInterval, easeFunction: ACAnimatorEaseFunction, options: ACAnimatorOptions, animation: @escaping ACAnimatorAnimation, completion: ACAnimatorCompletion? = nil) {
        self.easeFunction = easeFunction
        self.duration = duration
        self.options = options
        self.animation = animation
        self.completion = completion
    }
    
    public func start() {
        guard !isRunning else {
            print("ACAnimator - Error: Can't start animation because is already running.")
            return
        }
        
        startTime = CACurrentMediaTime()
        
        // Create displayLink & add it to the run-loop
        let displayLink = CADisplayLink(target: self, selector: #selector(step))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }
    
    public func stop() {
        animationDidFinish(forcibly: true)
    }
    
    @objc private func step(_ displayLink: CADisplayLink) {
        elapsed = CACurrentMediaTime() - startTime
        let fraction = elapsed / duration
        if fraction >= 1.0 {
            animation(reversed ? 0.0 : 1.0, elapsed, duration)
            animationDidFinish()
        }
        else {
            let easedFraction = easeFunction.apply(to: reversed ? 1.0 - fraction : fraction)
            animation(easedFraction, elapsed, duration)
        }
    }
    
    private func animationDidFinish(forcibly: Bool = false) {
        guard displayLink != nil else { return }
        
        displayLink?.invalidate()
        displayLink = nil
        
        elapsed = 0.0
        startTime = 0.0
        
        if !forcibly && options.contains(.repeat) {
            if options.contains(.autoreverse) {
                reversed = !reversed
            }
            start()
        }
        else {
            completion?(!forcibly)
        }
    }
}
