#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNYubikit, NSObject)

RCT_EXPORT_METHOD(initYubikit
                  : (RCTPromiseResolveBlock)resolve
                  : (RCTPromiseRejectBlock)reject)

@end
