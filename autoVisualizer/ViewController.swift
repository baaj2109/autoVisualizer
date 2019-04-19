//
//  ViewController.swift
//  autoVisualizer
//
//  Created by kehwaweng on 2019/4/2.
//  Copyright © 2019 kehwaweng. All rights reserved.
//

import Cocoa
import IPEVOCameraKitOSX
import CreateML
import CoreML


class ViewController: NSViewController, ICCameraStreamProxyDelegate {
    
    let nc              : NotificationCenter = NotificationCenter.default
    let model           = scene_model()
    var context         : CIContext = CIContext()
    
    var liveStreamLayer : ICLiveStreamLayer?
    var status          : [String] = []
    var camera          : ICCamera?
    
    var maxBrightness   : Int16 = 0
    var maxContrast     : Int16 = 0
    var maxGamma        : Int16 = 0
    var maxHue          : Int16 = 0
    var maxSaturation   : Int16 = 0
    var maxSharpness    : Int16 = 0
    
    var minBrightness   : Int16 = 0
    var minContrast     : Int16 = 0
    var minGamma        : Int16 = 0
    var minHue          : Int16 = 0
    var minSaturation   : Int16 = 0
    var minSharpness    : Int16 = 0
    
    var dBrightness     : Int16 = 0
    var dContrast       : Int16 = 0
    var dGamma          : Int16 = 0
    var dHue            : Int16 = 0
    var dSaturation     : Int16 = 0
    var dSharpness      : Int16 = 0
    
