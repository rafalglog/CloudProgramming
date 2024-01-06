import SQLite
import Foundation

struct Period {
    let startDate: Date
    let endDate: Date

    var cycleLength: Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

class PeriodTracker {
    var db: Connection!
    let periods = Table("periods")
    let id = Expression<Int64>("id")
    let startDate = Expression<Date>("startDate")
    let endDate = Expression<Date>("endDate")

    init() {
        do {
            db = try Connection("db.sqlite3")
            try db.run(periods.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(startDate)
                t.column(endDate)
            })
        } catch {
            print(error)
        }
    }

    func addPeriod(start: Date, end: Date) {
        do {
            let insert = periods.insert(startDate <- start, endDate <- end)
            try db.run(insert)
        } catch {
            print(error)
        }
    }

    func getLastPeriod() -> Period? {
        do {
            if let row = try db.pluck(periods.order(startDate.desc)) {
                return Period(startDate: row[startDate], endDate: row[endDate])
            }
        } catch {
            print(error)
        }
        return nil
    }

    func getAverageCycleLength() -> Int {
        do {
            let periodRecords = try db.prepare(periods.order(startDate.asc))
            var totalDays = 0
            var totalPeriods = 0
            var lastEndDate: Date? = nil
            for period in periodRecords {
                if let lastEnd = lastEndDate {
                    totalDays += Calendar.current.dateComponents([.day], from: lastEnd, to: period[startDate]).day ?? 0
                    totalPeriods += 1
                }
                lastEndDate = period[endDate]
            }
            return totalDays / max(1, totalPeriods)
        } catch {
            print(error)
        }
        return 28
    }

    func predictNextPeriodDate() -> Date? {
        guard let lastPeriod = getLastPeriod() else {
            return nil
        }
        let cycleLength = getAverageCycleLength()
        return Calendar.current.date(byAdding: .day, value: cycleLength, to: lastPeriod.endDate)
    }

    func removeLastPeriod() {
        do {
            if let lastPeriod = try db.pluck(periods.order(id.desc)) {
                let periodToRemove = periods.filter(id == lastPeriod[id])
                try db.run(periodToRemove.delete())
                print("Successfully removed the last period.")
            } else {
                print("No periods to remove.")
            }
        } catch {
            print("Could not remove the last period due to error: \(error)")
        }
    }

    func printPeriodHistory() {
        do {
            let allPeriods = Array(try db.prepare(periods))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let averageCycleLength = getAverageCycleLength()
            let fertileWindowStartOffset = averageCycleLength / 2 - 5
            let fertileWindowEndOffset = averageCycleLength / 2

            for period in allPeriods {
                let start = period[startDate]
                let cycleStart = Calendar.current.date(byAdding: .day, value: fertileWindowStartOffset, to: start)
                let cycleEnd = Calendar.current.date(byAdding: .day, value: fertileWindowEndOffset, to: start)
                let cycleLength = Period(startDate: start, endDate: period[endDate]).cycleLength
                print("Start Date: \(dateFormatter.string(from: start)), " +
                      "End Date: \(dateFormatter.string(from: period[endDate])), " +
                      "Cycle Length: \(cycleLength) days, " +
                      "Estimated Fertile Window: \(dateFormatter.string(from: cycleStart!)) - \(dateFormatter.string(from: cycleEnd!))")
            }
        } catch {
            print(error)
        }
    }
}
print("""
=====================================================================
              CYCLE TRACKER - Cloud Programming (A SWIFT LEARNING PROJECT)
                      Author: Rafal Glogowski, #12345

DISCLAIMER:
This software application (the 'App') is intended as an educational tool.

The App does not provide medical or any other health care advice, diagnosis or treatment. The App and its health-related information and resources are not a substitute for the advice of a professional health care provider.

Always consult your professional health care provider about any health-related decision. DO NOT ignore or delay seeking professional health advice because of information you have read or received through the App.

By using the App, you acknowledge that you understand this disclaimer and that you agree to use this App for educational purposes only.

Would you like to proceed with this educational experience? (yes/no)
======================================================================
""")

let userAcceptance = readLine()?.lowercased()
if userAcceptance != "yes" {
    print("You did not agree to the terms of the disclaimer. Exiting the application.")
    exit(0)
}
let periodTracker = PeriodTracker()
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"

let shouldRemoveLast = CommandLine.arguments.contains("--removelast")

if shouldRemoveLast {
    periodTracker.removeLastPeriod()
} else {
    print("What would you like to do? (Enter R to review data or A to add new data)")
    let userResponse = readLine()

    if userResponse?.uppercased() == "R" {
        print("\nPeriod History: ")
        periodTracker.printPeriodHistory()

        if let nextPeriodDate = periodTracker.predictNextPeriodDate() {
            print("\nPredicted Start Date of Next Period: \(dateFormatter.string(from: nextPeriodDate))")
        } else {
            print("Unable to predict next period date.")
        }
    } else if userResponse?.uppercased() == "A" {
        print("Please enter the start date (yyyy-mm-dd): ")
        let startInput = readLine()
        print("Please enter the end date (yyyy-mm-dd): ")
        let endInput = readLine()

        if let startString = startInput, let endString = endInput,
        let startDate = dateFormatter.date(from: startString),
        let endDate = dateFormatter.date(from: endString) {
            periodTracker.addPeriod(start: startDate, end: endDate)
        } else {
            print("Invalid input format. Please enter in format yyyy-mm-dd")
        }
    } else {
        print("Invalid option. Please enter R to review data or A to add new data.")
    }
}

print("\nPeriod History: ")
periodTracker.printPeriodHistory()

if let nextPeriodDate = periodTracker.predictNextPeriodDate() {
    print("\nPredicted Start Date of Next Period: \(dateFormatter.string(from: nextPeriodDate))")
} else {
    print("Unable to predict next period date.")
}
