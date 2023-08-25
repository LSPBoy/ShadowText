//
//  ViewController.swift
//  MultipleProjections
//
//  Created by Sun on 2023/7/12.
//

import UIKit

class ViewController: UIViewController {
    
    private let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.addSubview(imageView)
        imageView.contentMode = .center
        imageView.layer.borderColor = UIColor.red.cgColor
        imageView.layer.borderWidth = 0.5
        
        let font = UIFont(name: "Avenir-Black", size: 80) ?? .systemFont(ofSize: 80, weight: .black)
        let textColor = UIColor(red: 0.439, green: 0.894, blue: 0.913, alpha: 1.0)
        let image = "SUPER".dualProjections(font, textColor: textColor)
        imageView.image = image
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        imageView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        imageView.center = self.view.center
    }
}

