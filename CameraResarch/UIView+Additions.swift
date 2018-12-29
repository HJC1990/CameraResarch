//
//  UIView+Additions.swift
//  CameraResarch
//
//  Created by sam on 2018/12/24.
//  Copyright © 2018年 sam. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    public var centerX: CGFloat {
        get {
            return self.center.x;
        }
        set {
            var center = self.center
            center.x = newValue
            self.center = center
        }
    }
    public var centerY: CGFloat {
        get {
            return self.center.y;
        }
        set {
            var center = self.center
            center.y = newValue
            self.center = center
        }
    }
    public var x:CGFloat {
        get {
            return self.frame.origin.x
        }
        set {
            var frame = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }
    public var y:CGFloat {
        get {
            return self.frame.origin.y
        }
        set {
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }
}
