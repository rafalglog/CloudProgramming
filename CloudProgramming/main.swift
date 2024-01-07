import SQLite
import Foundation

// Represents a period with start and end dates
struct Period {
    let startDate: Date
    let endDate: Date

    // Computed property to calculate the length of the period in days
    var cycleLength: Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

// Manages period tracking and database operations
class PeriodTracker {
    var db: Connection!
    let periods = Table("periods")
    let id = Expression<Int64>("id")
    let startDate = Expression<Date>("startDate")
    let endDate = Expression<Date>("endDate")

    // Initializes the PeriodTracker and sets up the SQLite database
    init() {
        do {
            // Connects to the SQLite database and creates the 'periods' table if it does not exist
            db = try Connection("db.sqlite3")
            try db.run(periods.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(startDate)
                t.column(endDate)
            })
        } catch {
            print("Error initializing PeriodTracker: \(error)")
        }
    }

    // Adds a new period to the database
    func addPeriod(start: Date, end: Date) {
        do {
            // Inserts a new row into the 'periods' table with start and end dates
            let insert = periods.insert(startDate <- start, endDate <- end)
            try db.run(insert)
        } catch {
            print("Error adding period: \(error)")
        }
    }

    // Retrieves the last recorded period from the database
    func getLastPeriod() -> Period? {
        do {
            // Fetches the most recent record from the 'periods' table
            if let row = try db.pluck(periods.order(startDate.desc)) {
                return Period(startDate: row[startDate], endDate: row[endDate])
            }
        } catch {
            print("Error getting last period: \(error)")
        }
        return nil
    }

    // Calculates and returns the average cycle length based on historical data
    func getAverageCycleLength() -> Int {
        do {
            // Fetches all period records from the 'periods' table and calculates average cycle length
            let periodRecords = try db.prepare(periods.order(startDate.asc))
            var totalDays = 0
            var totalPeriods = 0
            var lastEndDate: Date? = nil

            for period in periodRecords {
                if let lastEnd = lastEndDate {
                    let daysToAdd = Calendar.current.dateComponents([.day], from: lastEnd, to: period[startDate]).day ?? 0
                    totalDays += daysToAdd
                    print("Days between \(lastEnd) and \(period[startDate]): \(daysToAdd)")
                    totalPeriods += 1
                }
                lastEndDate = period[endDate]
            }

            // Calculates the average cycle length
            let averageCycleLength = totalDays / max(1, totalPeriods)
            let finalAverageCycleLength = averageCycleLength == 0 ? 28 : averageCycleLength
            print("Total Days: \(totalDays), Total Periods: \(totalPeriods), Average Cycle Length: \(averageCycleLength)")

            // Returns the average cycle length or a default value if no data is available
            return averageCycleLength
        } catch {
            print("Error calculating average cycle length: \(error)")
        }
        return 28
    }

    // Predicts the start date of the next period based on historical data
    func predictNextPeriodDate() -> Date? {
        guard let lastPeriod = getLastPeriod() else {
            return nil
        }
        let cycleLength = getAverageCycleLength()

        // Returns the predicted start date by adding the average cycle length to the last period's end date
        return Calendar.current.date(byAdding: .day, value: cycleLength, to: lastPeriod.endDate)
    }
    func predictFertileDates() ->(fertileWindowStart: Date?, fertileWindowEnd: Date?) {
        let cycleLength = getAverageCycleLength()
        let lastPeriod = getLastPeriod()

            // Predicted start date by adding the average cycle length to the last period's end date
        let predictedStartDate = Calendar.current.date(byAdding: .day, value: cycleLength, to: lastPeriod!.endDate)
        let fertileWindowStart = Calendar.current.date(byAdding: .day, value: cycleLength / 2 - 5, to: predictedStartDate!)
        let fertileWindowEnd = Calendar.current.date(byAdding: .day, value: cycleLength / 2, to: predictedStartDate!)

            return (fertileWindowStart, fertileWindowEnd)
    }

