//
//  BranchCreditHistoryRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchCreditHistoryRequest.h"
#import "BNCPreferenceHelper.h"

@interface BranchCreditHistoryRequest ()

@property (strong, nonatomic) callbackWithList callback;
@property (strong, nonatomic) NSString *bucket;
@property (strong, nonatomic) NSString *creditTransactionId;
@property (assign, nonatomic) NSInteger length;
@property (assign, nonatomic) BranchCreditHistoryOrder order;

@end

@implementation BranchCreditHistoryRequest

- (id)initWithBucket:(NSString *)bucket creditTransactionId:(NSString *)creditTransactionId length:(NSInteger)length order:(BranchCreditHistoryOrder)order callback:(callbackWithList)callback {
    if (self = [super init]) {
        _bucket = bucket;
        _creditTransactionId = creditTransactionId;
        _length = length;
        _order = order;
        _callback = callback;
    }

    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    params[@"device_fingerprint_id"] = [BNCPreferenceHelper getDeviceFingerprintID];
    params[@"identity_id"] = [BNCPreferenceHelper getIdentityID];
    params[@"session_id"] = [BNCPreferenceHelper getSessionID];
    params[@"length"] = @(self.length);
    params[@"direction"] = self.order == BranchMostRecentFirst ? @"desc" : @"asc";

    if (self.bucket) {
        params[@"bucket"] = self.bucket;
    }
    
    if (self.creditTransactionId) {
        params[@"begin_after_id"] = self.creditTransactionId;
    }
    
    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:@"credithistory"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(nil, error);
        }
        return;
    }
    
    for (NSMutableDictionary *transaction in response.data) {
        if (transaction[@"referrer"] == [NSNull null]) {
            [transaction removeObjectForKey:transaction[@"referrer"]];
        }
        if (transaction[@"referree"] == [NSNull null]) {
            [transaction removeObjectForKey:@"referree"];
        }
    }
    
    if (self.callback) {
        self.callback(response.data, nil);
    }
}

@end
