# YoutubeDirectLinkExtractor

[![Build Status](https://travis-ci.org/devandsev/YoutubeDirectLinkExtractor.svg?branch=develop)](https://travis-ci.org/devandsev/YoutubeDirectLinkExtractor)

YoutubeDirectLinkExtractor allows you to obtain the direct link to a YouTube video, which you can easily use with AVPlayer. 
It uses type safety and optionals to guarantee that you won't crash while extracting the link no matter what. There are popular alternatives, which use more straightforward and risky approach, though: [YoutubeSourceParserKit](https://github.com/mojilala/YoutubeSourceParserKit), [HCYoutubeParser](https://github.com/hellozimi/HCYoutubeParser).

## Installation

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
    pod 'YoutubeDirectLinkExtractor'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```bash
$ pod install
```

### [Carthage](https://github.com/Carthage/Carthage)

Add this to `Cartfile`

```
github "devandsev/YoutubeDirectLinkExtractor"
```

In the `Cartfile` directory, type:

```bash
$ carthage update
```

## Usage examples

Any force unwrapping used here is just for keeping examples short, don't use it in real projects.

Basic usage:

```swift
let y = YoutubeDirectLinkExtractor()
y.extractInfo(for: .urlString("https://www.youtube.com/watch?v=HsQvAnCGxzY"), success: { info in
    print(info.highestQualityPlayableLink)
}) { error in
    print(error)
}
```

Extract lowest quality video link from id:

```swift
let y = YoutubeDirectLinkExtractor()
y.extractInfo(for: .id("HsQvAnCGxzY"), success: { info in
    print(info.lowestQualityPlayableLink)
}) { error in
    print(error)
}
```

Use extracted video link with AVPlayer:

```swift
let y = YoutubeDirectLinkExtractor()
y.extractInfo(for: .urlString("https://www.youtube.com/watch?v=HsQvAnCGxzY"), success: { info in
    let player = AVPlayer(url: URL(string: info.highestQualityPlayableLink!)!)
    let playerViewController = AVPlayerViewController()
    playerViewController.player = player

    self.present(playerViewController, animated: true) {
        playerViewController.player!.play()
    }
}) { error in
    print(error)
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
