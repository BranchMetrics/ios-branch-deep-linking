//
//  BNCUserAgentCollector.m
//  Branch
//
//  Created by Ernest Cho on 8/29/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCUserAgentCollector.h"
#import "BNCPreferenceHelper.h"
#import "BNCDeviceSystem.h"
@import WebKit;

@interface BNCUserAgentCollector()
// need to hold onto the webview until the async user agent fetch is done
@property (nonatomic, strong, readwrite) WKWebView *webview;
@end

@implementation BNCUserAgentCollector

+ (BNCUserAgentCollector *)instance {
    static BNCUserAgentCollector *collector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        collector = [BNCUserAgentCollector new];
    });
    return collector;
}

- (void)loadUserAgentWithCompletion:(void (^)(NSString *userAgent))completion {
    
    // if the system build version changes, then the WebView might have been updated
    __block NSString *systemBuildVersion = [BNCDeviceSystem sharedInstance].systemBuildVersion;

    NSString *savedUserAgent = [self loadUserAgentForSystemBuildVersion:systemBuildVersion];
    if (savedUserAgent) {
        self.userAgent = savedUserAgent;
        if (completion) {
            completion(savedUserAgent);
        }
    } else {
        [self collectUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
            self.userAgent = userAgent;
            [self saveUserAgent:userAgent forSystemBuildVersion:systemBuildVersion];
            if (completion) {
                completion(userAgent);
            }
        }];
    }
}

// load user agent from preferences
- (NSString *)loadUserAgentForSystemBuildVersion:(NSString *)systemBuildVersion {
    
    NSString *userAgent = nil;
    BNCPreferenceHelper *preferences = [BNCPreferenceHelper preferenceHelper];
    NSString *savedUserAgent = [preferences.browserUserAgentString copy];
    NSString *savedSystemBuildVersion = [preferences.lastSystemBuildVersion copy];
    
    if (savedUserAgent && [systemBuildVersion isEqualToString:savedSystemBuildVersion]) {
        userAgent = savedUserAgent;
    }
    
    return userAgent;
}

// save user agent to preferences
- (void)saveUserAgent:(NSString *)userAgent forSystemBuildVersion:(NSString *)systemBuildVersion {
    if (userAgent && systemBuildVersion) {
        BNCPreferenceHelper *preferences = [BNCPreferenceHelper preferenceHelper];
        preferences.browserUserAgentString = userAgent;
        preferences.lastSystemBuildVersion = systemBuildVersion;
    }
}

// collect user agent from webkit.  this is expensive.
- (void)collectUserAgentWithCompletion:(void (^)(NSString *userAgent))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.webview) {
            self.webview = [[WKWebView alloc] initWithFrame:CGRectZero];
        }
        
        [self.webview evaluateJavaScript:@"navigator.userAgent;" completionHandler:^(id _Nullable response, NSError * _Nullable error) {            
            if (completion) {
                if (response) {
                    // release the webview
                    self.webview = nil;
                    
                    completion(response);
                } else {
                    // retry if we failed to obtain user agent.  This occasionally occurs on simulator.
                    [self collectUserAgentWithCompletion:completion];
                }
            }
        }];
    });
}

@end
