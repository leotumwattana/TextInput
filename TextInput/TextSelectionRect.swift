//
//  TextSelectionRect.swift
//  TextInput
//
//  Created by Ziqiao Chen on 9/11/20.
//

import UIKit

class TextSelectionRect: UITextSelectionRect {
    
    var selectionRect: CGRect
    var rectContainsStart: Bool
    var rectContainsEnd: Bool
    
    init(rect: CGRect, containsStart: Bool = false, containsEnd: Bool = false) {
        selectionRect = rect
        rectContainsStart = containsStart
        rectContainsEnd = containsEnd
    }
    
    override var writingDirection: NSWritingDirection {
      return .leftToRight
    }
    
    override var isVertical: Bool {
      return false
    }
    
    override var rect: CGRect {
      return selectionRect
    }
    
    override var containsStart: Bool {
      return rectContainsStart
    }
    
    override var containsEnd: Bool {
      return rectContainsEnd
    }
    
    override var description: String {
        return "[\(rect))"
    }
}
