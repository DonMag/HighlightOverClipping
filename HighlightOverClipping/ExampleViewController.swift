//
//  ExampleViewController.swift
//  HighlightOverClipping
//
//  Created by Don Mag on 1/29/22.
//

import UIKit

class ExampleViewController: UIViewController, MyCustomViewDelegate {
	
	var useLayerMethod: Bool = true
	
	// some data to add subviews
	var idx: Int = 0
	let colors: [UIColor] = [
		.systemRed, .systemGreen, .systemBlue, .systemYellow,
		.gray, .lightGray, .purple, .systemOrange,
	]
	
	let viewTestView: MyCustomView = {
		let v = MyCustomView()
		// we can set some properties here
		//v.outlineColor = .red			// default is .green
		//v.outlineWidth = 1			// default is 2
		//v.outlineDashPattern = [20, 4]	// default is nil (solid border)
		//v.cornerRadius = 24			// default is 32
		//v.bkgColor = .black			// default is .blue
		//v.dragLimit = 24				// default is 12
		//v.allowDragToRemove = true	// default is false
		//v.shouldBringToFront = true	// default is false
		return v
	}()
	
	let layerTestView: AnotherCustomView = {
		let v = AnotherCustomView()
		// we can set some properties here
		//v.outlineColor = .red			// default is .green
		//v.outlineWidth = 1			// default is 2
		//v.outlineDashPattern = [20, 4]	// default is nil (solid border)
		//v.cornerRadius = 24			// default is 32
		//v.bkgColor = .black			// default is .blue
		//v.dragLimit = 24				// default is 12
		//v.allowDragToRemove = true	// default is false
		//v.shouldBringToFront = true		// default is false
		return v
	}()
	
	var testView: UIView!
	
