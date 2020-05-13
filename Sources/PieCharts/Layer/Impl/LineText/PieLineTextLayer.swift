//
//  PieLineTextLayer.swift
//  PieCharts
//
//  Created by Ivan Schuetz on 30/12/2016.
//  Copyright © 2016 Ivan Schuetz. All rights reserved.
//

import UIKit

public struct PieLineTextLayerSettings {
    public var segment1Length: CGFloat = 15
    public var segment2Length: CGFloat = 15
    public var lineColor: UIColor = UIColor.black
    public var lineWidth: CGFloat = 1
    public var chartOffset: CGFloat = 5
    public var labelXOffset: CGFloat = 5
    public var labelYOffset: CGFloat = 0
    public var useLineMarker: Bool = true
    public var lineMarkerSize: CGSize = CGSize(width: 10, height: 10)
    public var lineMarkerBorderSize: CGFloat = 1
    public var lineMarkerBorderColor: CGColor = UIColor.black.cgColor
    public var lineMarkerBackgroundColor: CGColor = UIColor.white.cgColor
    public var valueLabel: PieChartLabelSettings = PieChartLabelSettings()
    public var titleLabel: PieChartLabelSettings = PieChartLabelSettings()
    
    public init() {}
}

open class PieLineTextLayer: PieChartLayer {
    typealias SliceLabels = (title: UILabel, value: UILabel)
    public weak var chart: PieChart?
    
    public var settings: PieLineTextLayerSettings = PieLineTextLayerSettings()
    
    fileprivate var sliceViews = [PieSlice: (CALayer, SliceLabels)]()
    
    public var animator: PieLineTextLayerAnimator = AlphaPieLineTextLayerAnimator()
    
    public init() {}
    
    public func onEndAnimation(slice: PieSlice) {
        addItems(slice: slice)
    }
    
    public func addItems(slice: PieSlice) {
        guard sliceViews[slice] == nil else { return }
        
        let p1 = slice.view.calculatePosition(angle: slice.view.midAngle, p: slice.view.center, offset: slice.view.outerRadius + settings.chartOffset)
        let p2 = slice.view.calculatePosition(angle: slice.view.midAngle, p: slice.view.center, offset: slice.view.outerRadius + settings.segment1Length)
        
        let angle = slice.view.midAngle.truncatingRemainder(dividingBy: CGFloat.pi * 2)
        let isRightSide = angle >= 0 && angle <= (CGFloat.pi / 2) || (angle > (CGFloat.pi * 3 / 2) && angle <= CGFloat.pi * 2)
        
        let p3 = CGPoint(x: p2.x + (isRightSide ? settings.segment2Length : -settings.segment2Length), y: p2.y)
        
        let lineLayer = createLine(p1: p1, p2: p2, p3: p3)
        let valueLabel = createLabel(slice: slice, isRightSide: isRightSide, referencePoint: p3, isTitle: false)
        let titleLabel = createLabel(slice: slice, isRightSide: isRightSide, referencePoint: p3, isTitle: true)

        for slice in sliceViews {
            if slice.value.1.title.frame.intersects(titleLabel.frame) {
                settings.useLineMarker = false
                continue
            } else {
                chart?.addSubview(titleLabel)
            }

            if slice.value.1.value.frame.intersects(valueLabel.frame) {
                settings.useLineMarker = false
                continue
            } else {
                chart?.container.addSublayer(lineLayer)
                animator.animate(lineLayer)
                chart?.addSubview(valueLabel)
                break
            }
        }

        if settings.useLineMarker {
            let dot = UIView(frame: CGRect(
                x: p1.x - (settings.lineMarkerSize.width / 2),
                y: p1.y - (settings.lineMarkerSize.height / 2),
                width: settings.lineMarkerSize.width,
                height: settings.lineMarkerSize.height))
            dot.layer.backgroundColor = settings.lineMarkerBackgroundColor
            dot.layer.borderColor = settings.lineMarkerBorderColor
            dot.layer.borderWidth = settings.lineMarkerBorderSize
            dot.layer.cornerRadius = dot.frame.width / 2
            chart?.addSubview(dot)
        }

        animator.animate(valueLabel)
        animator.animate(titleLabel)
        
        sliceViews[slice] = (lineLayer, (titleLabel, valueLabel))
    }
    
    public func createLine(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CALayer {
        let path = UIBezierPath()
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.strokeColor = settings.lineColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.borderWidth = settings.lineWidth
        
        return layer
    }
    
    public func createLabel(slice: PieSlice, isRightSide: Bool, referencePoint: CGPoint, isTitle: Bool) -> UILabel {
        let label: UILabel
        if isTitle {
            label = settings.titleLabel.labelGenerator?(slice) ?? {
                let label = UILabel()
                label.textColor = .lightGray
                label.backgroundColor = settings.valueLabel.bgColor
                label.font = settings.valueLabel.font
                return label
                }()
            label.text = settings.titleLabel.textGenerator(slice)
        } else {
            label = settings.valueLabel.labelGenerator?(slice) ?? {
                let label = UILabel()
                label.backgroundColor = settings.valueLabel.bgColor
                label.textColor = settings.valueLabel.textColor
                label.font = settings.valueLabel.font
                return label
                }()
            label.text = settings.valueLabel.textGenerator(slice)
        }

        label.sizeToFit()
        label.frame.origin = CGPoint(x: referencePoint.x - (isRightSide ? 0 : label.frame.width) + ((isRightSide ? 1 : -1) * settings.labelXOffset), y: referencePoint.y - label.frame.height / 2 + (isTitle ? settings.labelYOffset : -settings.labelYOffset))
        
        return label
    }
    
    public func onSelected(slice: PieSlice, selected: Bool) {
        guard let (layer, label) = sliceViews[slice] else { print("Invalid state: slice not in dictionary"); return }
        
        let offset = selected ? slice.view.selectedOffset : -slice.view.selectedOffset
        UIView.animate(withDuration: 0.15) {
            label.title.center = slice.view.calculatePosition(angle: slice.view.midAngle, p: label.title.center, offset: offset)
            label.value.center = slice.view.calculatePosition(angle: slice.view.midAngle, p: label.value.center, offset: offset)
        }
        
        layer.position = slice.view.calculatePosition(angle: slice.view.midAngle, p: layer.position, offset: offset)
    }
    
    public func clear() {
        for (_, layerView) in sliceViews {
            layerView.0.removeFromSuperlayer()
            layerView.1.title.removeFromSuperview()
            layerView.1.value.removeFromSuperview()
        }
        sliceViews.removeAll()
    }
}
