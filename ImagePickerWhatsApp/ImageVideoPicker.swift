//
//  ImageVideoPicker.swift
//  Youtech PROD
//
//  Created by Ion Utale on 30/01/2018.
//  Copyright © 2018 Florence-Consulting. All rights reserved.
//

import Foundation
import Photos
import AVFoundation

enum CaptureType: Int {
    case photo
    case video
}

class MediaFile {
    var mimetype: String?
    var path: URL?
}

@objc protocol ImageVideoPickerDelegate {
    @objc optional func onCancel()
//    func onDoneSelection(urls: [MediaFile])
    @objc optional func onDoneSelection(assets: [PHAsset])
}

open class ImageVideoPicker: UIViewController {
    
    var destinationPath: URL?
    
    var captureType: CaptureType! = CaptureType.video
    var filePath: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("video.mov")
    }
    
    // camera capture
    var session: AVCaptureSession?
    var imageOutput: AVCapturePhotoOutput?
    var videoOutput: AVCaptureMovieFileOutput? //AVCaptureVideoDataOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet var previewView: UIView!
    
    // register time label
    @IBOutlet var registerTime: UILabel!
    var timer: Timer?
    var registerTimeSec: Double = 0 {
        didSet {
            self.registerTime.text = Date.timeFromSeconds(seconds: self.registerTimeSec)
        }
    }
    
    // photos/video library
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var mediaModeButton: UIButton!
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var toggleCollectionView: UIView!
    @IBOutlet var collectionViewHeight: NSLayoutConstraint!
    
    var allPhotos: PHFetchResult<PHAsset>!
    var selectedPhotos: [PHAsset] = [] {
        didSet {
            let btnTitle = self.selectedPhotos.count == 0 ? "Cancel" : "Done"
            self.doneBtn.setTitle(btnTitle, for: .normal)
        }
    }
    @IBOutlet var doneBtn: UIButton!

    var delegate: ImageVideoPickerDelegate?
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    
    open static func makeVCFromStoryboard() -> ImageVideoPicker {
        let bundle = Bundle(for: ImageVideoPicker.self)
        return UIStoryboard(name: "MediaPicker", bundle: bundle).instantiateViewController(withIdentifier: "picker") as! ImageVideoPicker
    }
    
    override open func viewDidLoad() {
        let bundle = Bundle(for: ImageVideoPicker.self)
        collectionView.register(UINib(nibName: "ImageVideoPickerCell", bundle: bundle), forCellWithReuseIdentifier: "asset")
        preparePhotoLibrary()
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(toggleCollectionViewAction))
        toggleCollectionView.addGestureRecognizer(tap)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        changeMode(nil)
    }
    
    @objc func toggleCollectionViewAction() {
        if(collectionViewHeight.constant != 0) {
            hideCollectionView()
        } else {
            showCollectionView()
        }
    }
    
    func hideCollectionView () {
        UIView.animate(withDuration: 0.3) {
            self.collectionViewHeight.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func showCollectionView () {
        UIView.animate(withDuration: 0.3) {
            self.collectionViewHeight.constant = 160
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func doneAction(_ sender: Any) {
        if selectedPhotos.count == 0 {
            delegate?.onCancel!()
        } else {
            delegate?.onDoneSelection!(assets: selectedPhotos)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func changeMode(_ sender: UIButton!) {
        let bundle = Bundle(for: ImageVideoPicker.self)

        if(captureType == .photo) {
            captureType = .video
            cameraButton.setImage(UIImage(named: "ic_start_rec", in: bundle,compatibleWith: nil)!, for: .normal)
            mediaModeButton.setImage(UIImage(named: "ic_camera_white_24dp", in: bundle,compatibleWith: nil)!, for: .normal)
            registerTime.isHidden = false
        } else {
            captureType = .photo
            cameraButton.setImage(UIImage(named: "ic_save_photo", in: bundle,compatibleWith: nil)!, for: .normal)
            mediaModeButton.setImage(UIImage(named: "video", in: bundle,compatibleWith: nil)!, for: .normal)
            registerTime.isHidden = true
        }
        setupCamera()
        videoPreviewLayer?.frame = previewView.bounds
    }
    
    @IBAction func savePicture(_ sender: UIButton!) {
        guard imageOutput != nil || videoOutput != nil else  { return }
        let bundle = Bundle(for: ImageVideoPicker.self)

        switch captureType {
        case .photo:
            registerTime.isHidden = true
            capturePhoto()
        case .video:
            registerTime.isHidden = false
            registerTimeSec = 0
            
            if videoOutput!.isRecording {
                timer?.invalidate()
                showCollectionView()
                cameraButton.setImage(UIImage(named: "ic_start_rec", in: bundle,compatibleWith: nil)!, for: .normal)
                videoOutput?.stopRecording()
                mediaModeButton.isEnabled = true
                collectionView.isHidden = false
            } else {
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateRegisterTime), userInfo: nil, repeats: true)
                hideCollectionView()
                mediaModeButton.isEnabled = false
                collectionView.isHidden = true
                cameraButton.setImage(UIImage(named: "ic_stop_rec", in: bundle,compatibleWith: nil)!, for: .normal)
                captureVideo()
            }
        default:
            print("capture type not recognized")
        }
    }
    
    @objc func updateRegisterTime () {
        registerTimeSec += 1
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

}

extension ImageVideoPicker: UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allPhotos.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: ImageVideoPickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: "asset", for: indexPath) as! ImageVideoPickerCell
        
        cell.asset = allPhotos.object(at: indexPath.item)
        cell.selection = false

        let index = selectedPhotos.index(of: cell.asset!)
        if index != nil {
            cell.selection = true
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = allPhotos.object(at: indexPath.item)
        
        let cell = collectionView.cellForItem(at: indexPath) as! ImageVideoPickerCell
        if cell.selection! {
            let index = selectedPhotos.index(of: asset)
            selectedPhotos.remove(at: index!)
            cell.selection = false
        } else {
            selectedPhotos.append(asset)
            cell.selection = true
        }
        
    }
}

extension ImageVideoPicker: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: collectionView.frame.size.height - 10, height: collectionView.frame.size.height - 10)
    }
}

