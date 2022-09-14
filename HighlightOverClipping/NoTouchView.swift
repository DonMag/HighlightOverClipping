//
//  NoTouchView.swift
//  HighlightOverClipping
//
//  Created by Don Mag on 1/30/22.
//

import UIKit

class NoTouchView: UIView, UIGestureRecognizerDelegate {
	
	public weak var delegate: MyCustomViewDelegate?
	
	// MARK: public properties
	public var bkgColor: UIColor = .blue {
		didSet {
			clippingView.backgroundColor = bkgColor
		}
	}
	public var cornerRadius: CGFloat = 32 {
		didSet {
			clippingView.layer.cornerRadius = cornerRadius
		}
	}
	public var outlineColor: UIColor = .green {
		didSet {
			outlineView.dashColor = outlineColor
		}
	}
	public var outlineWidth: CGFloat = 2 {
		didSet {
			outlineView.dashLineWidth = outlineWidth
		}
	}
	public var outlineDashPattern: [NSNumber]? {
		didSet {
			outlineView.dashPattern = outlineDashPattern
		}
	}

	// limit dragging of subviews to keep them visbile
	//	this is the number of Points to keep inside the clipping view
	public var dragLimit: CGFloat = 12
	
	// if true, dragging a subview out-of-view will remove it
	public var allowDragToRemove: Bool = false
	
	// if true, selected view is brought to front
	public var shouldBringToFront: Bool = false
	
	// so the caller can get the subview count
	public var subviewCount: Int {
		return clippingView.subviews.count
	}
	
	// so the caller can get a reference to the selected view
	public var selectedView: UIView? {
		return currentView
	}
	
	// MARK: private properties
	// this will hold the subviews
	private let clippingView: UIView = {
		let v = UIView()
		v.clipsToBounds = true
		v.isUserInteractionEnabled = true
		v.translatesAutoresizingMaskIntoConstraints = false
		return v
	}()
	
	// this will outline / highlight the selected subview
	private let outlineView: OutlineView = {
		let v = OutlineView()
		v.isUserInteractionEnabled = false
		v.translatesAutoresizingMaskIntoConstraints = true
		return v
	}()
	
	// used for tracking the pan movement
	private var iCenter: CGPoint = .zero
	private var isDragging: Bool = false
	
	// used for restricting subview dragging
	private var allowedCenterBez: UIBezierPath!
	
	// tracks the currently selected viwe
	private var currentView: UIView?
	
	// MARK: init
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	private func commonInit() {
		
		// clipping view properties
		clippingView.backgroundColor = bkgColor
		clippingView.layer.cornerRadius = cornerRadius
		
		// outline / highlight view properties
		outlineView.dashColor = outlineColor
		outlineView.dashLineWidth = outlineWidth
		
		// add clipping view
		addSubview(clippingView)
		
		// add outline view AFTER adding clipping view
		addSubview(outlineView)
		
		// constrain clipping view to all 4 sides of self
		NSLayoutConstraint.activate([
			clippingView.topAnchor.constraint(equalTo: topAnchor, constant: 0.0),
			clippingView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.0),
			clippingView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0.0),
			clippingView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0.0),
		])
		
		// outline view starts hidden
		outlineView.isHidden = true
		
		// add a Double-Tap Gesture Recognizer to self
		//	to allow De-Selecting the currently selected view
		let dp = UITapGestureRecognizer(target: self, action: #selector(gotDoubleTap(_:)))
		dp.numberOfTapsRequired = 2
		// add it to SELF (not to a subview of self)
		clippingView.addGestureRecognizer(dp)
		
		dp.delegate = self
		
	}
	
	// MARK: gesture delegate
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
	
	// MARK: double-tap / touch / drag funcs
	@objc private func gotDoubleTap(_ g: UITapGestureRecognizer) {
		if let cv = currentView {
			// yes, so deselect it
			deselectSubview(cv)
		}
	}
	
	@objc private func panHandler(_ g: UIPanGestureRecognizer) {
		
		guard let panV = g.view else { return }
		
		let cView: UIView = clippingView
		
		let translation = g.translation(in: cView)
		
		switch g.state {
		case .began:
			if let cv = currentView {
				if cv != panV {
					deselectSubview(cv)
					selectSubview(panV)
				}
			} else {
				selectSubview(panV)
			}
			if shouldBringToFront {
				cView.bringSubviewToFront(panV)
			}
			// prevent subview from being dragged out-of-view
			//	adjust limit as desired
			if allowDragToRemove || dragLimit <= 0 {
				allowedCenterBez = UIBezierPath(roundedRect: bounds.insetBy(dx: -(panV.frame.width), dy: -(panV.frame.height)),
												cornerRadius: cornerRadius)
			} else {
				allowedCenterBez = UIBezierPath(roundedRect: bounds.insetBy(dx: -(panV.frame.width * 0.5 - dragLimit), dy: -(panV.frame.height * 0.5 - dragLimit)),
												cornerRadius: cornerRadius)
			}
			()
			
		case .changed:
			let pt: CGPoint = CGPoint(x: panV.center.x + translation.x,
									  y: panV.center.y + translation.y)
			// only move the subview if the center falls
			//	inside the allowed bezier path
			if allowedCenterBez.contains(pt) {
				panV.center = pt
				outlineView.center = pt
			}
			g.setTranslation(CGPoint(x: 0, y: 0), in: panV)
			()
			
		case .ended:
			// if the subview was dragged out-of-view
			//	we want to delete it
			allowedCenterBez = UIBezierPath(roundedRect: bounds.insetBy(dx: -(panV.frame.width * 0.5 - 2), dy: -(panV.frame.height * 0.5 - 2)),
											cornerRadius: cornerRadius)
			if !allowedCenterBez.contains(panV.center) {
				removeSelected()
			}
			()
			
		default:
			()
			
		}
		
	}
	
	// MARK: public Select / Deselect / Add / Remove
	public func selectSubview(_ subView: UIView) {
		
		currentView = subView
		
		outlineView.frame.size = subView.frame.size.insetBy(dw: -outlineWidth * 2.0, dh: -outlineWidth * 2.0)
		outlineView.center = subView.center
		
		// show outline view
		outlineView.isHidden = false
		
		// inform the delegate
		delegate?.didSelectSubview?(subView)
		
	}
	
	public func deselectSubview(_ subView: UIView) {
		currentView = nil
		// hide outline view
		outlineView.isHidden = true
		// inform the delegate
		delegate?.didDeselectSubview?(subView)
	}
	
	public func addView(_ view: UIView, atCenter: Bool? = true) {
		let b: Bool = atCenter == nil ? true : atCenter!
		if b {
			view.center = clippingView.center
		}
		clippingView.addSubview(view)
		view.isUserInteractionEnabled = true
		let pg: UIPanGestureRecognizer = ImmediatePanG(target: self, action: #selector(panHandler(_:)))
		view.addGestureRecognizer(pg)
	}
	
	public func removeSelected() {
		if let v = currentView {
			deselectSubview(v)
			v.removeFromSuperview()
			// inform the delegate
			delegate?.didRemoveSubview?()
		}
	}
	
}
