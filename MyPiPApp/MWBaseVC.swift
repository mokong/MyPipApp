//
//  MWBaseVC.swift
//  MyPiPApp
//
//  Created by Horizon on 20/08/2022.
//

import UIKit

class MWBaseVC: UIViewController {

    // MARK: - properties
    var enterPipBtn: CustomPlayerCircularButtonView?

    // MARK: - view life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        setupCloseBtn()
        setupEnterPipBtn()
    }
    
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

    
    // MARK: - init
    
    
    // MARK: - utils

    
    // MARK: - action
    
    @objc
    fileprivate func handleCloseAction(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @objc
    func handleEnterPipAction() {

    }

    
    // MARK: - other
    

    

}
