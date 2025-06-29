//
//  AppDelegate.swift
//  OldOS
//
//  Created by Zane Kleinberg on 1/9/21.
//

import UIKit
//import GoogleSignIn
import CoreData
import OAuth2
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //userDefaults is a great way to go about managing data in the context of this app. We initialize it in our app delegate, and fill in data when none is set yet...
        let userDefaults = UserDefaults.standard
        userDefaults.register(
            defaults: [
                "Lock_Wallpaper": "Wallpaper_1",
                "Home_Wallpaper": "Wallpaper_1",
                "Camera_Wallpaper_Lock": false,
                "Camera_Wallpaper_Home": false,
                "bookmarks": ["https://apple.com":"Apple", "https://yahoo.com":"Yahoo!", "https://google.com":"Google", "https://manuals.info.apple.com/MANUALS/1000/MA1539/en_US/iPhone_iOS4_User_Guide.pdf":"iPhone User Guide", "https://web.archive.org/web/20100814131917/https://www.apple.com/webapps/":"iPhone Web Applications",  "https://zsk.dev":"Zane K — My place on the internet"],
                "webpages": ["0":"https://google.com", "1":"https://zsk.dev"], //Saving like this let's us get around NSKeyedArchiver
                "weather_cities": ["0":"Cupertino,us", "1": "New York,us"],
                "weather_mode": "imperial",
                "stock_mode": "Price",
                "stocks": ["AAPL", "GOOG", "NVDA", "TSLA", "T","MSFT", "AMZN", "NFLX", "META", "INTC", "ORCL"]
            ]
        )
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        //Google email setup
//        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
//          if error != nil || user == nil {
//            // Show the app's signed-out state.
//          } else {
//            // Show the app's signed-in state.
//          }
//        }
        
        return true
    }
    
//    func application(
//      _ app: UIApplication,
//      open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]
//    ) -> Bool {
//      var handled: Bool
//
//      handled = GIDSignIn.sharedInstance.handle(url)
//      if handled {
//        return true
//      }
//
//      // Handle other custom URL types.
//
//      // If not handled by this app, return false.
//      return false
//    }
    
//    func application(_ app: UIApplication,
//                  open url: URL,
//                  options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
//        // you should probably first check if this is the callback being opened
//      //  if <# check #> {
//            // if your oauth2 instance lives somewhere else, adapt accordingly
//            oauth2.handleRedirectURL(url)
//        return true
//       // }
//    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    lazy var persistentEmailContainer: NSPersistentContainer = {
      let container = NSPersistentContainer(name: "Emails")
      container.loadPersistentStores { _, error in
        if let error = error as NSError? {
          fatalError("Unresolved error \(error), \(error.userInfo)")
        }
      }
      return container
    }()


}

//let config = GIDConfiguration.init(clientID: "814260428968-hd7t3jtn7q3hu3p0o1fotenp35986uk2.apps.googleusercontent.com")

var oauth2 = OAuth2CodeGrant(settings: [
    "client_id": "814260428968-hd7t3jtn7q3hu3p0o1fotenp35986uk2.apps.googleusercontent.com",
    "authorize_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://www.googleapis.com/oauth2/v3/token",
    "scope": "https://mail.google.com",     // depends on the API you use
    "redirect_uris": ["com.googleusercontent.apps.814260428968-hd7t3jtn7q3hu3p0o1fotenp35986uk2:/oauth"],
])
