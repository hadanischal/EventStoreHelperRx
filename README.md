# EventStoreHelperRx

![Swift](https://img.shields.io/badge/Swift-5.1.2-orange.svg)
[![CI Status](https://img.shields.io/travis/hadanischal@gmail.com/EventStoreHelperRx.svg?style=flat)](https://travis-ci.org/hadanischal@gmail.com/EventStoreHelperRx)
[![Version](https://img.shields.io/cocoapods/v/EventStoreHelperRx.svg?style=flat)](https://cocoapods.org/pods/EventStoreHelperRx)
[![License](https://img.shields.io/cocoapods/l/EventStoreHelperRx.svg?style=flat)](https://cocoapods.org/pods/EventStoreHelperRx)
[![Platform](https://img.shields.io/cocoapods/p/EventStoreHelperRx.svg?style=flat)](https://cocoapods.org/pods/EventStoreHelperRx)

## Requirements
* iOS 12.0+
* Xcode 11.0+
```ruby
    pod 'RxSwift', '~> 5'
    pod 'RxCocoa', '~> 5'
```

## Installation
### Cocoapods

EventStoreHelperRx is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'EventStoreHelperRx'
```


Then, run the following command:

```bash
$ pod install
```

## Usage

### Swift

1. Model:
```swift
import Foundation
import EventStoreHelperRx

extension EventsModel {
     init?(withRosterModel rosterModel: RosterModel) {
        guard let name = rosterModel.name,
            let fromDate = rosterModel.fromDate?.yyyyMMddDate,
            let toDate = rosterModel.toDate?.yyyyMMddDate else {
                return nil
        }
        self.init(title: "\(name) on Roster",
            startDate: fromDate,
            endDate: toDate,
            location: nil,
            notes: nil,
            alarmMinutesBefore: 30)
    }
}

extension EventsModel {
    init?(withScheduleModel scheduleModel: ScheduleModel) {
        guard let name = scheduleModel.name,
            let fromDate = scheduleModel.fromDate?.yyyyMMddDate,
            let toDate = scheduleModel.toDate?.yyyyMMddDate else {
                return nil
        }
        self.init(title: "\(name) on Roster",
               startDate: fromDate,
               endDate: toDate,
               location: nil,
               notes: nil,
               alarmMinutesBefore: 30)
    }
}

```


2. Add Event:

```swift

import Foundation
import RxSwift
import CocoaLumberjack
import EventStoreHelperRx

enum AddEventRoute {
    case eventAdded(String, String)
    case openSettings(String, String)
    case errorResult(Error)
}
    // Check Calendar permissions auth status
    // Try to add an event to the calendar if authorized
    func addEventToCalendar(withRosterModel rosterModel: RosterModel) -> Observable<AddEventRoute> {

        guard let event = EventsModel(withRosterModel: rosterModel) else { return Observable.empty() }

        return self.eventsCalendarManager
            .addEventToCalendar(event: event)
            //            .presentCalendarModalToAddEvent(event: event)
            .asObservable()
            .catchError({ (error) -> Observable<EventsCalendarStatus> in
                return Observable.just(EventsCalendarStatus.error(error as? EKEventError ?? EKEventError.eventNotAddedToCalendar))
            })
            .flatMap({ calendarStatus -> Observable<AddEventRoute> in
                switch calendarStatus {
                case .added:
                    let result = ("Event added to Calendar", "Event added to Calendar completed")
                    return Observable.just(AddEventRoute.eventAdded(result.0, result.1))

                case .denied:
                    let appName = Bundle.main.displayName ?? "This app"
                    let result = ("This feature requires calender access", "In iPhone settings, tap \(appName) and turn on calender access")
                    return Observable.just(AddEventRoute.openSettings(result.0, result.1))

                case .error(let error):
                    return Observable.just(AddEventRoute.errorResult(error))
                }
            })
    }
```

3. Make sure to import EventStoreHelperRx `import EventStoreHelperRx`:

```swift

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
```

## Contributing

As the creators, and maintainers of this project, we're glad to invite contributors to help us stay up to date. Please take a moment to review [the contributing document](CONTRIBUTING.md) in order to make the contribution process easy and effective for everyone involved.

- If you **found a bug**, open an [issue](https://github.com/hadanischal/EventStoreHelperRx/issues).
- If you **have a feature request**, open an [issue](https://github.com/hadanischal/EventStoreHelperRx/issues).
- If you **want to contribute**, submit a [pull request](https://github.com/hadanischal/EventStoreHelperRx/pulls).

<br>

## Example Project

* [EmployeeRoster](https://github.com/hadanischal/EmployeeRoster): A simple example project which implement EventStoreHelperRx

## Author

hadanischal@gmail.com, hadanischal@gmail.com

## License

**EventStoreHelperRx** is available under the MIT license. See the [LICENSE](https://github.com/hadanischal/EventStoreHelperRx/blob/master/LICENSE) file for more info.

