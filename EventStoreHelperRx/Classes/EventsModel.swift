//
//  EventsModel.swift
//  EventStoreHelperRx
//
//  Created by Nischal Hada on 10/12/19.
//  Copyright © 2019 Nischal Hada. All rights reserved.
//

import Foundation

public struct EventsModel {
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let location: String?
    public let notes: String?
    public let alarmMinutesBefore: Int
    
    public init(title: String,
                startDate: Date,
                endDate: Date,
                location: String?,
                notes: String?,
                alarmMinutesBefore: Int) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.alarmMinutesBefore = alarmMinutesBefore
    }
}
