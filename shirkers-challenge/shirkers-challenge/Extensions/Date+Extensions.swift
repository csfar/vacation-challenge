//
//  Date+Extensions.swift
//  shirkers-challenge
//
//  Created by Artur Carneiro on 12/10/20.
//  Copyright © 2020 Artur Carneiro. All rights reserved.
//

import Foundation

extension Date {
    func toBeSavedFormat(as format: String = "yyyy-MM-dd+HH-mm-ss") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

    func toBeDisplayedFormat() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        return dateFormatter.string(from: self)
    }
}