    // Removes the last recorded period from the database
    func removeLastPeriod() {
        do {
            // Deletes the most recent record from the 'periods' table
            if let lastPeriod = try db.pluck(periods.order(id.desc)) {
                let periodToRemove = periods.filter(id == lastPeriod[id])
                try db.run(periodToRemove.delete())
                print("Successfully removed the last period.")
            } else {
                print("No periods to remove.")
            }
        } catch {
            print("Error removing last period: \(error)")
        }
    }

    // Prints the period history, including cycle lengths and estimated fertile windows
    func printPeriodHistory() {
        do {
            let allPeriods = Array(try db.prepare(periods.order(startDate.asc)))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let averageCycleLength = getAverageCycleLength()
            let fertileWindowStartOffset = averageCycleLength / 2 - 5
            let fertileWindowEndOffset = averageCycleLength / 2

            // Iterates through all periods and prints relevant information
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
            print("Error printing period history: \(error)")
        }
    }
}

// Prints a disclaimer and prompts the user for acceptance
print("""
=====================================================================
              CYCLE TRACKER - Cloud Programming (A SWIFT LEARNING PROJECT)
                      Author: Rafal Glogowski, #163707, Grupa: U2

DISCLAIMER:
This software application (the 'CYCLE TRACKER') is intended as an educational tool.

The CYCLE TRACKER does not provide medical or any other health care advice, diagnosis or treatment. The CYCLE TRACKER and its health-related information and resources are not a substitute for the advice of a professional health care provider.

Always consult your professional health care provider about any health-related decision. DO NOT ignore or delay seeking professional health advice because of information you have read or received through the App.

By using the CYCLE TRACKER, you acknowledge that you understand this disclaimer and that you agree to use this App for educational purposes only.

Would you like to proceed with this educational experience? (yes/no)
======================================================================
""")

// Reads user acceptance and exits the application if not accepted
let userAcceptance = readLine()?.lowercased()
if userAcceptance != "yes" {
    print("You did not agree to the terms of the disclaimer. Exiting the application.")
    exit(0)
}

// Creates an instance of PeriodTracker
let periodTracker = PeriodTracker()

// Sets up a date formatter for user input
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"

// Checks if the "--removelast" flag is present in command line arguments
let shouldRemoveLast = CommandLine.arguments.contains("--removelast")

// Removes the last recorded period if the flag is present; otherwise, prompts the user for actions
if shouldRemoveLast {
    periodTracker.removeLastPeriod()
} else {
    print("What would you like to do? (Enter R to review data or A to add new data)")
    let userResponse = readLine()

    // Reviews data and predicts the next period date if the user chooses to review
    if userResponse?.uppercased() == "R" {
        print("\nPeriod History: ")
        periodTracker.printPeriodHistory()

        if let nextPeriodDate = periodTracker.predictNextPeriodDate() {
            print("\nPredicted Start Date of Next Period: \(dateFormatter.string(from: nextPeriodDate))")
        } else {
            print("Unable to predict next period date.")
        }
    } else if userResponse?.uppercased() == "A" {
        // Adds a new period if the user chooses to add data
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

// Prints the updated period history and predicts the next period date
print("\nPeriod History: ")
periodTracker.printPeriodHistory()

if let nextPeriodDate = periodTracker.predictNextPeriodDate() {
    print("\nPredicted Start Date of Next Period: \(dateFormatter.string(from: nextPeriodDate))")
} else {
    print("Unable to predict next period date.")
}
let fertileDates = periodTracker.predictFertileDates()
if let fertileWindowStart = fertileDates.fertileWindowStart, let fertileWindowEnd = fertileDates.fertileWindowEnd {
    print("Predicted Fertile Window: \(dateFormatter.string(from: fertileWindowStart)) - \(dateFormatter.string(from: fertileWindowEnd))")
} else {
    print("Unable to calculate the predicted fertile window.")
}
