#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNYubikit, NSObject)
  RCT_EXTERN_METHOD(initNFCSession:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)

  RCT_EXTERN_METHOD(initAccessorySession:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
@end