extension ImageVideoPicker: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("did finish registering")
        UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, self, nil, nil);
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("did start registering")
    }
}

// capture photo
extension ImageVideoPicker: AVCapturePhotoCaptureDelegate {
    
    @available(iOS 11.0, *)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error { print(error.localizedDescription) }
        
        if let imageData = photo.fileDataRepresentation() {
            if let uiImage = UIImage(data: imageData) {
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            }
        }
    }
    
    //For iOS 10 or below
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            UIImageWriteToSavedPhotosAlbum(UIImage(data: dataImage)!, nil, nil, nil)
        }
        
    }

}

extension ImageVideoPicker {
    
    func captureVideo() {
        guard videoOutput != nil else  { return }
        if videoOutput!.connection(with: AVMediaType.video) == nil { return }
        videoOutput?.startRecording(to: filePath, recordingDelegate: self)
    }
    
    func capturePhoto() {
        guard imageOutput != nil else  { return }
        if imageOutput!.connection(with: AVMediaType.video) == nil { return }
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160,
                             ]
        settings.previewPhotoFormat = previewFormat
        imageOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func setupCamera () {
        // Setup your camera here...
        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSession.Preset.medium
        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video) else {
            print("simulator has no camera")
            return
        }
        
        var error: NSError?
        var input: AVCaptureDeviceInput?
        (input, error) = captureDeviceInput(camera: backCamera)
        
        if error == nil && !(session!.canAddInput(input!)) { return }
        session!.addInput(input!)

