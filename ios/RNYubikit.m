#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNYubikit, NSObject)
  RCT_EXTERN_METHOD(initNFCSession:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

  RCT_EXTERN_METHOD(stopNFCSession:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

  RCT_EXTERN_METHOD(initAccessorySession:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

  RCT_EXTERN_METHOD(stopAccessorySession:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

  RCT_EXTERN_METHOD(registerU2F:(NSString *)challenge appId:(NSString *)appId resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

  RCT_EXTERN_METHOD(signU2F:(NSString *)keyHandle challenge:(NSString *)challenge appId:(NSString *)appId resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
@end
