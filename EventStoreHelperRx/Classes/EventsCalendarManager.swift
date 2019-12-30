//
//  EventsCalendarManager.swift
//  EventStoreHelperRx
//
//  Created by Nischal Hada on 10/12/19.
//  Copyright © 2019 Nischal Hada. All rights reserved.
//

import UIKit
import EventKitUI
import RxSwift

public enum EventsCalendarStatus: Equatable {
    case added
    case denied
    case error(EKEventError)
}

public protocol EventsCalendarManagerDataSource {
    func addEventToCalendar(event: EventsModel) -> Single<EventsCalendarStatus>
    func presentCalendarModalToAddEvent(event: EventsModel) -> Single<EventsCalendarStatus>
}

public final class EventsCalendarManager: NSObject, EventsCalendarManagerDataSource {

    private var eventStore: EKEventStore!
    private var eventHelper: EKEventHelperDataSource!

    public init(withEKEventHelper eventHelper: EKEventHelperDataSource = EKEventHelper(),
                withEventStore eventStore: EKEventStore = EKEventStore()) {
        self.eventHelper = eventHelper
        self.eventStore = eventStore
    }

    // Check Calendar permissions auth status
    // Try to add an event to the calendar if authorized
    public func addEventToCalendar(event: EventsModel) -> Single<EventsCalendarStatus> {
        return self.eventHelper
            .authorizationStatus
            .flatMap { authStatus -> Single<EventsCalendarStatus> in
                switch authStatus {
                case .authorized:
                    return self.addEvent(event: event)
                case .notDetermined:
                    //Authorization is not determined
                    //We should request access to the calendar
                    return self.eventHelper
                        .requestAccess
                        .flatMap { status -> Single<EventsCalendarStatus> in
                            if status {
                                return self.addEvent(event: event)
                            }
                            return Single.just(EventsCalendarStatus.denied)
                    }
                case .denied, .restricted:
                    return Single.just(EventsCalendarStatus.denied)
                }
        }
    }

    // Try to save an event to the calendar
    private func addEvent(event: EventsModel) -> Single<EventsCalendarStatus> {
        return Single<EventsCalendarStatus>.create { single in
            let eventToAdd = self.generateEvent(event: event)
            if !self.eventAlreadyExists(event: eventToAdd) {
                do {
                    try self.eventStore.save(eventToAdd, span: .thisEvent)
                } catch {
                    // Error while trying to create event in calendar
                    single(.error(EKEventError.eventNotAddedToCalendar))
                }
                single(.success(.added))
            } else {
                single(.error(EKEventError.eventAlreadyExistsInCalendar))
            }
            return Disposables.create {}
        }
    }

    // Generate an event which will be then added to the calendar
    private func generateEvent(event: EventsModel) -> EKEvent {
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        newEvent.title = event.title
        newEvent.startDate = event.startDate
        newEvent.endDate = event.endDate
        newEvent.notes = event.notes
        // Set default alarm minutes before event
        let alarm = EKAlarm(relativeOffset: TimeInterval(event.alarmMinutesBefore*60))
        newEvent.addAlarm(alarm)
        return newEvent
    }

    // Check if the event was already added to the calendar
    private func eventAlreadyExists(event eventToAdd: EKEvent) -> Bool {
        let predicate = eventStore.predicateForEvents(withStart: eventToAdd.startDate, end: eventToAdd.endDate, calendars: nil)
        let existingEvents = eventStore.events(matching: predicate)

        let eventAlreadyExists = existingEvents.contains { (event) -> Bool in
            return eventToAdd.title == event.title && event.startDate == eventToAdd.startDate && event.endDate == eventToAdd.endDate
        }
        return eventAlreadyExists
    }

    // Show EventKit to add event to calendar
    public func presentCalendarModalToAddEvent(event: EventsModel) -> Single<EventsCalendarStatus> {
        return self.eventHelper
            .authorizationStatus
            .flatMap { authStatus -> Single<EventsCalendarStatus> in
                switch authStatus {
                case .authorized:
                    return self.presentEventCalendarDetailModal(event: event)
                case .notDetermined:
                    //AuthorizationStatus is not determined
                    //We should request access to the calendar
                    return self.eventHelper
                        .requestAccess
                        .observeOn(MainScheduler.instance)
                        .flatMap { status -> Single<EventsCalendarStatus>  in
                            if status {
                                return self.presentEventCalendarDetailModal(event: event)
                            }
                            return Single.just(EventsCalendarStatus.denied)
                    }
                case .denied, .restricted:
                    return Single.just(EventsCalendarStatus.denied)
                }
        }
    }

    // Present edit event calendar modal
    private func presentEventCalendarDetailModal(event: EventsModel) -> Single<EventsCalendarStatus> {
        return Single<EventsCalendarStatus>.create { single in
            let event = self.generateEvent(event: event)
            let eventModalVC = EKEventEditViewController()
            eventModalVC.event = event
            eventModalVC.eventStore = self.eventStore
            eventModalVC.editViewDelegate = self
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
                single(.error(EKEventError.eventNotAddedToCalendar))
                return Disposables.create {}
            }
            rootVC.present(eventModalVC, animated: true, completion: nil)
            single(.success(.added))
            return Disposables.create {}
        }
    }
}

// EKEventEditViewDelegate
extension EventsCalendarManager: EKEventEditViewDelegate {
    public func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true, completion: nil)
    }
}
