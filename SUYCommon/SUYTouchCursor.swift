//
//  SUYTouchCursor.swift
//  ScratchOnIPad
//
//  Created by Masashi Umezawa on 2017/09/04.
//
//

import TouchVisualizer
import ToastSwiftFramework
import UIKit

class SUYTouchCursor: NSObject {
    
    static let EyeDropperConfig: Configuration = createEyeDropperConfig()
    static var IsEnabled = false;
    
    private class func createEyeDropperConfig() -> Configuration {
        var config = Configuration()
        let image = UIImage(named: "eyeDropper")
        config.image = SUYUtils.offsetImage(image, transposed: CGRect(x:30,y:30,width:100,height:100), offset: CGPoint(x:128, y:128), size: CGSize(width:256, height:256))
        config.showsTouchRadius = false
        config.defaultSize = CGSize(width:120, height:120)
        return config
    }
    
    public class func showEyeDropper() {
        if(IsEnabled){return}
        showToast(message: "", image: UIImage(named: "eyeDropper")!)
        show(EyeDropperConfig)
    }
    
    public class func show(_ config: Configuration) {
        UIApplication.shared.keyWindow?.swizzle()
        Visualizer.start(config)
        IsEnabled = true;
    }
    
    public class func hide() {
        //To detect Visualizer bug
        //for window in UIApplication.shared.windows {print(window)}
        Visualizer.stop()
        IsEnabled = false;
    }
    
    private class func showToast(message:String, image: UIImage) {
        let view = UIApplication.shared.keyWindow?.rootViewController?.view
        view?.makeToast(message, duration: 0.5, position: .center, title: "", image: image, style: ToastManager.shared.style, completion: nil)
    }
}
