//
//  AppDelegate.swift
//  CustomAVPlayer
//
//  Created by Poonam on 23/07/22.
//

import UIKit
import AVKit


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window:UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let session = AVAudioSession.sharedInstance()
         do {
              try session.setCategory(.playback, mode: .moviePlayback)
            } catch let err {
               print(err.localizedDescription)
            }
        return true
    }

}

