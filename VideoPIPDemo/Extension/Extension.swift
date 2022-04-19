//
//  Extension.swift
//  VideoPIPDemo
//
//  Created by MQI-1 on 18/04/22.
//

import Foundation
import UIKit
import AVFoundation

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
