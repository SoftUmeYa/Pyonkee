//
//  SUYToast.swift
//  Scratch
//
//  Created by Masashi Umezawa on 2020/03/16.
//

import Toast
import UIKit

class SUYToast: NSObject {
    // MARK: - Toast
    
    @objc public class func showToast(message:String, image: UIImage, title: String = "", duration: TimeInterval = 0.5) {
        guard let view = UIApplication.shared.keyWindow?.rootViewController?.view else { return }
        self.showToastOn(view: view, message: message, image: image, title: title, duration: duration)
    }
    
    @objc public class func showToastOn(view: UIView, message:String, image: UIImage, title: String, duration: TimeInterval) {
        view.makeToast(message, duration: duration, position: .center, title: title, image: image, style: ToastManager.shared.style, completion: nil)
    }
    
    @objc public class func showActivityToastOn(view: UIView) {
        view.makeToastActivity(.center)
    }
    
    @objc public class func hideActivityToastOn(view: UIView) {
        view.hideToastActivity()
    }
}
