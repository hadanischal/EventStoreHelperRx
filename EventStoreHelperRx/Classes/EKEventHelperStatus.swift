//
//  EKEventHelperStatus.swift
//  EventStoreHelperRx
//
//  Created by Nischal Hada on 10/12/19.
//  Copyright © 2019 Nischal Hada. All rights reserved.
//

import Foundation

public enum EKEventHelperStatus {
    case notDetermined // The user has not yet made a choice regarding whether this application may access the service.
    case restricted //This application is not authorized to access the service. The user cannot change this application’s status, possibly due to active restrictions such as parental controls being in place.
    case denied //The user explicitly denied access to the service for this application.
    case authorized //This application is authorized to access the service.
}
