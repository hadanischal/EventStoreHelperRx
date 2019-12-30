//
//  Formatters.swift
//  EventStoreHelperRxTests
//
//  Created by Nischal Hada on 30/12/19.
//  Copyright © 2019 Nischal Hada. All rights reserved.
//

import Foundation

public class Formatters {

    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    public static var yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
