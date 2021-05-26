//
//  MicrobitUtils.swift
//  Microbit
//
//
//  Copyright © 2021 Masashi Umezawa. All rights reserved.
//

import Foundation

public func p(_ items: Any...) {
    #if DEBUG
    Swift.print(items)
    #endif
}