    @IBOutlet weak var videoContainView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nc.addObserver(forName: NSNotification.Name(rawValue: ICNotificationCameraAttached), object: nil, queue: nil, using: { (notification) in
            if let userInfo = notification.userInfo{
                self.camera = userInfo[ICCamerasManagerNotificationKeyCamera] as? ICCamera
                if (self.camera?.ready)!{
                    self.getCameraVariable()
                    self.setCamera()
                }
            }
        })
    }
    
    func cameraStreamProxy(_ cameraStreamProxy: ICCameraStreamProxy!, didReceiveFrame image: CIImage!, withInfo info: [AnyHashable : Any]!, from camera: ICCamera!) {
//        NSLog("received image")
        let image       = image!.resized(to: CGSize(width: 224, height: 224))
        let pixelbuffer = image?.toPixelBuffer_RGB(context: self.context, width: 224, height: 224)
        let prediction  = try? model.prediction(image: pixelbuffer!)
        NSLog("prediction: %@ , confidence: %f",prediction!.classLabel,prediction!.prediction.first!.value)
        if prediction!.prediction.first!.value < 0.5 {
            return
        }
        if status.count < 15{
            status.append(prediction!.classLabel)
        }else{
            status.removeFirst()
            status.append(prediction!.classLabel)
            let mappedItems = status.map{($0,1)}
            let counts = Dictionary(mappedItems, uniquingKeysWith: +).sorted(by: {$0.1 > $1.1})
            
            if Double(counts.first!.value) / 15.0 > 0.75 {
                
                /*
                        page
                 */
                if counts.first!.key == "page"{
                    let normContrast    = Int16( Double(31 - 0 ) / Double(95 - 0)           * Double(maxContrast - minContrast))     + minContrast
                    let normGamma       = Int16( Double(245 - 100) / Double(300 - 100)      * Double(maxGamma - minGamma))           + minGamma
                    let normHue         = Int16( Double(0 - -2000) / Double(2000 - -2000)   * Double(maxHue - minHue))               + minHue
                    let normSaturation  = Int16( Double(dSaturation - 0 ) / Double(100 - 0) * Double(maxSaturation - minSaturation)) + minSaturation
                    let normSharpness   = Int16( Double(3 - 1) / Double(7 - 1)              * Double(maxSharpness - minSharpness))   + minSharpness
                    setVariable(normContrast, normGamma, normHue, normSaturation, normSharpness)
//                    setVariable(31, 245, 0, dSaturation, 3)
                /*
                        classroom
                 */
                }else if counts.first!.key == "classroom"{
                    let normContrast    = Int16( Double(dContrast - 0 ) / Double(95 - 0)        * Double(maxContrast - minContrast))     + minContrast
                    let normGamma       = Int16( Double(dGamma - 100) / Double(300 - 100)       * Double(maxGamma - minGamma))           + minGamma
                    let normHue         = Int16( Double(dHue - -2000) / Double(2000 - -2000)    * Double(maxHue - minHue))               + minHue
                    let normSaturation  = Int16( Double(84 - 0 ) / Double(100 - 0)              * Double(maxSaturation - minSaturation)) + minSaturation
                    let normSharpness   = Int16( Double(dSharpness - 1) / Double(7 - 1)         * Double(maxSharpness - minSharpness))   + minSharpness
                    setVariable(normContrast, normGamma, normHue, normSaturation, normSharpness)
//                    setVariable(dContrast, dGamma, dHue, 84, dSharpness)
                    
                /*
                        object
                 */
                }else if counts.first!.key == "object"{
                    let normContrast    = Int16( Double(16 - 0 ) / Double(95 - 0)           * Double(maxContrast - minContrast))     + minContrast
                    let normGamma       = Int16( Double(150 - 100) / Double(300 - 100)     * Double(maxGamma - minGamma))           + minGamma
                    let normHue         = Int16( Double(0 - -2000) / Double(2000 - -2000)   * Double(maxHue - minHue))               + minHue
                    let normSaturation  = Int16( Double(100 - 0 ) / Double(100 - 0)         * Double(maxSaturation - minSaturation)) + minSaturation
                    let normSharpness   = Int16( Double(2 - 1) / Double(7 - 1)              * Double(maxSharpness - minSharpness))   + minSharpness
                    setVariable(normContrast, normGamma, normHue, normSaturation, normSharpness)
//                    setVariable(16, 200, 0, 100, 2)
                    
                /*
                        magz
                 */
                }else if counts.first!.key == "magz"{
                    let normContrast    = Int16( Double(11 - 0 ) / Double(95 - 0)           * Double(maxContrast - minContrast))     + minContrast
                    let normGamma       = Int16( Double(177 - 100) / Double(300 - 100)      * Double(maxGamma - minGamma))           + minGamma
                    let normHue         = Int16( Double(17 - -2000) / Double(2000 - -2000)  * Double(maxHue - minHue))               + minHue
                    let normSaturation  = Int16( Double(100 - 0 ) / Double(100 - 0)         * Double(maxSaturation - minSaturation)) + minSaturation
                    let normSharpness   = Int16( Double(3 - 1) / Double(7 - 1)              * Double(maxSharpness - minSharpness))   + minSharpness
                    setVariable(normContrast, normGamma, normHue, normSaturation, normSharpness)
//                    setVariable(11, 177, 17, 100, 3)
                    
                }else{
                    print("ERROR!!!")
                }
            /*
                 unique not equal 1
            */
            }else{
                setVariable(dContrast, dGamma, dHue, dSaturation, dSharpness)
            }
        }// end if
        
    }// end cameraStreamProxy
    
    
    func setVariable(_ Contrast: Int16 , _ Gamma: Int16, _ Hue: Int16, _ Saturation: Int16, _ Sharpness: Int16, _ Brightness: Int16 = 0){
        
        camera?.getBrightnessOf(.current){ (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                let newV = Int16(0.75 * Double(value) + 0.25 * Double(Brightness))
                self.camera?.setBrightness(newV)
            }
        }
        camera?.getContrastOf(.current) { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                let newV = Int16(0.75 * Double(value) + 0.25 * Double(Contrast))
                self.camera?.setContrast(newV)
            }
        }
        camera?.getGammaOf(.current) { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                let newV = Int16(0.75 * Double(value) + 0.25 * Double(Gamma))
                self.camera?.setGamma(newV)
            }
        }
        camera?.getHueOf(.current) { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                let newV = Int16(0.75 * Double(value) + 0.25 * Double(Hue))
                self.camera?.setHue(newV)
            }
        }
        camera?.getSaturationOf(.current) { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                let newV = Int16(0.75 * Double(value) + 0.25 * Double(Saturation))
                self.camera?.setSaturation(newV)
            }
        }
        camera?.getSharpnessOf(.current) { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                let newV = Int16(0.75 * Double(value) + 0.25 * Double(Sharpness))
                self.camera?.setSharpness(newV)
            }
        }
    }
    
    func getCameraVariable(){
        /*
                Brightness
         */
        camera?.getBrightnessOf(.maximum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.maxBrightness  = value
            }
        })
        camera?.getBrightnessOf(.default, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.dBrightness    = value
            }
        })
        camera?.getBrightnessOf(.minimum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.minBrightness  = value
            }
        })
        /*
                Contrast
         */
        camera?.getContrastOf(.maximum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.maxContrast    = value
            }
        })
        camera?.getContrastOf(.default, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.dContrast      = value
            }
        })
        camera?.getContrastOf(.minimum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.minContrast    = value
            }
        })
        /*
                Gamma
         */
        camera?.getGammaOf(.maximum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.maxGamma       = value
            }
        })
        camera?.getGammaOf(.default, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.dGamma         = value
            }
        })
        camera?.getGammaOf(.minimum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.minGamma       = value
            }
        })
        
        /*
                Hue
         */
        camera?.getHueOf(.maximum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.maxHue         = value
            }
        })
        camera?.getHueOf(.default, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.dHue           = value
            }
        })
        camera?.getHueOf(.minimum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.minHue         = value
            }
        })
        /*
                Saturation
         */
        camera?.getSaturationOf(.maximum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.maxSaturation  = value
            }
        })
        camera?.getSaturationOf(.default, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.dSaturation    = value
            }
        })
        camera?.getSaturationOf(.minimum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.minSaturation  = value
            }
        })
        /*
                Sharpness
         */
        camera?.getSharpnessOf(.maximum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.maxSharpness   = value
            }
        })
        camera?.getSharpnessOf(.default, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.dSharpness     = value
            }
        })
        camera?.getSharpnessOf(.minimum, completionHandler: { (error, value) in
            if (error as NSError?)?.code == IPEVOCameraErrorCode.success.rawValue {
                self.minSharpness   = value
            }
        })

    }// end getCameraVariable
    
    func setCamera(){
        ICCameraStreamProxy.shared()?.addStreamObserver(self, for: self.camera!)
        let captureSession      = ICCameraStreamProxy.shared()?.captureSession(for: self.camera!)
        self.liveStreamLayer    = ICLiveStreamLayer.init(session: captureSession)
        self.liveStreamLayer?.autoresizingMask = [.layerHeightSizable, .layerWidthSizable]
        DispatchQueue.main.async {
            if let layer = self.videoContainView.layer, let liveStreamLayer = self.liveStreamLayer {
                liveStreamLayer.frame = layer.bounds
                self.videoContainView.layer?.addSublayer(liveStreamLayer)
            }
        }
    }// end setCamera

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension CIImage {

    func resized(to size: CGSize) -> CIImage? {
        guard extent.width > 0 && extent.height > 0 else {
            debugPrint("extent.width or extent.height is 0 so you cannot resize this CIImage to the size: \(size)")
            return nil
        }
        let xScale = size.width / extent.width
        let yScale = size.height / extent.height
        return transformed(by: CGAffineTransform(scaleX: xScale, y: yScale))
    }
    func toPixelBuffer_RGB(context:CIContext, width: Int, height: Int) -> CVPixelBuffer?{
        // Create a dictionary requesting Core Graphics compatibility
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey:kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey:kCFBooleanTrue
            ] as CFDictionary
        
        var nullablePixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA ,
                                         attributes,
                                         &nullablePixelBuffer)
        
        guard status == kCVReturnSuccess, let pixelBuffer = nullablePixelBuffer
            else { return nil }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        context.render(self,
                       to: pixelBuffer,
                       bounds: self.extent,
                       colorSpace:CGColorSpaceCreateDeviceRGB() )
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
