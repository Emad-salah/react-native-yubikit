#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNYubikit, NSObject)
  RCT_EXTERN_METHOD(initNFCSession:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

  RCT_EXTERN_METHOD(initAccessorySession:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
@end
