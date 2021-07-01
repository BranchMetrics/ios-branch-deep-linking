//
//  BranchInstallRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchInstallRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BranchConstants.h"
#import "BNCEncodingUtils.h"
#import "BNCApplication.h"
#import "BNCAppleReceipt.h"
#import "BNCAppGroupsData.h"
#import "BNCPartnerParameters.h"

@implementation BranchInstallRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    return [super initWithCallback:callback isInstall:YES];
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    [self safeSetValue:[BNCSystemObserver getBundleID] forKey:BRANCH_REQUEST_KEY_BUNDLE_ID onDict:params];
    [self safeSetValue:[BNCSystemObserver getTeamIdentifier] forKey:BRANCH_REQUEST_KEY_TEAM_ID onDict:params];
    [self safeSetValue:[BNCSystemObserver getAppVersion] forKey:BRANCH_REQUEST_KEY_APP_VERSION onDict:params];
    [self safeSetValue:[BNCSystemObserver getDefaultUriScheme] forKey:BRANCH_REQUEST_KEY_URI_SCHEME onDict:params];
    [self safeSetValue:[NSNumber numberWithBool:preferenceHelper.checkedFacebookAppLinks]
        forKey:BRANCH_REQUEST_KEY_CHECKED_FACEBOOK_APPLINKS onDict:params];
    [self safeSetValue:[NSNumber numberWithBool:preferenceHelper.checkedAppleSearchAdAttribution]
        forKey:BRANCH_REQUEST_KEY_CHECKED_APPLE_AD_ATTRIBUTION onDict:params];
    [self safeSetValue:preferenceHelper.linkClickIdentifier forKey:BRANCH_REQUEST_KEY_LINK_IDENTIFIER onDict:params];
    [self safeSetValue:preferenceHelper.spotlightIdentifier forKey:BRANCH_REQUEST_KEY_SPOTLIGHT_IDENTIFIER onDict:params];
    [self safeSetValue:preferenceHelper.universalLinkUrl forKey:BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:params];
    [self safeSetValue:preferenceHelper.initialReferrer forKey:BRANCH_REQUEST_KEY_INITIAL_REFERRER onDict:params];
    [self safeSetValue:[[BNCAppleReceipt sharedInstance] installReceipt] forKey:BRANCH_REQUEST_KEY_APPLE_RECEIPT onDict:params];
    [self safeSetValue:[NSNumber numberWithBool:[[BNCAppleReceipt sharedInstance] isTestFlight]] forKey:BRANCH_REQUEST_KEY_APPLE_TESTFLIGHT onDict:params];
    
    if ([[BNCAppGroupsData shared] loadAppClipData]) {        
        [self safeSetValue:[BNCAppGroupsData shared].bundleID forKey:BRANCH_REQUEST_KEY_APP_CLIP_BUNDLE_ID onDict:params];
        [self safeSetValue:BNCWireFormatFromDate([BNCAppGroupsData shared].installDate) forKey:BRANCH_REQUEST_KEY_LATEST_APP_CLIP_INSTALL_TIME onDict:params];
        [self safeSetValue:[BNCAppGroupsData shared].url forKey:BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:params];
        [self safeSetValue:[BNCAppGroupsData shared].branchToken forKey:BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_DEVICE_TOKEN onDict:params];
        [self safeSetValue:[BNCAppGroupsData shared].bundleToken forKey:BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_BUNDLE_TOKEN onDict:params];
    }
    
    NSDictionary *partnerParameters = [[BNCPartnerParameters shared] parameterJson];
    if (partnerParameters.count > 0) {
        [self safeSetValue:partnerParameters forKey:BRANCH_REQUEST_KEY_PARTNER_PARAMETERS onDict:params];
    }
        
    params[BRANCH_REQUEST_KEY_DEBUG] = @(preferenceHelper.isDebug);

    if (preferenceHelper.appleSearchAdNeedsSend) {
        NSString *encodedSearchData = nil;
        @try {
            NSData *jsonData = [BNCEncodingUtils encodeDictionaryToJsonData:preferenceHelper.appleSearchAdDetails];
            encodedSearchData = [BNCEncodingUtils base64EncodeData:jsonData];
        } @catch (id) { }
        [self safeSetValue:encodedSearchData
                    forKey:BRANCH_REQUEST_KEY_SEARCH_AD
                    onDict:params];
    }
    
    NSString *appleAttributionToken = [BNCSystemObserver appleAttributionToken];
    if (appleAttributionToken) {
        preferenceHelper.appleAttributionTokenChecked = YES;
        [self safeSetValue:appleAttributionToken forKey:BRANCH_REQUEST_KEY_APPLE_ATTRIBUTION_TOKEN onDict:params];
    }

    BNCApplication *application = [BNCApplication currentApplication];
    params[@"lastest_update_time"] = BNCWireFormatFromDate(application.currentBuildDate);
    params[@"previous_update_time"] = BNCWireFormatFromDate(preferenceHelper.previousAppBuildDate);
    params[@"latest_install_time"] = BNCWireFormatFromDate(application.currentInstallDate);
    params[@"first_install_time"] = BNCWireFormatFromDate(application.firstInstallDate);
    params[@"update"] = [self.class appUpdateState];

    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_INSTALL] key:key callback:callback];
}

- (NSString *)getActionName {
    return @"install";
}

@end
