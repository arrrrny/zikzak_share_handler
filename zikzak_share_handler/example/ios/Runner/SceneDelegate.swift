import UIKit
import Flutter

@available(iOS 13.0, *)
class SceneDelegate: FlutterSceneDelegate {

    // This is called when a new scene is being created
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)

        // Handle any URLs that were used to open the app
        if let urlContext = connectionOptions.urlContexts.first {
            let url = urlContext.url
            // The plugin will handle this through the scene(_:openURLContexts:) method
            _ = scene(scene, openURLContexts: connectionOptions.urlContexts)
        }

        // Handle user activities (for universal links and handoff)
        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            _ = scene(scene, continue: userActivity)
        }
    }

    // This is called when the app is asked to open a URL
    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        // Let the plugin handle the URL
        // The plugin's scene-based URL handling will be called automatically through FlutterSceneDelegate
        return super.scene(scene, openURLContexts: URLContexts)
    }

    // This is called to handle NSUserActivity (universal links, handoff, etc.)
    override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        // Let the plugin handle the user activity
        return super.scene(scene, continue: userActivity)
    }
}
