import Foundation

class DailyTaskManager {
  static let s = DailyTaskManager()

  private init() {}

  func Append(taskKey: String, interval: TimeInterval, task: @escaping () -> Void) {
    let lastExecutionKey = "Task_\(taskKey)_LastExecution"
    let currentDate = Date()
    if let lastExecutionDate = UserDefaults.standard.object(forKey: lastExecutionKey) as? Date {
      if lastExecutionDate > currentDate {
        task()
        UserDefaults.standard.set(currentDate, forKey: lastExecutionKey)
        return
      }
      let nextExecutionDate = lastExecutionDate.addingTimeInterval(interval)
      if currentDate < nextExecutionDate {
        return
      }
    }
    task()
    UserDefaults.standard.set(currentDate, forKey: lastExecutionKey)
  }

  func Has(taskKey: String) -> Bool {
    let lastExecutionKey = "Task_\(taskKey)_LastExecution"
    if let lastExecutionDate = UserDefaults.standard.object(forKey: lastExecutionKey) as? Date {
      return Calendar.current.isDate(lastExecutionDate, inSameDayAs: Date())
    }
    return false
  }

  func Remove(taskKey: String) {
    let lastExecutionKey = "Task_\(taskKey)_LastExecution"
    UserDefaults.standard.removeObject(forKey: lastExecutionKey)
  }
}
