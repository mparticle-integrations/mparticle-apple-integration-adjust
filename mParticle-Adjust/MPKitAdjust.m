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
#import "mParticle.h"
#import "MPKitExecStatus.h"
#import "MPKitRegister.h"
#import "Adjust.h"

@implementation MPKitAdjust

+ (NSNumber *)kitCode {
    return @68;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Adjust" className:@"MPKitAdjust" startImmediately:YES];
    [MParticle registerExtension:kitRegister];
}

#pragma mark MPKitInstanceProtocol methods
- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration startImmediately:(BOOL)startImmediately {
    self = [super init];
    NSString *appToken = configuration[@"appToken"];
    if (!self || !appToken) {
        return nil;
    }

    _configuration = configuration;
    NSString *adjEnvironment = [configuration[@"mpEnv"] integerValue] == MPEnvironmentProduction ? ADJEnvironmentProduction : ADJEnvironmentSandbox;
    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:appToken environment:adjEnvironment];
    [Adjust appDidLaunch:adjustConfig];
    _started = startImmediately;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });

    return self;
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
