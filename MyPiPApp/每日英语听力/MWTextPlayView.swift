//
//  MWTextPlayView.swift
//  MyPiPApp
//
//  Created by Horizon on 16/08/2022.
//

import UIKit

class MWTextPlayView: UIView {

    // MARK: - properties
    fileprivate lazy var displayLabel: UILabel = UILabel(frame: .zero)
    var text: String? {
        didSet {
            displayLabel.text = text
        }
    }
    
    // MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSubviews()
        setupLayouts()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupSubviews() {
        backgroundColor = UIColor.black
        
        displayLabel.numberOfLines = 2
        displayLabel.font = UIFont.boldSystemFont(ofSize: 15.0)
        displayLabel.textColor = UIColor.darkGray
        addSubview(displayLabel)
    }
    
    fileprivate func setupLayouts() {
        displayLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8.0)
            make.centerY.equalToSuperview().inset(8.0)
        }
    }
    
    // MARK: - utils
    
    
    // MARK: - action
    
    
    // MARK: - other
    
}