        switch captureType {
        case .photo:
            prepareSessionForPhoto()
        case .video:
            prepareSessionForVideo()
        default:
            print("capture type not recognized")
        }
    }
    
    
    func prepareSessionForPhoto() {
        // The remainder of the session setup will go here...
        
        imageOutput = AVCapturePhotoOutput()
        if #available(iOS 11.0, *) {
            imageOutput?.supportedPhotoCodecTypes(for: AVFileType.jpg)
        } else {
            // Fallback on earlier versions
            /*let settings = AVCapturePhotoSettings.init(format: [AVVideoCodecKey: AVVideoCodecJPEG])
            imageOutput?.setPreparedPhotoSettingsArray([settings], completionHandler: nil)*/
        }
        //imageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        if session!.canAddOutput(imageOutput!) {
            session!.addOutput(imageOutput!)
            // ...
            // Configure the Live Preview here...
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
            videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            //                videoPreviewLayer!.frame = previewView.bounds
            previewView.layer.addSublayer(videoPreviewLayer!)
            session!.startRunning()
        }
    }
    
    func prepareSessionForVideo() {
        
        videoOutput = AVCaptureMovieFileOutput() // AVCaptureVideoDataOutput() // 2
      
        if session!.canAddOutput(videoOutput!) {
            session!.addOutput(videoOutput!)
            // ...
            // Configure the Live Preview here...
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
            videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            previewView.layer.addSublayer(videoPreviewLayer!)
            session!.startRunning()
        }
        
    }
    
    func captureDeviceInput(camera: AVCaptureDevice) -> (AVCaptureDeviceInput?, NSError?) {
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: camera)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        return (input, error)
    }
}


// MARK : - get images and videos
extension ImageVideoPicker: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Check each of the three top-level fetches for changes.
            
            if let changeDetails = changeInstance.changeDetails(for: allPhotos) {
                // Update the cached fetch result.
                allPhotos = changeDetails.fetchResultAfterChanges
                // (The table row for this one doesn't need updating, it always says "All Photos".)
                self.collectionView.reloadData()
//                getVideoUrl()
            }
        }
    }
}

extension ImageVideoPicker {
    
    func preparePhotoLibrary() {
        PHPhotoLibrary.shared().register(self)
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        updateItemSize()
    }
    
    private func updateItemSize() {
        
        let viewWidth = view.bounds.size.width
        
        let desiredItemWidth: CGFloat = 100
        let columns: CGFloat = max(floor(viewWidth / desiredItemWidth), 4)
        let padding: CGFloat = 1
        let itemWidth = floor((viewWidth - (columns - 1) * padding) / columns)
        let itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.main.scale
        thumbnailSize = CGSize(width: itemSize.width * scale, height: itemSize.height * scale)
    }
}

// extract video testing
extension ImageVideoPicker {
    open  static func getDataFrom(asset: PHAsset, completion: @escaping(Data?) -> ()) {
        if asset.mediaType == .image {
            ImageVideoPicker.getDataFor(imageAsset: asset) { data in
                completion(data)
            }
        } else if asset.mediaType == .video {
            ImageVideoPicker.getDataFor(videoAsset: asset) { data in
                completion(data)
            }
        } else {
            assert(true, "unknown media type. please contact: utale.ion@gmail.com")
        }
    }
    
    private static func getDataFor(videoAsset: PHAsset, completion: @escaping((Data?)->())) {
        // it will be cool to add this to the selection, so that you can show the progress befor show selected image
        let videoOption = PHVideoRequestOptions()
        videoOption.isNetworkAccessAllowed = true
        videoOption.progressHandler = {
            (progress, error, stop, info) -> Void in
            print("video progress: ", progress)
        }
        
        PHImageManager().requestAVAsset(forVideo: videoAsset, options: videoOption, resultHandler: { (avurlAsset, audioMix, dict) in
            guard let newObj = avurlAsset as? AVURLAsset else { return }
            
            do {
                let data = try Data.init(contentsOf: newObj.url)
                completion(data)
            } catch (let error ) {
                print(error.localizedDescription)
                completion(nil)
            }
        })
    }
    
    private static func getDataFor(imageAsset: PHAsset, completion: @escaping((Data?)->())) {
        // it will be cool to add this to the selection, so that you can show the progress befor show selected image
        let imageOption = PHImageRequestOptions()
        imageOption.isNetworkAccessAllowed = true
        imageOption.progressHandler = {
            (progress, error, stop, info) -> Void in
            print("image progress: ",progress)
        }
        
        let imageManager = PHCachingImageManager()
        imageManager.requestImage(for: imageAsset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: imageOption) { (image, anyHash) in
            if image == nil {
                completion(nil)
            } else {
                completion(UIImageJPEGRepresentation(image!, 0))
            }
        }
    }
}

