//
//  ViewController.swift
//  CoreML-Model-Comparer
//
//  Created by Kyle Haptonstall on 2/10/18.
//  Copyright © 2018 Kyle Haptonstall. All rights reserved.
//

import CoreML
import UIKit
import Vision

class ViewController: UIViewController {
    
    typealias ModelTuple = (model: MLModel, modelName: String, outputLabel: UILabel)
    
    // MARK: Constants
    
    private enum Constant {
        static let outputFormat = "%@: %d%% - %@"
        static let performingClassificationFormat = "%@ is performing classification..."
    }
    
    // MARK: Private Variables
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var mobileNetLabel: UILabel!
    @IBOutlet private weak var squeezeNetLabel: UILabel!
    @IBOutlet private weak var resNet50Label: UILabel!
    @IBOutlet private weak var inceptionV3Label: UILabel!
    @IBOutlet private weak var vgg16Label: UILabel!
    
    lazy private var modelTuples: [ModelTuple] = {
       return [
        (MobileNet().model, "MobileNet", mobileNetLabel),
        (Inceptionv3().model, "InceptionV3", inceptionV3Label),
        (Resnet50().model, "ResNet50", resNet50Label),
        (VGG16().model, "VGG16", vgg16Label),
        (SqueezeNet().model, "SqueezeNet", squeezeNetLabel)
        ]
    }()
    
    // MARK: Button Actions
    
    @IBAction func pickImageButtonPressed(_ sender: Any) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            DispatchQueue.main.async {
                self.presentImagePicker(withType: .camera)
            }
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            DispatchQueue.main.async {
                self.presentImagePicker(withType: .photoLibrary)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelAction)
        present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: Private Methods
    
    private func presentImagePicker(withType type: UIImagePickerControllerSourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = type
        present(pickerController, animated: true)
    }
    
    private func detectObjects(from image: CIImage) {
        for tuple in modelTuples {
            tuple.outputLabel.text = String(format: Constant.performingClassificationFormat, tuple.modelName)
            
            guard let visionModel = try? VNCoreMLModel(for: tuple.model) else {
                fatalError("Can't load model")
            }
            
            let visionRequest = VNCoreMLRequest(model: visionModel) { (request, error) in
                guard let results = request.results as? [VNClassificationObservation],
                    let topResult = results.first else {
                        fatalError("Unexpected result type from VNCoreMLRequest")
                }
                
                DispatchQueue.main.async {
                    tuple.outputLabel.text = String(format: Constant.outputFormat, tuple.modelName, Int(topResult.confidence * 100), topResult.identifier)
                }
            }
            
            let handler = VNImageRequestHandler(ciImage: image)
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    try handler.perform([visionRequest])
                } catch {
                    print(error)
                }
            }
        }
        
    }
}

// MARK: - UINavigationControllerDelegate + UIImagePickerControllerDelegate

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Couldn't load image picked image")
        }
        
        imageView.image = image
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("Couldn't convert UIImage to CIImage")
        }
        
        detectObjects(from: ciImage)
    }
    
}
