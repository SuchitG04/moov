//
//  BreakSession.swift
//  Moov
//
//  Model for tracking break sessions using SwiftData
//

import Foundation
import SwiftData

@Model
class BreakSession {
    var id: UUID
    var timestamp: Date
    var type: String // "micro" or "regular"
    var action: String // "taken", "snoozed", "dismissed"
    var snoozeDuration: TimeInterval?

    init(type: String = "regular", action: String, snoozeDuration: TimeInterval? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.action = action
        self.snoozeDuration = snoozeDuration
    }

    // Computed properties for convenience
    var wasTaken: Bool {
        action == "taken"
    }

    var wasSnoozed: Bool {
        action == "snoozed"
    }

    var wasDismissed: Bool {
        action == "dismissed"
    }
}
