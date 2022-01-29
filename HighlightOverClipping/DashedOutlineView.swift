//
//  DashedOutlineView.swift
//  HighlightOverClipping
//
//  Created by Don Mag on 1/29/22.
//

import UIKit

// MARK: simple dashed-outline view
//	draws an outline frame outside the bounds
//	optionally with a dash pattern
class DashedOutlineView: UIView {
	public var dashColor: UIColor = .red {
		didSet {
			shapeLayer.strokeColor = dashColor.cgColor
		}
	}
	public var dashLineWidth: CGFloat = 1 {
		didSet {
			shapeLayer.lineWidth = dashLineWidth
		}
	}
	public var dashPattern: [NSNumber]? {
		didSet {
			shapeLayer.lineDashPattern = dashPattern
		}
	}
	
	private var shapeLayer: CAShapeLayer!
	override class var layerClass: AnyClass {
		return CAShapeLayer.self
	}
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	private func commonInit() -> Void {
		shapeLayer = self.layer as? CAShapeLayer
		shapeLayer.fillColor = UIColor.clear.cgColor
		shapeLayer.borderColor = UIColor.clear.cgColor
		shapeLayer.lineWidth = dashLineWidth
		shapeLayer.lineDashPattern = dashPattern
		backgroundColor = .clear
	}
	override func layoutSubviews() {
		super.layoutSubviews()
		shapeLayer.path = UIBezierPath(rect: bounds.insetBy(dx: -(dashLineWidth * 0.5), dy: -(dashLineWidth * 0.5))).cgPath
		//shapeLayer.path = UIBezierPath(rect: bounds).cgPath
	}
}

