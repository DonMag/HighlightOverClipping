//
//  ViewController.swift
//  HighlightOverClipping
//
//  Created by Don Mag on 1/28/22.
//

import UIKit

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	@IBAction func showSimpleView(_ sender: Any) {
		let vc = SimpleExampleViewController()
		vc.useLayerMethod = false
		navigationController?.pushViewController(vc, animated: true)
	}
	
	@IBAction func showSimpleLayer(_ sender: Any) {
		let vc = SimpleExampleViewController()
		vc.useLayerMethod = true
		navigationController?.pushViewController(vc, animated: true)
	}
	

	var isFirstTime: Bool = true
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if isFirstTime {
			isFirstTime = false
			let vc = UIAlertController(title: "Please Note!", message: "\nThis is EXAMPLE code!\n\nIt is intended to be a Starting Point Only and should not be considered\n\n\"Production Ready\"", preferredStyle: .alert)
			vc.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			present(vc, animated: true, completion: nil)
		}
	}

}

