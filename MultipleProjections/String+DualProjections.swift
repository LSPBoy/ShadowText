//
//  String+DualProjections.swift
//  MultipleProjections
//
//  Created by Sun on 2023/7/12.
//

import UIKit

extension String {
    
    /// Drawing text as a image with a double projection
    /// - Parameters:
    ///   - font: The font of the text
    ///   - textColor: The text color of text
    ///   - firstLevel: The first level projection text color of text
    ///   - secondLevel: The second level projection text color of text
    /// - Returns: Dual projections image
    public func dualProjections(
        _ font: UIFont,
        textColor: UIColor,
        firstLevel: UIColor = UIColor(red: 0.890, green: 0.337, blue: 0.635, alpha: 1.0),
        secondLevel: UIColor = UIColor(red: 0.000, green: 0.003, blue: 0.329, alpha: 1.0)
    ) -> UIImage? {
        
        // Calculate the size required for text
        let size = self.size(withAttributes: [.font: font])
        
//        let blurRadius = font.pointSize * 0.034
        let firstOffset = CGPoint(x: font.pointSize * 0.067, y: font.pointSize * 0.084)
        let secondOffset = CGPoint(x: font.pointSize * 0.189, y: font.pointSize * 0.189)
        
        // Increase the size of the canvas on which the drawing will be done,
        // since we will be drawing a double projection,
        // we will need extra space for the first and second level projections.
        let expectedSize = CGSize(
            width: size.width + font.pointSize * 0.3,
            height: size.height + font.pointSize * 0.3
        )
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIApplication.shared.delegate?.window??.windowScene?.screen.scale ?? 1.0
        format.opaque = false
        let render = UIGraphicsImageRenderer(size: expectedSize, format: format)
        let image = render.image { ctx in
            
            let context = ctx.cgContext
            
            context.translateBy(x: 0, y: expectedSize.height)
            context.scaleBy(x: 1.0, y: -1.0)

            let attributedText = NSAttributedString(string: self, attributes: [.font: font])
            let line = CTLineCreateWithAttributedString(attributedText)
            let runArray = CTLineGetGlyphRuns(line)

            for runIndex in 0..<CFArrayGetCount(runArray) {
                let run = unsafeBitCast(CFArrayGetValueAtIndex(runArray, runIndex), to: CTRun.self)
                guard let attributes = CTRunGetAttributes(run) as? [AnyHashable: Any],
                      // swiftlint:disable:next force_cast
                      let runFont = attributes[kCTFontAttributeName as String] as! CTFont? else {
                    continue
                }
                
                let glyphCount = CTRunGetGlyphCount(run)
                for glyphIndex in 0..<glyphCount {
                    let range = CFRangeMake(glyphIndex, 1)
                    var glyph: CGGlyph = CGGlyph()
                    var position: CGPoint = .zero
                    
                    CTRunGetGlyphs(run, range, &glyph)
                    CTRunGetPositions(run, range, &position)
                    
                    guard let path = CTFontCreatePathForGlyph(runFont, glyph, nil) else {
                        continue
                    }
                    
                    context.translateBy(x: position.x, y: position.y)
                    // Reverse plotting based on layers
                    do {
                        // Second level projection
                        context.saveGState()
                        context.translateBy(x: secondOffset.x, y: secondOffset.y)
                        context.setShouldAntialias(false) // Actively reflect edge burrs
                        context.setShouldSmoothFonts(false)
                        context.addPath(path)
                        context.setShadow(offset: CGSize(width: 2, height: 2), blur: 4, color: secondLevel.cgColor)
                        context.setFillColor(secondLevel.cgColor)
                        context.fillPath()
                        context.restoreGState()
                    }

                    do {
                        // First level projection
                        context.saveGState()
                        context.translateBy(x: firstOffset.x, y: secondOffset.y + firstOffset.y)
                        context.setShouldAntialias(false) // Actively reflect edge burrs
                        context.setShouldSmoothFonts(false)
                        let newPath = self.fixConnectionPoint(from: path)
                        context.addPath(newPath)

                        context.setShadow(offset: CGSize(width: 2, height: 2), blur: 2, color: firstLevel.cgColor)
                        context.setFillColor(firstLevel.cgColor)
                        context.fillPath()
                        context.restoreGState()
                    }

                    do {
                        // Draw the front text
                        context.saveGState()
                        context.translateBy(x: 0, y: secondOffset.y + firstOffset.y * 2)
                        context.setShouldAntialias(false) // Actively reflect edge burrs
                        context.setShouldSmoothFonts(false)
                        context.addPath(path)
                        context.setShadow(offset: CGSize(width: 2, height: 2), blur: 2, color: textColor.cgColor)
                        context.setFillColor(textColor.cgColor)
                        context.fillPath()
                        context.restoreGState()
                    }
                    context.translateBy(x: -position.x, y: -position.y)
                }
            }
            
            // Reverse plotting based on layers
//            cgContext.saveGState()
//            cgContext.setShouldAntialias(false) // Actively reflect edge burrs
//            cgContext.setShouldSmoothFonts(false)
//            cgContext.setTextDrawingMode(.fill)
//            defer {
//                cgContext.restoreGState()
//            }
//            cgContext.setShadow(offset: .zero, blur: blurRadius, color: UIColor.black.cgColor)
//            do {
//                // Second level projection
//                cgContext.saveGState()
//                cgContext.setShouldAntialias(false) // Actively reflect edge burrs
//                cgContext.setShouldSmoothFonts(false)
//                cgContext.setTextDrawingMode(.fill)
//                defer {
//                    cgContext.restoreGState()
//                }
//                cgContext.setShadow(offset: .zero, blur: blurRadius, color: secondLevel.cgColor)
//                self.draw(at: secondOffset, withAttributes: [.font: font, .foregroundColor: secondLevel])
//            }
//            do {
//                // First level projection
//                self.draw(at: firstOffset, withAttributes: [.font: font, .foregroundColor: firstLevel])
//                let cgPath = CGMutablePath()
//                cgPath.move(to: firstOffset)
//                cgPath
//                cgContext.addPath(cgPath)
//            }
//            do {
//                // Draw the front text
//                self.draw(at: .zero, withAttributes: [.font: font, .foregroundColor: textColor])
//            }
        }
        return image
    }
    
    private func fixConnectionPoint(from path: CGPath) -> CGPath {
        let newPath = CGMutablePath()
        path.applyWithBlock { element in
            // TODO: - 实现链接点的绘制
            switch element.pointee.type {
            case .moveToPoint:
                newPath.move(to: element.pointee.points[0])
                
            case .addLineToPoint:
                newPath.addLine(to: element.pointee.points[0])
              
            case .addQuadCurveToPoint:
                let controlPoint = element.pointee.points[0]
                let endPoint = element.pointee.points[1]
                newPath.addQuadCurve(to: endPoint, control: controlPoint)
              
            case .addCurveToPoint:
                let controlPoint1 = element.pointee.points[0]
                let controlPoint2 = element.pointee.points[1]
                let endPoint = element.pointee.points[2]
                newPath.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
         
            case .closeSubpath:
                newPath.closeSubpath()
                
            @unknown default:
                break
            }
        }
        return newPath
    }

}
