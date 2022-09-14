//
//  DragBasicsViewController.swift
//  HighlightOverClipping
//
//  Created by Don Mag on 1/30/22.
//

import UIKit

class DragBasicsViewController: UIViewController {

	let v1 = UIView()
	let v2 = UIView()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		view.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
		
		v1.frame = CGRect(x: 20, y: 80, width: 100, height: 80)
		v2.frame = CGRect(x: 60, y: 180, width: 60, height: 120)
		
		v1.backgroundColor = .red
		v2.backgroundColor = .blue
		
		v1.layer.borderColor = UIColor.green.cgColor
		v2.layer.borderColor = UIColor.green.cgColor

		view.addSubview(v1)
		view.addSubview(v2)
		
		[v1, v2].forEach { v in
			let pg: UIPanGestureRecognizer = ImmediatePanG(target: self, action: #selector(panView(_:)))
			v.addGestureRecognizer(pg)
		}
		let pg: UIPanGestureRecognizer = ImmediatePanG(target: self, action: #selector(panView(_:)))
		self.view.addGestureRecognizer(pg)

    }

	@objc func panView(_ sender: UIPanGestureRecognizer) {
		
		guard let subV = sender.view else { return }

		let cView: UIView = self.view
		
		if subV == cView {
			self.view.subviews.forEach { thisV in
				thisV.layer.borderWidth = 0
			}
			return
		}
		
		let translation = sender.translation(in: cView)

		switch sender.state {
		case .began:
			self.view.subviews.forEach { thisV in
				thisV.layer.borderWidth = thisV == subV ? 2 : 0
			}
			self.view.bringSubviewToFront(subV)
			()
			
		case .changed:
			subV.center = CGPoint(x: subV.center.x + translation.x,
							   y: subV.center.y + translation.y)
			sender.setTranslation(CGPoint(x: 0, y: 0), in: subV)
			()
			
		case .ended:
			()
			
		default:
			()
			
		}
		
	}

}
