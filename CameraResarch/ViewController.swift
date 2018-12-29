//
//  ViewController.swift
//  CameraResarch
//
//  Created by sam on 2018/12/20.
//  Copyright © 2018年 sam. All rights reserved.
//

import UIKit
import AVFoundation
import OpenGLES

var previewLayer: CameraGLKView!
var isFilter = false
var eaglContext: EAGLContext!
var eagPlContext: EAGLContext!
var ciContext: CIContext!
var previewContext: CIContext!
var dataArr = [CameraGLKView]()
var filterArr = [String]()
var currentIndex: Int!

class ViewController: UIViewController {
    
    
    
    @IBOutlet weak var gestureView: UIView!
    @IBOutlet weak var captureBtn: UIButton!
    
    var scrollV = UIScrollView()
    var captureSession: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    var captureDeviceInput: AVCaptureDeviceInput! //输入
    var captureDeviceOutput: AVCaptureVideoDataOutput! //输出
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        currentIndex = 0
        setupSession()
        
        captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            captureDeviceInput = try AVCaptureDeviceInput.init(device: captureDevice)
        } catch {
            print("错误")
        }
        captureDeviceOutput = AVCaptureVideoDataOutput()
        captureDeviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(captureDeviceOutput)
        setupContexts()
        
        filterArr = ["","CIPhotoEffectMono","CILinearToSRGBToneCurve","CISepiaTone","CIPhotoEffectFade","CIPhotoEffectTonal","CIPhotoEffectTransfer","CIPhotoEffectChrome","CIHardLightBlendMode","CIMaskToAlpha","CIAffineClamp","CIColorPosterize"]
        
        
        addGestures()
    }
    func addGestures() {
        let leftswip = UISwipeGestureRecognizer(target: self, action: #selector(leftswipeGesture))
        leftswip.direction = .left
        gestureView.addGestureRecognizer(leftswip)
        
        let rightswip = UISwipeGestureRecognizer(target: self, action: #selector(rightswipeGesture))
        rightswip.direction = .right
        gestureView.addGestureRecognizer(rightswip)
    }
    
    @objc func leftswipeGesture() {
        currentIndex += 1
        if currentIndex > 11 {
            currentIndex = 0
        }
        print("\(String(describing: currentIndex))")
    }
    @objc func rightswipeGesture() {
        currentIndex -= 1
        if currentIndex < 0 {
            currentIndex = 11
        }
        print("\(String(describing: currentIndex))")
    }
    
    @IBAction func filterBtnClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        isFilter = !isFilter
        if sender.isSelected {
            self.captureBtn.isHidden = true
            scrollV.isHidden = false
        } else {
            self.captureBtn.isHidden = false
             scrollV.isHidden = true
//            scrollV.removeFromSuperview()
//            for view in scrollV.subviews {
//                view.removeFromSuperview()
//            }
//            dataArr.removeAll()
        }
        
    }
    func setupScrollView() {
        
        
        scrollV.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height-160, width: UIScreen.main.bounds.size.width, height: 160)
        scrollV.backgroundColor = UIColor.black
        for i in 0...11 {
            let backView = CameraGLKView.init(frame: CGRect(x: 10*(i+1)+60*i, y: 0, width: 60, height: 60), context: eaglContext)
            backView.centerY = 80
            backView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2));
            backView.layer.cornerRadius = 4
            backView.layer.masksToBounds = true
            scrollV.addSubview(backView)
            dataArr.append(backView)
        }
        scrollV.contentSize = CGSize(width: 70*12+10, height: 0)
        view.addSubview(scrollV)
    }

    func setupContexts() {
        eaglContext = EAGLContext.init(api: EAGLRenderingAPI.openGLES3)
        eagPlContext = EAGLContext.init(api: EAGLRenderingAPI.openGLES3)
        ciContext = CIContext.init(eaglContext: eaglContext)
        previewContext = CIContext.init(eaglContext: eagPlContext)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
        
        previewLayer = CameraGLKView.init(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height-160), context: eagPlContext)
        previewLayer.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2));
        view.insertSubview(previewLayer, at: 0)
        setupScrollView()
        
    }
    
    @IBAction func captureBtnClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }
    
    //创建capturesession
    func setupSession() {
        captureSession = AVCaptureSession()
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}

extension UIViewController:AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
//        if isFilter {
            getVideoSampleBuffer(sampleBuffer: sampleBuffer)
//        }
        
        
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    }
}


func getVideoSampleBuffer(sampleBuffer: CMSampleBuffer) {

    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    let sourceImage = CIImage.init(cvImageBuffer: imageBuffer as! CVPixelBuffer, options: nil)
    let sourceExtent = sourceImage.extent;
    let sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
    var outputImage = CIImage()
    
    if previewLayer != nil {
        let previewAspect =  CGFloat(previewLayer.drawableWidth)  /  CGFloat(previewLayer.drawableHeight);
        outputImage = addFilter(ciimage: sourceImage, num: currentIndex)
        var drawRect = sourceExtent;
        if (sourceAspect > previewAspect) {
            drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect) / 2.0;
            drawRect.size.width = drawRect.size.height * previewAspect;
        } else {
            drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect) / 2.0;
            drawRect.size.height = drawRect.size.width / previewAspect;
        }

        if  eagPlContext != nil {
            EAGLContext.setCurrent(eagPlContext)
        }
        previewLayer.bindDrawable()
        glClearColor(0.5, 0.5, 0.5, 1.0);
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
        
        glEnable(GLenum(GL_BLEND));
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA));
        
        previewContext.draw(outputImage, in: CGRect(x:0.0,y: 0.0, width:CGFloat(previewLayer.drawableWidth), height:CGFloat(previewLayer.drawableHeight)), from: drawRect)
        
        previewLayer.display()
    }
    
    if !isFilter {
        return
    }
    
    for i in 0...(dataArr.count-1) {
        let backView = dataArr[i]
        outputImage = addFilter(ciimage: sourceImage, num: i)
        let previewAspect =  CGFloat(backView.drawableWidth)  /  CGFloat(backView.drawableHeight);
        var drawRect = sourceExtent;
        if (sourceAspect > previewAspect) {
            drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect) / 2.0;
            drawRect.size.width = drawRect.size.height * previewAspect;
        } else {
            drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect) / 2.0;
            drawRect.size.height = drawRect.size.width / previewAspect;
        }
        backView.bindDrawable()

        if eaglContext != nil {
            EAGLContext.setCurrent(eaglContext)
        }

        glClearColor(0.5, 0.5, 0.5, 1.0);
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT));

        glEnable(GLenum(GL_BLEND));
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA));

        ciContext.draw(outputImage, in: CGRect(x:0.0,y: 0.0, width:CGFloat(backView.drawableWidth), height:CGFloat(backView.drawableHeight)), from: drawRect)

        backView.display()
    }

    
//    print("\(Thread.current)")
}

func addFilter(ciimage:CIImage, num:Int) -> CIImage{
    var filter : CIFilter!
    
    let filterName = filterArr[num]
    filter = CIFilter(name: filterName)
    
    var output = CIImage()
    if filter != nil {
        filter.setValue(ciimage, forKey: kCIInputImageKey)
         output = filter.value(forKey: kCIOutputImageKey) as! CIImage
    } else {
         output = ciimage
    }
    
    return output
}


