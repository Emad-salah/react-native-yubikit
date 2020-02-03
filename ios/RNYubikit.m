#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNYubikit, NSObject)
  RCT_EXTERN_METHOD(executeRegisterU2F:(NSString *)type challenge:(NSString *)challenge appId:(NSString *)appId resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

  RCT_EXTERN_METHOD(registerU2F:(NSString *)type challenge:(NSString *)challenge appId:(NSString *)appId resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

  RCT_EXTERN_METHOD(signU2F:(NSString *)type keyHandle:(NSString *)keyHandle challenge:(NSString *)challenge appId:(NSString *)appId resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

  RCT_EXTERN_METHOD(executeSignU2F:(NSString *)type keyHandles:(NSArray *)keyHandles challenge:(NSString *)challenge appId:(NSString *)appId resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
@end
