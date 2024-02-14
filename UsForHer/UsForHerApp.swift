//
//  UsForHerApp.swift
//  UsForHer
//
//  Created by Ben Levy on 3/4/21.
//

import SwiftUI
import UIKit
import Firebase
import BackgroundTasks

@main
struct UsForHerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let contentView = ContentView()
    var body: some Scene {
        WindowGroup {
            contentView
            
        }
    }
}
class AppDelegate: NSObject, UIApplicationDelegate {
    let cW = UsForHerApp().contentView
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
         application.setMinimumBackgroundFetchInterval(1)

        if(application.applicationState == .background){
            cW.update()
        }
        
        return true
    }
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        submitBackgroundTasks()
      }
      
      func submitBackgroundTasks() {
        // Declared at the "Permitted background task scheduler identifiers" in info.plist
        let backgroundAppRefreshTaskSchedulerIdentifier = "com.background"
        let timeDelay = 10.0

        do {
          let backgroundAppRefreshTaskRequest = BGAppRefreshTaskRequest(identifier: backgroundAppRefreshTaskSchedulerIdentifier)
          backgroundAppRefreshTaskRequest.earliestBeginDate = Date(timeIntervalSinceNow: timeDelay)
          try BGTaskScheduler.shared.submit(backgroundAppRefreshTaskRequest)
          print("Submitted task request")
        } catch {
          print("Failed to submit BGTask")
        }
      }
    
    func registerBackgroundTasks() {
       // Declared at the "Permitted background task scheduler identifiers" in info.plist
       let backgroundAppRefreshTaskSchedulerIdentifier = "com.background"

       // Use the identifier which represents your needs
       BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundAppRefreshTaskSchedulerIdentifier, using: nil) { (task) in
          print("BackgroundAppRefreshTaskScheduler is executed NOW!")
          print("Background time remaining: \(UIApplication.shared.backgroundTimeRemaining)s")
          task.expirationHandler = {
            task.setTaskCompleted(success: false)
          }

          // Do some data fetching and call setTaskCompleted(success:) asap!
          let isFetchingSuccess = true
          task.setTaskCompleted(success: isFetchingSuccess)
        }
      }
 }
