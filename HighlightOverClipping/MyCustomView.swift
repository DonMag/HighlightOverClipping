//
//  MyCustomView.swift
//  HighlightOverClipping
//
//  Created by Don Mag on 1/29/22.
//

import UIKit

@objc protocol MyCustomViewDelegate {
	@objc optional func didSelectSubview(_ subView: UIView)
	@objc optional func didDeselectSubview(_ subView: UIView)
	@objc optional func didRemoveSubview()
}

class MyCustomView: UIView, UIGestureRecognizerDelegate {
	
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
		
		// create a Pan Gesture Recognizer
		//	we'll use a subclassed Recognizer to allow
		//	immediate Panning
		let pg = ImmediatePanG(target: self, action: #selector(panHandler(_:)))
		// add it to SELF (not to a subview of self)
		addGestureRecognizer(pg)
		
		// Touching an empty area (i.e. NOT on a subview)
		//	will De-Select the currently selected view
		// but we'll also add a Double-Tap Gesture Recognizer to allow
		//	De-Selecting the currently selected view
		let dp = UITapGestureRecognizer(target: self, action: #selector(gotDoubleTap(_:)))
		dp.numberOfTapsRequired = 2
		// add it to SELF (not to a subview of self)
		addGestureRecognizer(dp)
		
		pg.delegate = self
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
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		
		// if we have no subviews, we don't want to do anything
		guard clippingView.subviews.count > 0 else { return }
		
		guard let touch = touches.first else { return }
		
		let loc = touch.location(in: clippingView)
		var touchedView: UIView?
		
		// if subviews overlap, we want to get the "top" subview
		//	so check top-down in the hierarchy
		let topDownSubviews: [UIView] = clippingView.subviews.reversed()
		
		// loop through, looking for the touch
		//	inside a subview
		for i in 0..<topDownSubviews.count {
			let v = topDownSubviews[i]
			if v.frame.contains(loc) {
				touchedView = v
				if shouldBringToFront {
					clippingView.bringSubviewToFront(v)
				}
				break
			}
		}
		
		// if a subview was touched
		if let tv = touchedView {
			// is there a current selected view?
			if let cv = currentView {
				// is it the same subview?
				if cv == tv {
					// yes, so we don't need to do anything
				} else {
					// not the same subview, so
					//	de-select the current one
					deselectSubview(cv)
					// and select the new one
					selectSubview(tv)
				}
			} else {
				// there's no current selected view, so
				//	select the new one
				selectSubview(tv)
			}
		} else {
			// the touch was NOT on a subview
			// is there a current selected view?
			if let cv = currentView {
				// yes, so deselect it
				deselectSubview(cv)
			}
		}
		
	}
	
	@objc private func panHandler(_ g: UIPanGestureRecognizer) {
		
		// is there a selected subview?
		if let v = currentView {
			
			switch g.state {
			case .began:
				// if pan started inside the selected subview
				if v.frame.contains(g.location(in: clippingView)) {
					// get the subview's current center
					iCenter = v.center
					// we're now dragging
					isDragging = true
					// prevent subview from being dragged out-of-view
					//	adjust limit as desired
					if allowDragToRemove || dragLimit <= 0 {
						allowedCenterBez = UIBezierPath(roundedRect: bounds.insetBy(dx: -(v.frame.width), dy: -(v.frame.height)), cornerRadius: cornerRadius)
					} else {
						allowedCenterBez = UIBezierPath(roundedRect: bounds.insetBy(dx: -(v.frame.width * 0.5 - dragLimit), dy: -(v.frame.height * 0.5 - dragLimit)), cornerRadius: cornerRadius)
					}
				}
				
			case .changed:
				// if we're dragging a subview
				if isDragging {
					let translation = g.translation(in: clippingView)
					
					let pt: CGPoint = CGPoint(x: iCenter.x + translation.x,
											  y: iCenter.y + translation.y)
					
					// only move the subview if the center falls
					//	inside the allowed bezier path
					if allowedCenterBez.contains(pt) {
						v.center = pt
						outlineView.center = pt
					}
				}
				
			case .ended:
				// finished dragging...
				isDragging = false
				
				// if the subview was dragged out-of-view
				//	we want to delete it
				allowedCenterBez = UIBezierPath(roundedRect: bounds.insetBy(dx: -(v.frame.width * 0.5 - 2), dy: -(v.frame.height * 0.5 - 2)), cornerRadius: cornerRadius)
				if !allowedCenterBez.contains(v.center) {
					removeSelected()
				}
				return()

				let bez: UIBezierPath = UIBezierPath(roundedRect: clippingView.bounds, cornerRadius: cornerRadius)
				
				// check the 4 corners of the subview
				if bez.contains(CGPoint(x: v.frame.minX, y: v.frame.minY)) ||
					bez.contains(CGPoint(x: v.frame.minX, y: v.frame.maxY)) ||
					bez.contains(CGPoint(x: v.frame.maxX, y: v.frame.minY)) ||
					bez.contains(CGPoint(x: v.frame.maxX, y: v.frame.maxY))
				{
					// at least one corner is still visible
					//	so we're good
					break
				}

				// NO corners were visible, but the subview
				//	may be wider or taller than self, so
				if !v.frame.intersects(clippingView.bounds) {
					removeSelected()
				}
				
				// so remove the subview
				//removeSelected()
				
			default:
				isDragging = false
			}
			
		}
		
	}
	
	// MARK: public Select / Deselect / Add / Remove
	public func selectSubview(_ subView: UIView) {
		
		currentView = subView
		
		outlineView.frame.size = subView.frame.size
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

// MARK: CGSize helper
//	insetBy() -- similar to CGRect insetBy()
extension CGSize {
	func insetBy(dw: CGFloat, dh: CGFloat) -> CGSize {
		return CGSize(width: width - dw, height: height - dh)
	}
}

// MARK: Pan Gesture subclass
// from: https://stackoverflow.com/a/19145354/6257435
//	triggers Pan Gesture Began without waiting for "minimum distance" movement
class ImmediatePanG: UIPanGestureRecognizer {
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesBegan(touches, with: event)
		self.state = .began
	}
}
