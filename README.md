# 🏞

[![Pod Version](https://cocoapod-badges.herokuapp.com/v/PhotoPreviewer/badge.png)](http://cocoadocs.org/docsets/PhotoPreviewer/)
[![Pod Platform](https://cocoapod-badges.herokuapp.com/p/PhotoPreviewer/badge.png)](http://cocoadocs.org/docsets/PhotoPreviewer/)
[![Pod License](https://cocoapod-badges.herokuapp.com/l/PhotoPreviewer/badge.png)](https://www.apache.org/licenses/LICENSE-2.0.html)

# PhotoPreviewer
Preview photos for iOS written by Swift

## Requirements

- iOS 9.0 or later
- Xcode 10.0 or later

## Installation
There is a way to use PaddingLabel in your project:

- Using CocoaPods
- Manually

### Installation with CocoaPods

```
pod 'PhotoPreviewer', '1.0'
```

### Manually

Manually drag file [PhotoPreviewViewController.swift](https://github.com/levantAJ/PhotoPreviewer/blob/master/PhotoPreviewer/PhotoPreviewViewController.swift) to your project. 


### Build Project

At this point your workspace should build without error. If you are having problem, post to the Issue and the
community can help you solve it.

## How To Use

```swift
import PhotoPreviewer

let imageURLs = [URL(string: "https://geek-is-stupid.github.io/img/avatar-icon.png")!]
let photoPreviewVC = PhotoPreviewViewController(imageURLs: imageURLs, startAtIndex: 0)
photoPreviewVC.sourceImageView = yourImageView
present(photoPreviewVC, animated: true)

```

## Author
- [Tai Le](https://github.com/levantAJ)

## Communication
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Licenses

All source code is licensed under the [MIT License](https://raw.githubusercontent.com/levantAJ/PhotoPreviewer/master/LICENSE).
