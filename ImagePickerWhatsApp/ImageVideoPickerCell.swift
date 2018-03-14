//
//  ImageViewPickerCell.swift
//  Youtech
//
//  Created by Ion Utale on 31/01/18.
//  Copyright © 2018 Ion Utale. All rights reserved.
//

import UIKit
import Photos

extension TimeInterval {
    
    func format() -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1
        return formatter.string(from: self)
    }
}



class ImageVideoPickerCell : UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectedImage: UIImageView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var videoDuration: UILabel!
    
    var representedAssetIdentifier: String!
    
    var asset: PHAsset? {
        didSet {
            videoView.isHidden = true
            videoDuration.text = ""
            if(asset?.mediaType == PHAssetMediaType.video) {
                videoView.isHidden = false
                videoDuration.text = asset?.duration.format()
            }
            
            let imageManager = PHCachingImageManager()
            representedAssetIdentifier = asset?.localIdentifier
            
            imageManager.requestImage(for: asset!, targetSize: self.frame.size, contentMode: .default, options: nil) { (image, _) in
                
                if(self.representedAssetIdentifier == self.asset?.localIdentifier &&
                    image != nil) {
                    self.imageView.image = image
                }
            }
        }
    }
    
    var selection: Bool? {
        didSet {
            selectedImage.isHidden = !selection!
        }
    }
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 10
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 10,height: 10)
        self.layer.shadowRadius = 10
        self.layer.shadowOpacity = 0.5
    }
}
