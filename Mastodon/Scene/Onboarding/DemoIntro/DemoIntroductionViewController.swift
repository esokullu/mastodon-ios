// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import UIKit
import AVKit
import AVFoundation

final class DemoIntroductionViewController: UIViewController {
    
    private var player: AVPlayer?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.backgroundColor = .clear
        if ConfigureSettings.Introduction.shouldShowDemoIntroKey {
            playVideo()
        } else {
            self.dismiss(animated: true)
        }
     }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
     private func playVideo() {
         guard let path = Bundle.main.path(forResource: "demo", ofType:"mp4") else {
            return
         }
         player = AVPlayer(url: URL(fileURLWithPath: path))
         let playerController = AVPlayerViewController()
         playerController.player = player
         present(playerController, animated: false) {
             self.player?.play()
         }
         
         ConfigureSettings.Introduction.shouldShowDemoIntroKey = false
     }
}
