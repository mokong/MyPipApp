//
//  MWPipWindowVC.swift
//  MyPiPApp
//
//  Created by Horizon on 15/08/2022.
//

import UIKit
import AVKit

private var activeCustomPlayerVCs = Set<MWPipWindowVC>()

class MWPipWindowVC: UIViewController {

    
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

    fileprivate lazy var textPlayView = MWTextPlayView(frame: .zero)
    fileprivate var timer: Timer?
    fileprivate var count: Int = 0
    
    fileprivate let text1 = """
        In 2014, I began my search for a software engineering job in Tokyo. But I didn't want just any old job.
"""
    fileprivate let text2 = """
         I wanted one that was — for lack of a better term — actually good. Because I'd heard some scary stuff about Japan's tech industry.
"""
    fileprivate let text3 = """
          Tales of overwork. Low wages. The dreaded Japanese "black company". But despite all those stories, I believed there were good tech companies
"""
    fileprivate let text4 = """
           So I set out to find them. 8 years later, my wife and I run Japan Dev. It's a job board focused on that same mission: Helping people find tech jobs at great companies in Japan.
"""
    fileprivate let text5 = """
        Last month, our ultra-niche job board earned $62,197 in revenue. Here's the story.
"""
    
    // MARK: - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .black
        
        setupSubviews()
    }

    
    // MARK: - init
    fileprivate func setupSubviews() {
        setupAVPlayerLayer()
        setupPictureInPictureVC()
        setupCloseBtn()
        setupEnterPipBtn()
        setupTextPlayerView(on: view)
        setupTimer()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enterPipBtn?.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let enterPipBtn = enterPipBtn {
            view.bringSubviewToFront(textPlayView)
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
    
    func setupTextPlayerView(on targetView: UIView) {
        targetView.addSubview(textPlayView)
        textPlayView.text = text1
        
        textPlayView.snp.makeConstraints { make in
            make.centerY.equalTo(targetView.snp.centerY)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(250.0)
        }
    }
    
    fileprivate func setupTimer() {
        timer = Timer(timeInterval: 2.0, repeats: true, block: { [weak self] _ in
            self?.handleTimerAction()
        })
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
        timer?.fire()
    }

    // MARK: - utils
    
    // MARK: - action
    func handleTimerAction() {
        let dataList = [text1, text2, text3, text4, text5]
        count += 1
        let index = count % 5
        let str = dataList[index]
        textPlayView.text = str
    }
    
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

extension MWPipWindowVC: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        activeCustomPlayerVCs.insert(self)
        enterPipBtn?.isHidden = true
        if let window = UIApplication.shared.windows.first {
            setupTextPlayerView(on: window)
        }
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
