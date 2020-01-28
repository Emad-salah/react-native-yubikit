@objc(RNYubikit)
class RNYubikit: NSObject {
    var nfcSessionStatus = false
    var accessorySessionStatus = false
    
    @objc
    func initNFCSession(_ resolve: @escaping RCTPromiseResolveBlock, _ reject: @escaping RCTPromiseRejectBlock) {
        if YubiKitDeviceCapabilities.supportsISO7816NFCTags {
            // Provide additional setup when NFC is available
            // example
            YubiKitManager.shared.nfcSession.startIso7816Session()
            
            nfcSessionStatus = true
            resolve(true)
        } else {
            // Handle the missing NFC support
            reject("Device doesn't support NFC")
        }
    }
    
    @objc
    func initAccessorySession(_ resolve: @escaping RCTPromiseResolveBlock, _ reject: @escaping RCTPromiseRejectBlock) {
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Make sure the session is started (in case it was closed by another demo).
            YubiKitManager.shared.accessorySession.startSession()
            
            accessorySessionStatus = true
            resolve(true)
        } else {
            reject("This device or iOS version does not support operations with MFi accessory YubiKeys.")
        }
    }
    
    @objc
    func stopNFCSession(_ resolve: @escaping RCTPromiseResolveBlock, _ reject: @escaping RCTPromiseRejectBlock) {
        if nfcSessionStatus == true {
            // Provide additional setup when NFC is available
            // example
            YubiKitManager.shared.nfcSession.stopIso7816Session()
            
            nfcSessionStatus = false
            resolve(true)
        } else {
            // Handle the missing NFC support
            reject("Please start an NFC session first before stopping it")
        }
    }
    
    @objc
    func stopAccessorySession(_ resolve: @escaping RCTPromiseResolveBlock, _ reject: @escaping RCTPromiseRejectBlock) {
        if accessorySessionStatus == true {
            // Provide additional setup when NFC is available
            // example
            YubiKitManager.shared.accessorySession.stopSession()
            
            accessorySessionStatus = false
            resolve(true)
        } else {
            reject("Please start an accessory session first before stopping it")
        }
    }
    
    @objc
    func registerU2F(challenge: String, appId: String, _ resolve: @escaping RCTPromiseResolveBlock, _ reject: @escaping RCTPromiseRejectBlock) {
        // The challenge and appId are received from the authentication server.
        let registerRequest = YKFKeyU2FRegisterRequest(challenge: challenge, appId: appId)
            
        YubiKitManager.shared.accessorySession.u2fService!.execute(registerRequest) { [weak self] (response, error) in
            guard error == nil else {
                // Handle the error
                reject(error.message)
                return
            }
            // The response should not be nil at this point. Send back the response to the authentication server.
            resolve(response)
        }
    }
    
    @objc
    func signU2F(keyHandle: String, challenge: String, appId: String, _ resolve: @escaping RCTPromiseResolveBlock, _ reject: @escaping RCTPromiseRejectBlock) {
        // The challenge and appId are received from the authentication server.
        guard let signRequest = YKFKeyU2FSignRequest(challenge: challenge, appId: appId, keyHandle: keyHandle) else {
            reject("Session not started yet")
            return
        }
        guard let u2fService = YubiKitManager.shared.accessorySession.u2fService else {
            reject("The U2F service is not available (the session is closed or the key is not connected).")
            return
        }
        
        u2fService.execute(signRequest) { [weak self] (response, error) in
            guard error == nil else {
                // Handle the error
                reject(error.message)
                return
            }
            // The response should not be nil at this point. Send back the response to the authentication server.
            resolve(response)
        }
    }
}
 
