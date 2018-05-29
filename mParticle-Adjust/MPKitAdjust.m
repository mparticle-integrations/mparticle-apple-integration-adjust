//
//  MPKitAdjust.m
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPKitAdjust.h"
#ifdef COCOAPODS
    #import <Adjust/Adjust.h>
#else
    #import <AdjustSdk/Adjust.h>
#endif

static NSObject<AdjustDelegate> *temporaryDelegate = nil;
static BOOL didSetKitDelegate = NO;

NSString *const MPKitAdjustAttributionResultKey = @"mParticle-Adjust Attribution Result";
NSString *const MPKitAdjustErrorKey = @"mParticle-Adjust Error";
NSString *const MPKitAdjustErrorDomain = @"mParticle-Adjust";

@interface MPKitAdjust()

@property (nonatomic, strong) ADJConfig *adjustConfig;

@end


@implementation MPKitAdjust

+ (void)setDelegate:(id)delegate {
    if (didSetKitDelegate) {
        NSLog(@"Warning: Adjust delegate can not be set because it is already in use by kit. \
              If you'd like to set your own delegate, please do so before you initialize mParticle.\
              Note: When setting your own delegate, you will not be able to use \
              `onAttributionComplete`.");
        return;
    } else {
        temporaryDelegate = (NSObject<AdjustDelegate> *)delegate;
    }
}

+ (NSNumber *)kitCode {
    return @68;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Adjust" className:@"MPKitAdjust"];
    [MParticle registerExtension:kitRegister];
}

#pragma mark MPKitInstanceProtocol methods
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;

    NSString *appToken = configuration[@"appToken"];
    if (!appToken) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }

    _configuration = configuration;
    NSString *adjEnvironment = [MParticle sharedInstance].environment == MPEnvironmentProduction ? ADJEnvironmentProduction : ADJEnvironmentSandbox;
    static dispatch_once_t adjustPredicate;
    
    

    dispatch_once(&adjustPredicate, ^{
        CFTypeRef adjustConfigRef = CFRetain((__bridge CFTypeRef)[ADJConfig configWithAppToken:appToken environment:adjEnvironment]);
        _adjustConfig = (__bridge ADJConfig *)adjustConfigRef;
        
        NSObject<AdjustDelegate> *delegate = nil;
        if (temporaryDelegate) {
            delegate = temporaryDelegate;
        } else {
            delegate = (NSObject<AdjustDelegate> *)self;
            didSetKitDelegate = YES;
        }
        
        _adjustConfig.delegate = delegate;
        
        [Adjust appDidLaunch:_adjustConfig];
        _started = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });

    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (id const)providerKitInstance {
    return [self started] ? _adjustConfig : nil;
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    [Adjust setEnabled:!optOut];

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAdjust) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [Adjust setDeviceToken:deviceToken];

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAdjust) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (NSError *)errorWithMessage:(NSString *)message {
    NSError *error = [NSError errorWithDomain:MPKitAPIErrorDomain code:0 userInfo:@{MPKitAdjustErrorKey:message}];
    return error;
}

- (void)adjustAttributionChanged:(nullable ADJAttribution *)attribution {
    NSDictionary *attributionDictionary = nil;
    
    if (attribution) {
        attributionDictionary = attribution.dictionary;
    } else {
        attributionDictionary = @{};
    }
    
    NSMutableDictionary *outerDictionary = [NSMutableDictionary dictionary];
    
    if (attributionDictionary) {
        outerDictionary[MPKitAdjustAttributionResultKey] = attributionDictionary;
    }
    
    MPAttributionResult *attributionResult = [[MPAttributionResult alloc] init];
    attributionResult.linkInfo = outerDictionary;
    
    [_kitApi onAttributionCompleteWithResult:attributionResult error:nil];
}


@end
