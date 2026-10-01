import Foundation

extension Date {
    static func monthRange(year: Int, month: Int) throws -> (start: Date, end: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let interval = calendar.dateInterval(of: .month, for: start),
              let end = calendar.date(byAdding: .day, value: -1, to: interval.end) else {
            throw APODServiceError.invalidURL
        }

        return (start, end)
    }
}
