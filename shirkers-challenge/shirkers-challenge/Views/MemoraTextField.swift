//
//  MemoraTextField.swift
//  shirkers-challenge
//
//  Created by Artur Carneiro on 09/10/20.
//  Copyright © 2020 Artur Carneiro. All rights reserved.
//

import UIKit

final class MemoraTextField: UITextField {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUp() {
        font = UIFont.preferredFont(forTextStyle: .title2).bold()
        tintColor = .memoraLightGray
        textColor = .memoraLightGray
        textAlignment = .natural
        placeholder = "Memory's title"
    }
}