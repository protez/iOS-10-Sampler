//
//  ImageFiltersViewController.swift
//  iOS-10-Sampler
//
//  Created by Shuichi Tsutsumi on 9/3/16.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import CoreImage

class ImageFiltersViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var picker: UIPickerView!
    @IBOutlet weak private var indicator: UIActivityIndicatorView!

    private var filters: [String]!
    private var orgImage: UIImage!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        orgImage = imageView.image
        filters = CIFilter.names(
            available_iOS: 10,
            category: kCICategoryBuiltIn,
            exceptCategories: [kCICategoryGradient])
        print("filters:\(filters)\n")
        filters.insert("Original", at: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func applyFilter(name: String, handler: ((UIImage?) -> Void)) {
        let inputImage = CIImage(image: self.orgImage)!
        guard let filter = CIFilter(name: name) else {fatalError()}
        let attributes = filter.attributes
        print("attributes:\(attributes)")
        
        if attributes[kCIInputImageKey] == nil {
            print("\(name) has no inputImage property.")
            handler(nil)
            return
        }

        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setDefaults()
        

        // for CINinePartStretched & CINinePartTiled
        let inputSize = inputImage.extent.size
        let effectW = inputSize.width / 4
        let effectH = inputSize.height / 4
        if attributes["inputBreakpoint0"] != nil {
            // Lower left corner of image
            let breakPoint = CIVector(cgPoint: CGPoint(x: effectW, y: effectH))
            filter.setValue(breakPoint, forKey: "inputBreakpoint0")
        }
        if attributes["inputBreakpoint1"] != nil {
            // Upper right corner of image
            let breakPoint = CIVector(cgPoint: CGPoint(x: inputSize.width - effectW, y: inputSize.height - effectH))
            filter.setValue(breakPoint, forKey: "inputBreakpoint1")
        }
        if attributes["inputGrowAmount"] != nil {
            let amount = CIVector(cgPoint: CGPoint(x: inputSize.width * 2, y: inputSize.height * 2))
            filter.setValue(amount, forKey: "inputGrowAmount")
        }
        
        // Apply filter
        let context = CIContext(options: nil)
        guard let outputImage = filter.outputImage else {
            handler(nil)
            return
        }
        
        let size = self.imageView.frame.size
        var extent = outputImage.extent
        let scale: CGFloat!
        
        // some outputImage have infinite extents. e.g. CIDroste
        if extent.isInfinite {
            scale = UIScreen.main.scale
            extent = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        } else {
            scale = extent.size.width / self.orgImage.size.width
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: extent) else {fatalError()}
        let image = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
        print("extent:\(extent), image:\(image), org:\(self.orgImage), scale:\(scale)\n")
        
        handler(image)
    }
    
    // =========================================================================
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return filters.count
    }
    
    // =========================================================================
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filters[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            imageView.image = orgImage
            return
        }
        
        indicator.startAnimating()
        
        DispatchQueue.global(qos: .default).async {
            self.applyFilter(name: self.filters[row], handler: { (image) in
                DispatchQueue.main.async(execute: {
                    self.imageView.image = image
                    self.indicator.stopAnimating()
                })
            })
        }
    }

}
