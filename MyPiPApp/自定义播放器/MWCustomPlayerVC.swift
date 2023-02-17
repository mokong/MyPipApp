//
//  MWCustomPlayerVC.swift
//  MyPiPApp
//
//  Created by MorganWang on 15/08/2022.
//

import UIKit
import AVFoundation
import AVKit
import SnapKit

private var activeCustomPlayerVCs = Set<MWCustomPlayerVC>()

protocol CustomPlayerVCDelegate: AnyObject {
    func playerViewController(
      _ playerViewController: UIViewController,
      restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
        completionHandler: @escaping (Bool) -> Void
    )
}

class MWCustomPlayerVC: UIViewController {

    // MARK: - properties
    var player: AVPlayer? {
        didSet {
            setupAVPlayerLayer()
        }
    }
    var playerLayer: AVPlayerLayer?
    private var pictureInPictureVC: AVPictureInPictureController?
    weak var delegate: CustomPlayerVCDelegate?
    var autoDismissAtPip: Bool = false // 进入画中画时，是否自动关闭当前播放页面
    var enterPipBtn: CustomPlayerCircularButtonView?
    
    // MARK: - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = .black
        setupAVPlayerLayer()
        setupPictureInPictureVC()
        setupCloseBtn()
        setupEnterPipBtn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enterPipBtn?.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let enterPipBtn = enterPipBtn {
            view.bringSubviewToFront(enterPipBtn)
        }
    }
    
    // MARK: - init
    fileprivate func setupCloseBtn() {
        let closeBtn = UIButton(type: .custom)
        closeBtn.setImage(UIImage(named: "closeW"), for: UIControl.State.normal)
        closeBtn.addTarget(self, action: #selector(handleCloseAction(_:)), for: UIControl.Event.touchUpInside)
        view.addSubview(closeBtn)
        
        closeBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(40.0)
            make.width.height.equalTo(60.0)
            make.leading.equalToSuperview()
        }
    }
    
    fileprivate func setupAVPlayerLayer() {
        guard let player = player else {
            return
        }
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer!)
    }
    
    fileprivate func setupPictureInPictureVC() {
        guard let playerLayer = playerLayer else {
            return
        }

        pictureInPictureVC = AVPictureInPictureController(playerLayer: playerLayer)
        pictureInPictureVC?.delegate = self
    }
    
    fileprivate func setupEnterPipBtn() {
        enterPipBtn = CustomPlayerCircularButtonView(symbolName: "pip.enter", height: 50.0)
        enterPipBtn?.addTarget(self, action: #selector(handleEnterPipAction), for: [.primaryActionTriggered, .touchUpInside])
        view.addSubview(enterPipBtn!)
        
        enterPipBtn?.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(10.0)
            make.centerY.equalTo(self.view.snp.centerY)
            make.width.height.equalTo(50.0)
        }
    }
    
    // MARK: - utils
    
    // MARK: - action
    @objc
    fileprivate func handleCloseAction(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @objc
    fileprivate func handleEnterPipAction() {
        pictureInPictureVC?.startPictureInPicture()
    }
    
    // MARK: - other
    

}

extension MWCustomPlayerVC: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        activeCustomPlayerVCs.insert(self)
        enterPipBtn?.isHidden = true
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if autoDismissAtPip {
            dismiss(animated: true)
        }
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        activeCustomPlayerVCs.remove(self)
        enterPipBtn?.isHidden = false
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        delegate?.playerViewController(self, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
    }
}
