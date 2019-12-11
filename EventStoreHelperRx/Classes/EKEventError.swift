//
//  EKEventError.swift
//  EventStoreHelperRx
//
//  Created by Nischal Hada on 10/12/19.
//  Copyright © 2019 Nischal Hada. All rights reserved.
//

import Foundation

public enum EKEventError: Error {
    case calendarAccessDeniedOrRestricted
    case eventNotAddedToCalendar
    case eventAlreadyExistsInCalendar
}

extension EKEventError: LocalizedError {
    /// A localized message describing what error occurred.
    /// Also the title in alert view errors in EmployeeRoster
    public var errorDescription: String? {
        switch self {
        case .calendarAccessDeniedOrRestricted:
            return L10n.accessDeniedOrRestrictedTitle
        case .eventNotAddedToCalendar:
            return L10n.eventNotAddedToCalendarTitle
        case .eventAlreadyExistsInCalendar:
            return L10n.eventAlreadyExistsInCalendarTitle
        }
    }

    /// A localized message describing how one might recover from the failure.
    /// Also the message in alert view errors in EmployeeRoster
    public var recoverySuggestion: String? {
        switch self {
        case .calendarAccessDeniedOrRestricted:
            return L10n.accessDeniedOrRestrictedBody
        case .eventNotAddedToCalendar:
            return L10n.eventNotAddedToCalendarBody
        case .eventAlreadyExistsInCalendar:
            return L10n.eventAlreadyExistsInCalendarBody
        }
    }
}
