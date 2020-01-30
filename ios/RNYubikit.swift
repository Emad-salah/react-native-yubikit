import Foundation

struct Log: TextOutputStream {

    func write(_ string: String) {
        let fm = FileManager.default
        let log = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("swift-log.txt")
        if let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            handle.write(string.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? string.data(using: .utf8)?.write(to: log)
        }
    }
}

var logger = Log()

@objc(RNYubikit)
class RNYubikit: NSObject {
    var nfcSessionStatus = false
    var accessorySessionStatus = false
    private var nfcSessionStateObservation: NSKeyValueObservation?
    
    @objc
    private func initNFCSession() -> Bool {
        if YubiKitDeviceCapabilities.supportsISO7816NFCTags, #available(iOS 13.0, *) {
            // Provide additional setup when NFC is available
            // example
            YubiKitManager.shared.nfcSession.startIso7816Session()
            
            nfcSessionStatus = true
            return true
        } else {
            // Handle the missing NFC support
            return false
        }
    }
    
    @objc
    private func initAccessoryession() -> Bool {
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Provide additional setup when MFi is available
            // example
            YubiKitManager.shared.accessorySession.startSession()
            
            accessorySessionStatus = true
            return true
        } else {
            // Handle the missing MFi support
            return false
        }
    }
    
    @objc
    private func stopNFCSession() -> Bool {
        if nfcSessionStatus == true, #available(iOS 13.0, *) {
            // Provide additional setup when NFC is available
            // example
            YubiKitManager.shared.nfcSession.stopIso7816Session()
            
            nfcSessionStatus = false
            return true
        } else {
            return false
        }
    }
    
    @objc
    private func stopAccessorySession() -> Bool {
        if accessorySessionStatus == true {
            // Provide additional setup when MFi is available
            // example
            YubiKitManager.shared.accessorySession.stopSession()
            
            accessorySessionStatus = false
            return true
        } else {
            return false
        }
    }

    @objc
    func executeRegisterU2F(_ type: String, challenge: String, appId: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        if type == "nfc" {
            guard #available(iOS 13.0, *), YubiKitDeviceCapabilities.supportsISO7816NFCTags else {
                reject("NFCUnsupported", "Your device doesn't support NFC", nil)
                return
            }

            let nfcSession = YubiKitManager.shared.nfcSession as! YKFNFCSession
            if nfcSession.iso7816SessionState == .open {
                self.registerU2F("nfc", challenge: challenge, appId: appId, resolver: resolve, rejecter: reject)
                return
            }

            // The ISO7816 session is started only when required since it's blocking the application UI with the NFC system action sheet.
            let sessionStarted = self.initNFCSession()
            
            guard sessionStarted else {
                reject("NFCUnsupported", "NFC is not supported on this device", nil)
                return
            }
            
            // Execute the request after the key(tag) is connected.
            nfcSessionStateObservation = nfcSession.observe(\.iso7816SessionState, changeHandler: { [weak self] session, change in
                if session.iso7816SessionState == .open {
                    self?.registerU2F("nfc", challenge: challenge, appId: appId, resolver: resolve, rejecter: reject)
                    // The challenge and appId are received from the authentication server.
                    guard let registerRequest = YKFKeyU2FRegisterRequest(challenge: challenge, appId: appId) else {
                        reject("RegisterRequest", "U2F Register Request initialization failed", nil)
                        return
                    }
                    
                    guard type == "nfc", #available(iOS 13.0, *) else {
                        reject("NFCUnsupported", "Your device doesn't support NFC", nil)
                        return
                    }
                    
                    if type == "nfc" {
                        YubiKitManager.shared.nfcSession.u2fService!.execute(registerRequest) { [weak self] (response, error) in
                            guard error == nil else {
                                // Handle the error
                                reject("U2FService", error?.localizedDescription, error)
                                return
                            }
                            // The response should not be nil at this point. Send back the response to the authentication server.
                            print("U2F Register Data:", response, to: &logger)
                            resolve("{ \"clientData\": \"\(response?.clientData ?? "")\", \"registrationData\": \"\(response?.registrationData.base64EncodedString(options: .endLineWithLineFeed) ?? "")\" }")
                            _ = self?.stopNFCSession()
                            self?.nfcSessionStateObservation = nil
                        }
                    } else if type == "accessory" {
                        YubiKitManager.shared.accessorySession.u2fService!.execute(registerRequest) { [weak self] (response, error) in
                            guard error == nil else {
                                // Handle the error
                                reject("U2FService", error?.localizedDescription, error)
                                return
                            }
                            // The response should not be nil at this point. Send back the response to the authentication server.
                            resolve(response)
                            _ = self?.stopAccessorySession()
                            self?.nfcSessionStateObservation = nil
                        }
                    }
                }
            })
        } else {
            self.registerU2F("accessory", challenge: challenge, appId: appId, resolver: resolve, rejecter: reject)
        }
    }
    
    @objc
    func registerU2F(
        _ type: String,
        challenge: String,
        appId: String,
        resolver resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        // The challenge and appId are received from the authentication server.
        guard let registerRequest = YKFKeyU2FRegisterRequest(challenge: challenge, appId: appId) else {
            reject("RegisterRequest", "U2F Register Request initialization failed", nil)
            return
        }
        
        guard type == "nfc", #available(iOS 13.0, *) else {
            reject("NFCUnsupported", "Your device doesn't support NFC", nil)
            return
        }
        
        if type == "nfc" {
            YubiKitManager.shared.nfcSession.u2fService!.execute(registerRequest) { [weak self] (response, error) in
                guard error == nil else {
                    // Handle the error
                    reject("U2FService", error?.localizedDescription, error)
                    return
                }
                // The response should not be nil at this point. Send back the response to the authentication server.
                _ = self?.stopNFCSession()
                resolve(response)
            }
        } else if type == "accessory" {
            YubiKitManager.shared.accessorySession.u2fService!.execute(registerRequest) { [weak self] (response, error) in
                guard error == nil else {
                    // Handle the error
                    reject("U2FService", error?.localizedDescription, error)
                    return
                }
                // The response should not be nil at this point. Send back the response to the authentication server.
                resolve(response)
                _ = self?.stopAccessorySession()
            }
        }
    }
    
    @objc
    func signU2F(
        _ type: String,
        keyHandle: String,
        challenge: String,
        appId: String,
        resolver resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        // The challenge and appId are received from the authentication server.
        guard let signRequest = YKFKeyU2FSignRequest(challenge: challenge, keyHandle: keyHandle, appId: appId) else {
            reject("U2FSession", "Session not started yet", nil)
            return
        }
        
        var u2fService: YKFKeyU2FServiceProtocol? = nil
        
        if type == "nfc", #available(iOS 13.0, *) {
            guard YubiKitManager.shared.nfcSession.u2fService != nil else {
                reject("U2FService", "The U2F service is not available (the session is closed or the key is not connected).", nil)
                return
            }
            
            u2fService = YubiKitManager.shared.nfcSession.u2fService
        } else if type == "accessory" {
            guard YubiKitManager.shared.accessorySession.u2fService != nil else {
                reject("U2FService", "The U2F service is not available (the session is closed or the key is not connected).", nil)
                return
            }
            
            u2fService = YubiKitManager.shared.accessorySession.u2fService
        }
        
        if u2fService == nil {
            reject("UnknownSignType", "An unknown sign type was requested", nil)
            return
        }
        
        u2fService!.execute(signRequest) { [weak self] (response, error) in
            guard error == nil else {
                // Handle the error
                reject("U2FService", error?.localizedDescription, error)
                return
            }
            // The response should not be nil at this point. Send back the response to the authentication server.
            resolve(response)
        }
    }
}
 
