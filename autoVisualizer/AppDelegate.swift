//
//  AppDelegate.swift
//  autoVisualizer
//
//  Created by kehwaweng on 2019/4/2.
//  Copyright © 2019 kehwaweng. All rights reserved.
//

import Cocoa
import IPEVOCameraKitOSX
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        ICCamerasManager.shared().startMonitoring()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

