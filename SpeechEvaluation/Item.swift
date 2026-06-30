//
//  Item.swift
//  SpeechEvaluation
//
//  Created by 59 BGCC Loan Library on 6/30/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
