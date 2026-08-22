//
//  SceneDelegate.swift
//  OldOS
//
//  Created by Zane Kleinberg on 1/9/21.
//

import UIKit
import SwiftUI
import CoreData
import OAuth2
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate {
               appDelegate.oauth2.handleRedirectURL(url)
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let contentView = Controller()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let emailManager = EmailManager(oauth2: appDelegate.oauth2)
            
            let context = persistentContainer.viewContext
            window.rootViewController = HostingController(rootView: contentView.environmentObject(MusicObserver()).environmentObject(emailManager).environment(\.managedObjectContext, context))
            window.rootViewController?.accessibilityElementsHidden = true
            self.window = window
            window.makeKeyAndVisible()
            
//            appDelegate.oauth2.authConfig.authorizeEmbedded = true
//            appDelegate.oauth2.authConfig.ui.useSafariView = true          // ← use SFSafariViewController
//            appDelegate.oauth2.authConfig.authorizeContext = window.rootViewController  // ← a UIViewController
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        saveContext()
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
      let container = NSPersistentContainer(name: "Note")
      container.loadPersistentStores { _, error in
        if let error = error as NSError? {
          fatalError("Unresolved error \(error), \(error.userInfo)")
        }
      }
      return container
    }()

    func saveContext() {
      let context = persistentContainer.viewContext
      if context.hasChanges {
        do {
          try context.save()
        } catch {
          let nserror = error as NSError
          fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
      }
    }
    
    
    //emails

//    func saveEmailContext() {
//      let context = persistentContainer.viewContext
//      if context.hasChanges {
//        do {
//          try context.save()
//        } catch {
//          let nserror = error as NSError
//          fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//        }
//      }
//    }
    

}

private class HostingController<Content>: UIHostingController<Content> where Content: View {
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}
