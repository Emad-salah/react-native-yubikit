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
    private var accessorySessionStateObservation: NSKeyValueObservation?
    
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
                    // self?.registerU2F("nfc", challenge: challenge, appId: appId, resolver: resolve, rejecter: reject)
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
                            let registerData: NSDictionary = [
                                "clientData": response?.clientData.data(using: .utf8)?.base64EncodedString(options: .endLineWithLineFeed) ?? "",
                                "registrationData": response?.registrationData.base64EncodedString(options: .endLineWithLineFeed) ?? ""
                            ]
                            print("[iOS Swift] U2F Register Data: \(response as AnyObject)", to: &logger)
                            resolve(registerData)
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
    private func signNFCU2F(
        session: YKFNFCSession,
        challenge: String,
        appId: String,
        keyHandles: [String],
        callback: @escaping (String?, NSDictionary?) -> ()
    ) {
        let semaphore = DispatchSemaphore(value: 0)
        var signedChallenge = false
        DispatchQueue.global().async {
            for keyHandle in keyHandles {
                guard !signedChallenge else {
                    break
                }
                
                // The challenge and appId are received from the authentication server.
                guard let signRequest = YKFKeyU2FSignRequest(challenge: challenge, keyHandle: keyHandle, appId: appId) else {
                    continue
                }
                
                guard #available(iOS 13.0, *) else {
                    callback("NFCUnsupported", nil)
                    _ = self.stopNFCSession()
                    self.nfcSessionStateObservation = nil
                    break
                }
                
                guard session.iso7816SessionState == .open else {
                    let error = "NFCSessionClosed"
                    callback(error, nil)
                    _ = self.stopNFCSession()
                    self.nfcSessionStateObservation = nil
                    break
                }

                YubiKitManager.shared.nfcSession.u2fService!.execute(signRequest) { [weak self] (response, error) in
                    guard error == nil else {
                        // Handle the error
                        print("[iOS Swift] U2F Error: \(error?.localizedDescription)")
                        semaphore.signal()
                        return
                    }
                    // The response should not be nil at this point. Send back the response to the authentication server.
                    print("[iOS Swift] NFC U2F Sign Data:", response, to: &logger)
                    let signData: NSDictionary = [
                        "clientData": response?.clientData.data(using: .utf8)?.base64EncodedString(options: .endLineWithLineFeed) ?? "",
                        "keyHandle": response?.keyHandle ?? "",
                        "signature": response?.signature.base64EncodedString(options: .endLineWithLineFeed) ?? ""
                    ]
                    signedChallenge = true
                    semaphore.signal()
                    _ = self?.stopNFCSession()
                    self?.nfcSessionStateObservation = nil
                    callback(nil, signData)
                }
                semaphore.wait()
            }
        }
    }

    @objc
    private func signAccessoryU2F(
        session: YKFAccessorySession,
        challenge: String,
        appId: String,
        keyHandles: [String],
        callback: @escaping (String?, NSDictionary?) -> ()
    ) {
        let semaphore = DispatchSemaphore(value: 0)
        var signedChallenge = false
        DispatchQueue.global().async {
            for keyHandle in keyHandles {
                guard !signedChallenge else {
                    break
                }
                
                // The challenge and appId are received from the authentication server.
                guard let signRequest = YKFKeyU2FSignRequest(challenge: challenge, keyHandle: keyHandle, appId: appId) else {
                    continue
                }
                
                guard session.sessionState == .open else {
                    let error = "NFCSessionClosed"
                    callback(error, nil)
                    _ = self.stopAccessorySession()
                    self.accessorySessionStateObservation = nil
                    break
                }

                YubiKitManager.shared.accessorySession.u2fService!.execute(signRequest) { [weak self] (response, error) in
                    guard error == nil else {
                        // Handle the error
                        print("[iOS Swift] U2F Error: \(error?.localizedDescription)")
                        semaphore.signal()
                        return
                    }
                    // The response should not be nil at this point. Send back the response to the authentication server.
                    print("[iOS Swift] Accessory U2F Sign Data:", response, to: &logger)
                    let signData: NSDictionary = [
                        "clientData": response?.clientData.data(using: .utf8)?.base64EncodedString(options: .endLineWithLineFeed) ?? "",
                        "keyHandle": response?.keyHandle ?? "",
                        "signature": response?.signature.base64EncodedString(options: .endLineWithLineFeed) ?? ""
                    ]
                    signedChallenge = true
                    semaphore.signal()
                    _ = self?.stopAccessorySession()
                    self?.accessorySessionStateObservation = nil
                    callback(nil, signData)
                }
                semaphore.wait()
            }
        }
    }

    @objc
    func executeSignU2F(
        _ type: String,
        keyHandles: [String],
        challenge: String,
        appId: String,
        resolver resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        if type == "nfc" {
            guard #available(iOS 13.0, *), YubiKitDeviceCapabilities.supportsISO7816NFCTags else {
                reject("NFCUnsupported", "Your device doesn't support NFC", nil)
                return
            }

            let nfcSession = YubiKitManager.shared.nfcSession as! YKFNFCSession

            // The ISO7816 session is started only when required since it's blocking the application UI with the NFC system action sheet.
            let sessionStarted = nfcSession.iso7816SessionState == .open ? true : self.initNFCSession()
            
            guard sessionStarted else {
                reject("NFCUnsupported", "NFC is not supported on this device", nil)
                return
            }
            
            // Execute the request after the key(tag) is connected.
            nfcSessionStateObservation = nfcSession.observe(\.iso7816SessionState, changeHandler: { [weak self] session, change in
                if session.iso7816SessionState == .open {
                    self?.signNFCU2F(session: session, challenge: challenge, appId: appId, keyHandles: keyHandles) { error, response in
                        guard error == nil else {
                            reject(error, "An error has occurred", nil)
                            return
                        }

                        resolve(response)
                    }
                }
            })
        } else {
            guard YubiKitDeviceCapabilities.supportsMFIAccessoryKey else {
                reject("KeyUnsupported", "Your device doesn't support FIDO Keys", nil)
                return
            }

            let accessorySession = YubiKitManager.shared.accessorySession as! YKFAccessorySession

            // The ISO7816 session is started only when required since it's blocking the application UI with the NFC system action sheet.
            let sessionStarted = accessorySession.sessionState == .open ? true : self.initAccessoryession()
            
            guard sessionStarted else {
                reject("KeyUnsupported", "Your device doesn't support FIDO Keys", nil)
                return
            }
            
            // Execute the request after the key(tag) is connected.
            accessorySessionStateObservation = accessorySession.observe(\.sessionState, changeHandler: { [weak self] session, change in
                if session.sessionState == .open {
                    self?.signAccessoryU2F(session: session, challenge: challenge, appId: appId, keyHandles: keyHandles) { error, response in
                        guard error != nil else {
                            reject(error, "An error has occurred", nil)
                            return
                        }

                        resolve(response)
                    }
                }
            })
        }
    }
}
 
