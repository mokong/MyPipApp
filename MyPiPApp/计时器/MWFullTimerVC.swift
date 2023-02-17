//
//  MWFullTimerVC.swift
//  MyPiPApp
//
//  Created by MorganWang on 20/08/2022.
//

import UIKit
import UIPiPView
import SnapKit

class MWFullTimerVC: MWBaseVC {
    
    // MARK: - properties
    private let pipView = UIPiPView()
    private let timeLabel = UILabel()
    private let dateFormatStr = "yyyy-MM-dd HH:mm:ss"
    private var timer: Timer?

    // MARK: - view life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.black
        
        setupPipView()
        setupTimeLabel()
        createDisplayLink()
    }
    
    fileprivate func setupPipView() {
        let width = UIScreen.main.bounds.width
        pipView.frame = CGRect(x: 10.0, y: 0, width: width - 20.0, height: 50.0)
        view.addSubview(pipView)
        pipView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10.0)
            make.top.equalToSuperview().inset(100.0)
            make.height.equalTo(50.0)
        }
    }
    
    fileprivate func setupTimeLabel() {
        timeLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        timeLabel.textColor = UIColor.white
        timeLabel.backgroundColor = UIColor.orange
        timeLabel.textAlignment = .center
        pipView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalToSuperview()
        }
    }
    
    func createDisplayLink() {
        timer = Timer(timeInterval: 0.1/60, repeats: true, block: { [weak self] _ in
            self?.refresh()
        })
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
        timer?.fire()
    }

    
    // MARK: - init
    
    
    // MARK: - utils
    func reloadTime() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormatStr
        self.timeLabel.text = formatter.string(from: date)
    }

    
    // MARK: - action
    
    func refresh() {
        reloadTime()
    }
    
    override func handleEnterPipAction() {
        super.handleEnterPipAction()
        if pipView.isPictureInPictureActive() {
            pipView.stopPictureInPicture()
        } else {
            pipView.startPictureInPicture(withRefreshInterval: 0.1/60.0)
        }
    }
    
    // MARK: - other
    

    
    
}
