//
//  EKEventHelper.swift
//  EventStoreHelperRx
//
//  Created by Nischal Hada on 10/12/19.
//  Copyright © 2019 Nischal Hada. All rights reserved.
//

import Foundation
import RxSwift
import EventKit

public protocol EKEventHelperDataSource {
    var authorizationStatus: Single<EKEventHelperStatus> { get }
    var requestAccess: Single<Bool> { get }
}

public struct EKEventHelper: EKEventHelperDataSource {

    private var eventStore: EKEventStore!

    public init(withEKEventStore eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    // Get Calendar auth status
    public var authorizationStatus: Single<EKEventHelperStatus> {
        return Single<EKEventHelperStatus>.create { single in
            let authStatus = self.getAuthorizationStatus()
            switch authStatus {
            case .notDetermined:
                single(.success(.notDetermined))
            case .authorized:
                single(.success(.authorized))
            case .restricted:
                single(.success(.restricted))
            case .denied:
                single(.success( .denied))
            @unknown default:
                single(.error(RxError.unknown))
                fatalError("EKEventStore.authorizationStatus() is not available on this version of OS.")
            }
            return Disposables.create()
        }
    }

    // Request access to the Calendar
    public var requestAccess: Single<Bool> {
        return Single<Bool>.create { single in
            self.eventStore.requestAccess(to: EKEntityType.event) { (authorizationStatus, error) in
                if let error = error {
                    single(.error(error))
                }
                single(.success(authorizationStatus))
            }
            return Disposables.create()
        }
    }

    // Get Calendar auth status
    private func getAuthorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: EKEntityType.event)
    }
}
