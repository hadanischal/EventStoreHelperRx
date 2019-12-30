//
//  EventsCalendarManagerTests.swift
//  EventStoreHelperRxTests
//
//  Created by Nischal Hada on 9/12/19.
//  Copyright © 2019 Nischal Hada. All rights reserved.
//

import XCTest
import Quick
import Nimble
import Cuckoo
import RxTest
import RxBlocking
import RxSwift
import EventKitUI

@testable import EventStoreHelperRx

class EventsCalendarManagerTests: QuickSpec {

    override func spec() {
        var testRequest: EventsCalendarManager!
        var mockEKEventHelper: MockEKEventHelperDataSource!
        var mockEKEventStore: MockEKEventStore!

        let mockStartDate = Formatters.yyyyMMdd.date(from: "2020-10-19")!
        let mockEndDate = Formatters.yyyyMMdd.date(from: "2020-11-25")!

        let eventsModel = EventsModel(title: "Alice and Bob",
                                      startDate: mockStartDate,
                                      endDate: mockEndDate,
                                      location: nil,
                                      notes: nil,
                                      alarmMinutesBefore: 50)
        var testScheduler: TestScheduler!

        describe("EventsCalendarManager") {
            beforeEach {
                testScheduler = TestScheduler(initialClock: 0)

                mockEKEventHelper = MockEKEventHelperDataSource()
                stub(mockEKEventHelper, block: { stub in
                    when(stub.authorizationStatus).get.thenReturn(Single.just(.authorized))
                    when(stub.requestAccess).get.thenReturn(Single.just(true))
                })

                mockEKEventStore = MockEKEventStore()
                let mockEKCalendar = EKCalendar(for: .event, eventStore: mockEKEventStore)

                stub(mockEKEventStore) { (stub) in
                    when(stub).requestAccess(to: any(), completion: any()).thenDoNothing()
                    when(stub).predicateForEvents(withStart: any(), end: any(), calendars: any()).thenReturn(NSPredicate())
                    when(stub).events(matching: any()).thenReturn([])
                    when(stub).save(any(), span: any()).thenDoNothing()
                    when(stub).defaultCalendarForNewEvents.get.thenReturn(mockEKCalendar)
                }

                testRequest = EventsCalendarManager(withEKEventHelper: mockEKEventHelper, withEventStore: mockEKEventStore)
            }

            describe("When add Event To Calendar", {

                context("when authorizationStatus is denied", {
                    var result: [EventsCalendarStatus]?
                    beforeEach {
                        stub(mockEKEventHelper, block: { stub in
                            when(stub.authorizationStatus).get.thenReturn(Single.just(.denied))
                        })
                        stub(mockEKEventStore) { (stub) in
                            when(stub).requestAccess(to: any(), completion: any()).thenDoNothing()
                        }
                        result = try? testRequest.addEventToCalendar(event: eventsModel).toBlocking(timeout: 3).toArray()
                    }
                    it("it failed with error calendarAccessDeniedOrRestricted", closure: {
                        expect(result?.count).to(equal(1))
                        expect(result?.first).to(equal(EventsCalendarStatus.denied))
                    })
                    it("calls to the mockEKEventHelper for authorizationStatus", closure: {
                        verify(mockEKEventHelper).authorizationStatus.get()
                    })
                })

                context("when authorizationStatus is restricted", {
                    var result: [EventsCalendarStatus]?
                    beforeEach {
                        stub(mockEKEventHelper, block: { stub in
                            when(stub.authorizationStatus).get.thenReturn(Single.just(.restricted))
                        })

                        stub(mockEKEventStore) { (stub) in
                            when(stub).requestAccess(to: any(), completion: any()).thenDoNothing()
                        }
                        result = try? testRequest.addEventToCalendar(event: eventsModel).toBlocking(timeout: 3).toArray()
                    }
                    it("it failed with error calendarAccessDeniedOrRestricted", closure: {
                        expect(result?.count).to(equal(1))
                        expect(result?.first).to(equal(EventsCalendarStatus.denied))
                    })
                    it("calls to the mockEKEventHelper for authorizationStatus", closure: {
                        verify(mockEKEventHelper).authorizationStatus.get()
                    })
                })

                context("when authorizationStatus is authorized", {
                    var result: [EventsCalendarStatus]?
                    beforeEach {
                        stub(mockEKEventHelper, block: { stub in
                            when(stub.authorizationStatus).get.thenReturn(Single.just(.authorized))
                        })

                        stub(mockEKEventStore) { (stub) in
                            when(stub).requestAccess(to: any(), completion: any()).thenDoNothing()
                            when(stub).save(any(), span: any()).thenDoNothing()
                        }
                        result = try? testRequest.addEventToCalendar(event: eventsModel).toBlocking(timeout: 3).toArray()
                    }
                    it("it failed with error calendarAccessDeniedOrRestricted", closure: {
                        expect(result?.count).to(equal(1))
                        expect(result?.first).to(equal(EventsCalendarStatus.added))
                    })
                    it("calls to the mockEKEventHelper for authorizationStatus", closure: {
                        verify(mockEKEventHelper).authorizationStatus.get()
                    })
                    it("calls to the mockEKEventStore for predicateForEvents", closure: {
                        verify(mockEKEventStore).predicateForEvents(withStart: any(), end: any(), calendars: any())
                    })
                    it("calls to the mockEKEventStore for events matching event", closure: {
                        verify(mockEKEventStore).events(matching: any())
                    })
                    it("calls to the mockEKEventStore for save event", closure: {
                        verify(mockEKEventStore).save(any(), span: any())
                    })
                })

                context("when eventAlreadyExists", {
                    beforeEach {
                        stub(mockEKEventHelper, block: { stub in
                            when(stub.authorizationStatus).get.thenReturn(Single.just(.authorized))
                        })

                        let mockEvent = EKEvent(eventStore: mockEKEventStore)

                        mockEvent.calendar = mockEKEventStore.defaultCalendarForNewEvents
                        mockEvent.title = eventsModel.title
                        mockEvent.startDate = eventsModel.startDate
                        mockEvent.endDate = eventsModel.endDate
                        mockEvent.notes = eventsModel.notes
                        // Set default alarm minutes before event
                        let alarm = EKAlarm(relativeOffset: TimeInterval(eventsModel.alarmMinutesBefore*60))
                        mockEvent.addAlarm(alarm)

                        stub(mockEKEventStore) { (stub) in
                            when(stub).requestAccess(to: any(), completion: any()).thenDoNothing()
                            when(stub).save(any(), span: any()).thenDoNothing()
                            when(stub).events(matching: any()).thenReturn([mockEvent])
                        }
                        _ = try? testRequest.addEventToCalendar(event: eventsModel).toBlocking(timeout: 3).toArray()
                    }
                    it("calls to the mockEKEventHelper for authorizationStatus", closure: {
                        verify(mockEKEventHelper).authorizationStatus.get()
                    })
                    it("calls to the mockEKEventStore for predicateForEvents", closure: {
                        verify(mockEKEventStore).predicateForEvents(withStart: any(), end: any(), calendars: any())
                    })
                    it("calls to the mockEKEventStore for events matching event", closure: {
                        verify(mockEKEventStore).events(matching: any())
                    })
                    it("it failed with error EKEventError eventAlreadyExistsInCalendar", closure: {
                        let observable = testRequest.addEventToCalendar(event: eventsModel).asObservable()

                        let res = testScheduler.start { observable }
                        expect(res.events.count).to(equal(1))
                        let correctResult = [Recorded.error(200, EKEventError.eventAlreadyExistsInCalendar, EventsCalendarStatus.self)]
                        expect(res.events).to(equal(correctResult))
                    })
                })
            })

            describe("when authorizationStatus is notDetermined") {
                beforeEach {
                    stub(mockEKEventHelper, block: { stub in
                        when(stub.authorizationStatus).get.thenReturn(Single.just(.notDetermined))
                    })
                }

                context("when requestAccess is false", {
                    var result: [EventsCalendarStatus]?
                    beforeEach {
                        stub(mockEKEventHelper, block: { stub in
                            when(stub.requestAccess).get.thenReturn(Single.just(false))
                        })

                        stub(mockEKEventStore) { (stub) in
                            when(stub).requestAccess(to: any(), completion: any()).thenDoNothing()
                        }
                        result = try? testRequest.addEventToCalendar(event: eventsModel).toBlocking(timeout: 3).toArray()
                    }
                    it("it failed with error calendarAccessDeniedOrRestricted", closure: {
                        expect(result?.count).to(equal(1))
                        expect(result?.first).to(equal(EventsCalendarStatus.denied))
                    })
                    it("calls to the mockEKEventHelper for authorizationStatus", closure: {
                        verify(mockEKEventHelper).authorizationStatus.get()
                    })
                })

                context("when requestAccess is true", {
                    var result: [EventsCalendarStatus]?
                    beforeEach {
                        stub(mockEKEventHelper, block: { stub in
                            when(stub.requestAccess).get.thenReturn(Single.just(true))
                        })

                        stub(mockEKEventStore) { (stub) in
                            when(stub).requestAccess(to: any(), completion: any()).thenDoNothing()
                            when(stub).save(any(), span: any()).thenDoNothing()
                        }
                        result = try? testRequest.addEventToCalendar(event: eventsModel).toBlocking(timeout: 3).toArray()
                    }
                    it("it failed with error calendarAccessDeniedOrRestricted", closure: {
                        expect(result?.count).to(equal(1))
                        expect(result?.first).to(equal(EventsCalendarStatus.added))
                    })
                    it("calls to the mockEKEventHelper for authorizationStatus", closure: {
                        verify(mockEKEventHelper).authorizationStatus.get()
                    })
                })
            }
        }
    }
}
