import BrazeKit
import BrazeLocation
import BrazeUI
import Flutter
import SDWebImage
import UIKit
import braze_plugin

let brazeApiKey = "9292484d-3b10-4e67-971d-ff0c0d518e21"
let brazeEndpoint = "sondheim.appboy.com"

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, BrazeInAppMessageUIDelegate {

  static var braze: Braze? = nil

  // The subscription needs to be retained to be active
  var contentCardsSubscription: Braze.Cancellable?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // - Setup Braze
    let configuration = Braze.Configuration(apiKey: brazeApiKey, endpoint: brazeEndpoint)
    configuration.sessionTimeout = 1
    configuration.triggerMinimumTimeInterval = 0
    configuration.location.automaticLocationCollection = true
    configuration.location.brazeLocation = BrazeLocation()
    configuration.logger.level = .debug

    let braze = BrazePlugin.initBraze(configuration)

    // - GIF support
    GIFViewProvider.shared = .sdWebImage

    // - InAppMessage UI
    let inAppMessageUI = BrazeInAppMessageUI()
    inAppMessageUI.delegate = self
    braze.inAppMessagePresenter = inAppMessageUI

    contentCardsSubscription = braze.contentCards.subscribeToUpdates { contentCards in
      print("=> [Content Card Subscription] Received cards:", contentCards)

      // Pass each content card model to the Dart layer.
      BrazePlugin.processContentCards(contentCards)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: BrazeInAppMessageUIDelegate

  func inAppMessage(
    _ ui: BrazeInAppMessageUI,
    willPresent message: Braze.InAppMessage,
    view: InAppMessageView
  ) {
    print("=> [In-app Message] Received message from Braze:", message)

    // Pass in-app message data to the Dart layer.
    BrazePlugin.processInAppMessage(message)
  }

}

// MARK: GIF support

extension GIFViewProvider {

  public static let sdWebImage = Self(
    view: { SDAnimatedImageView(image: image(for: $0)) },
    updateView: { ($0 as? SDAnimatedImageView)?.image = image(for: $1) }
  )

  private static func image(for url: URL?) -> UIImage? {
    guard let url = url else { return nil }
    return url.pathExtension == "gif"
      ? SDAnimatedImage(contentsOfFile: url.path)
      : UIImage(contentsOfFile: url.path)
  }

}
