import AuthenticationServices
import SafariServices
import Flutter
import UIKit

public class SwiftFlutterWebAuthPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_web_auth", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterWebAuthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "authenticate" {
            let url = URL(string: (call.arguments as! Dictionary<String, AnyObject>)["url"] as! String)!
            let callbackURLScheme = (call.arguments as! Dictionary<String, AnyObject>)["callbackUrlScheme"] as! String

            var sessionToKeepAlive: Any? = nil // if we do not keep the session alive, it will get closed immediately while showing the dialog
            let completionHandler = { (url: URL?, err: Error?) in
                sessionToKeepAlive = nil

                if let err = err { 
                    NSLog("----------------");
                    if #available(iOS 12, *) {
                        NSLog("-------1111111---------");
                        if case ASWebAuthenticationSessionError.canceledLogin = err {
                            NSLog("-------2222222---------");
                            result(FlutterError(code: "CANCELED", message: "User canceled login", details: nil))
                            return
                        }
                    }
                    
                    if #available(iOS 11, *) {
                        NSLog("-------333333333---------");
                        if case SFAuthenticationError.canceledLogin = err {
                            NSLog("-------44444444---------");
                            result(FlutterError(code: "CANCELED", message: "User canceled login", details: nil))
                            return
                        }
                    }
                    
                    NSLog("-------55555555555---------");

                    result(FlutterError(code: "EUNKNOWN", message: err.localizedDescription, details: nil))
                    return
                }
                                     
                NSLog("Sucesso!!!!!!!!!!!!!!!!!!!!!!!");
                                     
                NSLog(url!.absoluteString);

                result(url!.absoluteString)
            }

            if #available(iOS 12, *) { 
                NSLog("11111111111111");
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)

                if #available(iOS 13, *) {
                    NSLog("222222222222");
                    guard let provider = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController else {
                        result(FlutterError(code: "FAILED", message: "Failed to aquire root FlutterViewController" , details: nil))
                        return
                    }

                    session.presentationContextProvider = provider
                }

                session.start()
                sessionToKeepAlive = session
            } else if #available(iOS 11, *) {
                NSLog("33333333333333");
                let session = SFAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)
                session.start()
                sessionToKeepAlive = session
            } else {
                result(FlutterError(code: "FAILED", message: "This plugin does currently not support iOS lower than iOS 11" , details: nil))
            }
        } else if (call.method == "cleanUpDanglingCalls") {
            NSLog("444444444444444");
            // we do not keep track of old callbacks on iOS, so nothing to do here
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}

@available(iOS 13, *)
extension FlutterViewController: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window!
    }
}