	// label to show subview count
	let subviewCountLabel: UILabel = {
		let v = UILabel()
		v.textAlignment = .center
		v.textColor = .darkGray
		v.text = "Subview Count: 0"
		return v
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
		
		// outlineView or outlineLayer method
		if useLayerMethod {
			testView = layerTestView
		} else {
			testView = viewTestView
		}
		
		// let's add a couple buttons
		let btnStack: UIStackView = {
			let v = UIStackView()
			v.axis = .horizontal
			v.distribution = .fillEqually
			v.spacing = 16
			return v
		}()
		
		["Add a View", "Remove Selected"].forEach { t in
			let b = UIButton()
			b.backgroundColor = .red
			b.setTitle(t, for: [])
			b.setTitleColor(.white, for: .normal)
			b.setTitleColor(.lightGray, for: .highlighted)
			b.layer.cornerRadius = 8
			b.addTarget(self, action: #selector(btnTap(_:)), for: .touchUpInside)
			btnStack.addArrangedSubview(b)
		}
		
		// add a "Drag Outside to Remove" option
		let dragOptionStack: UIStackView = {
			let v = UIStackView()
			v.axis = .horizontal
			v.spacing = 16
			return v
		}()
		
		let dLabel: UILabel = {
			let v = UILabel()
			v.textAlignment = .right
			v.textColor = .darkGray
			v.text = "Drag Outside to Remove:"
			return v
		}()
		
		let dSwitch: UISwitch = {
			let v = UISwitch()
			v.isOn = false
			v.addTarget(self, action: #selector(dragSwitchChanged(_:)), for: .valueChanged)
			return v
		}()
		
		dragOptionStack.addArrangedSubview(dLabel)
		dragOptionStack.addArrangedSubview(dSwitch)
		
		// add a "Bring subview to Front" option
		let selectOptionStack: UIStackView = {
			let v = UIStackView()
			v.axis = .horizontal
			v.spacing = 16
			return v
		}()
		
		let sLabel: UILabel = {
			let v = UILabel()
			v.textAlignment = .right
			v.textColor = .darkGray
			v.text = "Bring Selected to Front:"
			return v
		}()
		
		let sSwitch: UISwitch = {
			let v = UISwitch()
			v.isOn = false
			v.addTarget(self, action: #selector(selectSwitchChanged(_:)), for: .valueChanged)
			return v
		}()
		
		selectOptionStack.addArrangedSubview(sLabel)
		selectOptionStack.addArrangedSubview(sSwitch)
		
		// let's add an instructions label
		let iLabel: UILabel = {
			let v = UILabel()
			v.numberOfLines = 0
			v.textAlignment = .center
			v.backgroundColor = .darkGray
			v.textColor = .white
			v.text = "\nAfter adding subview(s)\n\nTap to Select and Drag\n\nTap empty area or\nDouble-Tap on the Selected view\nto De-select\n"
			return v
		}()
		
		// vertical stack view to arrange everything
		let vStack: UIStackView = {
			let v = UIStackView()
			v.axis = .vertical
			v.alignment = .center
			v.spacing = 8
			return v
		}()
		
		[btnStack, dragOptionStack, selectOptionStack, testView, subviewCountLabel, iLabel].forEach { v in
			vStack.addArrangedSubview(v)
		}
		
		vStack.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(vStack)
		
		let g = view.safeAreaLayoutGuide
		NSLayoutConstraint.activate([
			
			vStack.topAnchor.constraint(equalTo: g.topAnchor, constant: 20.0),
			vStack.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 20.0),
			vStack.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -20.0),
			
			btnStack.widthAnchor.constraint(equalTo: vStack.widthAnchor),
			
			testView.widthAnchor.constraint(equalTo: vStack.widthAnchor, multiplier: 0.75),
			testView.heightAnchor.constraint(equalTo: testView.widthAnchor, multiplier: 1.0),
			
			iLabel.widthAnchor.constraint(equalTo: vStack.widthAnchor),
			
		])
		
		
		if let tv = testView as? MyCustomView {
			tv.delegate = self
			dSwitch.isOn = tv.allowDragToRemove
			sSwitch.isOn = tv.shouldBringToFront
		}
		if let tv = testView as? AnotherCustomView {
			tv.delegate = self
			dSwitch.isOn = tv.allowDragToRemove
			sSwitch.isOn = tv.shouldBringToFront
		}

	}
	
	func updateCountLabel() {
		var n: Int = 0
		if let tv = testView as? MyCustomView {
			n = tv.subviewCount
		}
		if let tv = testView as? AnotherCustomView {
			n = tv.subviewCount
		}
		subviewCountLabel.text = "Subview Count: \(n)"
	}
	
	// MARK: UI actions
	@objc func btnTap(_ sender: UIButton) {
		guard let t = sender.currentTitle else { return }
		if t == "Add a View" {
			let v = UILabel()
			v.translatesAutoresizingMaskIntoConstraints = true
			v.text = "View \(idx)"
			v.textColor = .white
			v.backgroundColor = colors[idx % colors.count]
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
			idx += 1
		} else {
			if let img = UIImage(named: "sample1") {
				let iv = UIImageView(image: img)
				let f = testView.frame.width / img.size.width
				iv.frame = CGRect(origin: .zero, size: CGSize(width: testView.frame.width, height: img.size.height * f))
				if let tv = testView as? MyCustomView {
					tv.addView(iv, atCenter: false)
				}
				if let tv = testView as? AnotherCustomView {
					tv.addView(iv, atCenter: false)
				}
			}
//			testView.removeSelected()
		}
		updateCountLabel()
	}
	@objc func dragSwitchChanged(_ sender: UISwitch) {
		if let tv = testView as? MyCustomView {
			tv.allowDragToRemove = sender.isOn
		}
		if let tv = testView as? AnotherCustomView {
			tv.allowDragToRemove = sender.isOn
		}
	}
	@objc func selectSwitchChanged(_ sender: UISwitch) {
		if let tv = testView as? MyCustomView {
			tv.shouldBringToFront = sender.isOn
		}
		if let tv = testView as? AnotherCustomView {
			tv.shouldBringToFront = sender.isOn
		}
	}

	// MARK: delegate funcs
	func didSelectSubview(_ subView: UIView) {
		// if we want to do something when
		//	a subview was selected
		//print("Selected:", subView)
	}
	func didDeselectSubview(_ subView: UIView) {
		// if we want to do something when
		//	a subview was deselected
		//print("De-selected:", subView)
	}
	func didRemoveSubview() {
		//print("removed a view")
		updateCountLabel()
	}
}

