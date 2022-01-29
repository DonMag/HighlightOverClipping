//
//  SimpleExampleViewController.swift
//  HighlightOverClipping
//
//  Created by Don Mag on 1/29/22.
//

import UIKit

class SimpleExampleViewController: UIViewController {

	var useLayerMethod: Bool = true
	
	var testView: UIView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
		
		// outlineView or outlineLayer method
		if useLayerMethod {
			testView = AnotherCustomView()
		} else {
			testView = MyCustomView()
		}

		testView.translatesAutoresizingMaskIntoConstraints = false
		
		view.addSubview(testView)
		
		let g = view.safeAreaLayoutGuide
		NSLayoutConstraint.activate([
			
			testView.widthAnchor.constraint(equalTo: g.widthAnchor, multiplier: 0.75),
			testView.heightAnchor.constraint(equalTo: testView.widthAnchor, multiplier: 1.0),
			testView.centerXAnchor.constraint(equalTo: g.centerXAnchor),
			testView.centerYAnchor.constraint(equalTo: g.centerYAnchor),
			
		])
		
		if let tv = testView as? MyCustomView {
			tv.outlineWidth = 1
		}
		if let tv = testView as? AnotherCustomView {
			tv.outlineWidth = 1
		}

	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// add an image view and a label
		
		if let img = UIImage(named: "sample1") {
			let iv = UIImageView(image: img)
			// let's make the image view 10% wider than the clipping view
			let w = testView.frame.width * 1.10
			let f = w / img.size.width
			iv.frame = CGRect(origin: .zero, size: CGSize(width: w, height: img.size.height * f))
			if let tv = testView as? MyCustomView {
				tv.addView(iv, atCenter: true)
			}
			if let tv = testView as? AnotherCustomView {
				tv.addView(iv, atCenter: true)
			}
		}
		
		let v = UILabel()
		v.translatesAutoresizingMaskIntoConstraints = true
		v.text = "Sample Label"
		v.textColor = .white
		v.backgroundColor = .red
		v.textAlignment = .center
		v.font = .systemFont(ofSize: 32, weight: .bold)
		v.isUserInteractionEnabled = false
		v.sizeToFit()
		v.frame.size.width += 16
		v.frame.size.height += 12
		if let tv = testView as? MyCustomView {
			tv.addView(v)
		}
		if let tv = testView as? AnotherCustomView {
			tv.addView(v)
		}
		
	}
	
}

