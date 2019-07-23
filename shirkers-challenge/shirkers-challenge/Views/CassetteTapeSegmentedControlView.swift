//
//  CassetteTapeSegmentedControlView.swift
//  shirkers-challenge
//
//  Created by Artur Carneiro on 23/07/19.
//  Copyright © 2019 Artur Carneiro. All rights reserved.
//

import UIKit

class CassetteTapeSegmentedControlView: UISegmentedControl {
    
    override init(items: [Any]?) {
        super.init(items: items)
        self.selectedSegmentIndex = 0
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 3
        self.setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: Fonts.main, size: 17)], for: .normal)
        self.layer.borderColor = ColorPalette.grey.cgColor
        self.tintColor = ColorPalette.grey
        self.backgroundColor = .clear
        self.clipsToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
