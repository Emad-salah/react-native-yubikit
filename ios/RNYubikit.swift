@objc(RNYubikit)
class RNYubikit: NSObject {
    var nfcSessionStatus = false
    var accessorySessionStatus = false
    
    @objc
    func initNFCSession(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        if YubiKitDeviceCapabilities.supportsISO7816NFCTags, #available(iOS 13.0, *) {
            // Provide additional setup when NFC is available
            // example
            YubiKitManager.shared.nfcSession.startIso7816Session()
            
            nfcSessionStatus = true
            resolve(true)
        } else {
            // Handle the missing NFC support
            reject("NFCNotSupported", "Device doesn't support NFC", nil)
        }
    }
    
    @objc
    func initAccessorySession(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Make sure the session is started (in case it was closed by another demo).
            YubiKitManager.shared.accessorySession.startSession()
            
            accessorySessionStatus = true
            return resolve(true)
        } else {
            reject("AccessorySession", "This device or iOS version does not support operations with MFi accessory YubiKeys.", nil)
        }
    }
    
    @objc
    func stopNFCSession(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        if nfcSessionStatus == true, #available(iOS 13.0, *) {
            // Provide additional setup when NFC is available
            // example
            YubiKitManager.shared.nfcSession.stopIso7816Session()
            
            nfcSessionStatus = false
            resolve(true)
        } else {
            // Handle the missing NFC support
            reject("NFCSession", "Please start an NFC session first before stopping it", nil)
        }
    }
    
    @objc
    func stopAccessorySession(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        if accessorySessionStatus == true {
            // Provide additional setup when NFC is available
            // example
            YubiKitManager.shared.accessorySession.stopSession()
            
            accessorySessionStatus = false
            resolve(true)
        } else {
            reject("AccessorySession", "Please start an accessory session first before stopping it", nil)
        }
    }
    
    @objc
    func registerU2F(challenge: String, appId: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        // The challenge and appId are received from the authentication server.
        guard let registerRequest = YKFKeyU2FRegisterRequest(challenge: challenge, appId: appId) else {
            reject("RegisterRequest", "U2F Register Request initialization failed", nil)
            return
        }
            
        YubiKitManager.shared.accessorySession.u2fService!.execute(registerRequest) { [weak self] (response, error) in
            guard error == nil else {
                // Handle the error
                reject("U2FService", error?.localizedDescription, error)
                return
            }
            // The response should not be nil at this point. Send back the response to the authentication server.
            resolve(response)
        }
    }
    
    @objc
    func signU2F(keyHandle: String, challenge: String, appId: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        // The challenge and appId are received from the authentication server.
        guard let signRequest = YKFKeyU2FSignRequest(challenge: challenge, keyHandle: keyHandle, appId: appId) else {
            reject("U2FSession", "Session not started yet", nil)
            return
        }
        guard let u2fService = YubiKitManager.shared.accessorySession.u2fService else {
            reject("U2FService", "The U2F service is not available (the session is closed or the key is not connected).", nil)
            return
        }
        
        u2fService.execute(signRequest) { [weak self] (response, error) in
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
 
