# ImageVideoPicker
I was searching for a similar Image and Video Picker for a project and i wasn't able to find one that was able to :
1. Take picture
2. Get a Picture from the library
3. Register a Video
4. Get a video from the library

While i was looking i hopen whatsup of facebook or mabe google have a pod for this kind of needs, i realy liked the whatsapp picker, so i created this one similer to the one in whatsapp.

## Getting Started


### Prerequisites

In order to use ImageVideoPicker you need cocoapods and an xCode project already created

### Installing

to install cocoapods is should be enough just to run `sudo gem install cocoapods` in the terminal
if this doen't work go to [cocoapods](https://cocoapods.org/)

Then navigate the terminal to your project folder, where the file extension `.xcodeproj` is located and run `pod init`
this will create a file called `Podfile`
Open the file in a editor ( sublimeText, xCode, atom, vim ... etc ) and add the line bellow after `use_frameworks!`

```
pod 'ImagePickerWhatsApp'
```
or 
```
pod 'ImagePickerWhatsApp', :path => '/Users/aiu/Documents/cocoapods/ImagePickerWhatsApp'
```

then just run `pod install` in the terminal and wait to finish instaling the lib

### How to use it

add `import ImagePickerWhatsApp` to your viewcontroller class

then you can call the picker by calling :
```
let mp = ImageVideoPicker.makeVCFromStoryboard()
self.present(mp, animated: true, completion: nil)
```

### Delegate
to implement the delegate add `mp.delegate = self` and the extent the class of you view controller
aso you need to import the iOS Photos framework `import Photos`

````
extension ViewController: ImageVideoPickerDelegate {
    func onCancel() {
        print("no picture selected")
    }

    func onDoneSelection(assets: [PHAsset]) {
       print("selected \(assets.count) assets")
    }
}
````

the func `onDoneSelection` returns an array of assets that contain the info of where the asset is located : on the device, iTunes library or iCloud.

if you just need to display the images you can use the this code in a collection view or something similar just implement this peace of code
````
var representedAssetIdentifier: String!

func getImageFrom(asset: Phasset) {
    representedAssetIdentifier = asset?.localIdentifier
    let imageManager = PHCachingImageManager()

    imageManager.requestImage(for: asset!, targetSize: self.frame.size, contentMode: .default, options: nil) { (image, _) in

        if(self.representedAssetIdentifier == self.asset?.localIdentifier &&
            image != nil) {
            self.imageView.image = image
        }
    }
}

````

this will show just the thumbnail, but is awesome because is also showing the thumbnail for live photos, and videos

### Images and Videos as Data

The lib is intended to be used for sending images or videos over the network, and not to do fancy image or video editing. But this doesn't mea you can't. You can do just about anything since it returns an array of assets, but is you job to implement what you need.

in order to get the data from the asset ImageVideoPicker has one method that will return an completition handler with the data. 

```
ImageVideoPicker.getDataFrom(asset: asset) { (data) in
    if data == nil {
        print(data as Any, asset.mediaType, asset.localIdentifier)
    } else {
        print(data!.count as Any, asset.mediaType, asset.localIdentifier)
    }
}
```
that will be all
have fun

## Authors

* **Ion Utale** 

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details




