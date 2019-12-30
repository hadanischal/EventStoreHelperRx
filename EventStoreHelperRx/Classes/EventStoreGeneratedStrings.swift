// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {
  /// Allow Calendar access to use this features
  internal static let accessDeniedOrRestrictedBody = L10n.tr("EventStore", "ACCESS_DENIED_OR_RESTRICTED_BODY")
  /// Calendar access denied or restricted
  internal static let accessDeniedOrRestrictedTitle = L10n.tr("EventStore", "ACCESS_DENIED_OR_RESTRICTED_TITLE")
  /// Event already exists in Calendar, Please create new event
  internal static let eventAlreadyExistsInCalendarBody = L10n.tr("EventStore", "EVENT_ALREADY_EXISTS_IN_CALENDAR_BODY")
  /// Unable to add event to Calendar
  internal static let eventAlreadyExistsInCalendarTitle = L10n.tr("EventStore", "EVENT_ALREADY_EXISTS_IN_CALENDAR_TITLE")
  /// Event already exists in Calendar
  internal static let eventNotAddedToCalendarBody = L10n.tr("EventStore", "EVENT_NOT_ADDED_TO_CALENDAR_BODY")
  /// Unable to add event to Calendar
  internal static let eventNotAddedToCalendarTitle = L10n.tr("EventStore", "EVENT_NOT_ADDED_TO_CALENDAR_TITLE")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // swiftlint:disable:next nslocalizedstring_key
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
