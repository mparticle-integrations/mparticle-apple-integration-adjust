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

@interface MPKitAdjust()

@property (nonatomic, strong) ADJConfig *adjustConfig;

@end


@implementation MPKitAdjust

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
    NSString *adjEnvironment = [configuration[@"mpEnv"] integerValue] == MPEnvironmentProduction ? ADJEnvironmentProduction : ADJEnvironmentSandbox;
    static dispatch_once_t adjustPredicate;

    dispatch_once(&adjustPredicate, ^{
        CFTypeRef adjustConfigRef = CFRetain((__bridge CFTypeRef)[ADJConfig configWithAppToken:appToken environment:adjEnvironment]);
        _adjustConfig = (__bridge ADJConfig *)adjustConfigRef;
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

@end
