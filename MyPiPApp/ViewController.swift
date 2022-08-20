//
//  ViewController.swift
//  MyPiPApp
//
//  Created by Horizon on 13/08/2022.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {

    
    // MARK: - properties
    
    
    // MARK: - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    
    // MARK: - init
    
    
    // MARK: - utils
    /// 获取播放的资源
    fileprivate func playerResource() -> AVQueuePlayer? {
        guard let videoURL = Bundle.main.url(forResource: "suancaidegang", withExtension: "mp4") else {
          return nil
        }

        let item = AVPlayerItem(url: videoURL)
        let player = AVQueuePlayer(playerItem: item)

        player.actionAtItemEnd = .pause
        return player
    }
    
    fileprivate func restore(playerVC: UIViewController, completionHandler: @escaping (Bool) -> Void) {
        if let presentedVC = presentedViewController {
            // 说明当前正在播放的界面还存在
            // 先关闭界面，再弹出播放界面
            presentedVC.dismiss(animated: false) { [weak self] in
                self?.present(playerVC, animated: false) {
                    completionHandler(true)
                }
            }
        } else {
            // 直接弹出播放界面
            present(playerVC, animated: false) {
                completionHandler(true)
            }
        }
    }
    
    // MARK: - action
    
    @IBAction func systemPlayerAction(_ sender: Any) {
        guard let player = playerResource() else {
            return
        }
        let avPlayerVC = AVPlayerViewController()
        avPlayerVC.delegate = self
        avPlayerVC.player = player
        present(avPlayerVC, animated: true) {
            player.play()
        }
    }
    
    @IBAction func customPlayerAction(_ sender: Any) {
        guard let player = playerResource() else {
            return
        }
        
        let playerVC = MWCustomPlayerVC()
        playerVC.modalPresentationStyle = .fullScreen
        playerVC.delegate = self
        playerVC.player = player
        playerVC.autoDismissAtPip = true
        present(playerVC, animated: true) {
            player.play()
        }
    }
    
    @IBAction func pipTimeAction(_ sender: Any) {
        
    }
    
    @IBAction func pipTextAction(_ sender: Any) {
        guard let player = playerResource() else {
            return
        }
        
        let playerVC = MWPipWindowVC()
        playerVC.modalPresentationStyle = .fullScreen
        playerVC.delegate = self
        playerVC.player = player
        playerVC.autoDismissAtPip = true
        present(playerVC, animated: true) {
            player.play()
        }
    }
    
    
    // MARK: - other
    


}

extension ViewController: AVPlayerViewControllerDelegate {
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
        // 这里修改为返回true，即进入画中画时关闭播放界面
        return true
    }

    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        restore(playerVC: playerViewController, completionHandler: completionHandler)
    }
}

extension ViewController: CustomPlayerVCDelegate {
    func playerViewController(
      _ playerViewController: UIViewController,
      restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
      completionHandler: @escaping (Bool) -> Void) {
          restore(playerVC: playerViewController) { result in
              if let playerVC = playerViewController as? MWPipWindowVC {
                  playerVC.setupTextPlayerView(on: playerVC.view)
              }
          }
      }
}
