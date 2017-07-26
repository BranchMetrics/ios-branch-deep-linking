//
//  BNCError.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 11/17/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCError.h"
#import "BNCLocalization.h"

NSString * const BNCErrorDomain = @"io.branch.sdk.error";

void BNCForceNSErrorCategoryToLoad(void) __attribute__((constructor));
void BNCForceNSErrorCategoryToLoad() {
    // Nothing here, but forces linker to load the category.
}

@implementation NSError (Branch)

+ (NSString*) messageForCode:(BNCErrorCode)code {

    // The order is important!

    static NSString* const messages[] = {
    
        // BNCInitError
        @"The Branch user session has not been initialized.",

        // BNCDuplicateResourceError
        @"A resource with this identifier already exists.",
        
        // BNCRedeemCreditsError
        @"You're trying to redeem more credits than are available. Have you loaded rewards?",

        // BNCBadRequestError
        @"The network request was invalid.",

        // BNCServerProblemError
        @"Trouble reaching the Branch servers, please try again shortly.",

        // BNCNilLogError
        @"Can't log error messages because the logger is set to nil.",

        // BNCVersionError
        @"Incompatible version.",

        // BNCNetworkServiceInterfaceError
        @"The underlying network service does not conform to the BNCNetworkOperationProtocol.",

        // BNCInvalidNetworkPublicKeyError
        @"Public key is not an SecKeyRef type.",

        // BNCContentIdentifierError
        @"A canonical identifier or title are required to uniquely identify content.",

        // BNCSpotlightNotAvailableError
        @"The Core Spotlight indexing service is not available on this device.",

        // BNCSpotlightTitleError
        @"Spotlight indexing requires a title.",

        // BNCRedeemZeroCreditsError
        @"Can't redeem zero credits.",
    };

    #define _countof(array) (sizeof(array)/sizeof(array[0]))

    // Sanity check
    if (_countof(messages) != (BNCHighestError - BNCInitError)) {
        [NSException raise:NSInternalInconsistencyException format:@"Branch error message count is wrong."];
        return @"Branch error.";
    }

    if (code < BNCInitError || code >= BNCHighestError)
        return @"Branch error.";

    return messages[code - BNCInitError];
}

+ (NSError*_Nonnull) branchErrorWithCode:(BNCErrorCode)errorCode
                           error:(NSError*)error
                         message:(NSString*_Nullable)message {

    NSMutableDictionary *userInfo = [NSMutableDictionary new];

    NSString *localizedString = BNCLocalizedString([self messageForCode:errorCode]);
    if (localizedString) userInfo[NSLocalizedDescriptionKey] = localizedString;

    NSString* localizedReason = BNCLocalizedString(message);
    if (localizedReason) userInfo[NSLocalizedFailureReasonErrorKey] = localizedReason;

    if (error) userInfo[NSUnderlyingErrorKey] = error;

    return [NSError errorWithDomain:BNCErrorDomain code:errorCode userInfo:userInfo];
}

+ (NSError*_Nonnull) branchErrorWithCode:(BNCErrorCode)errorCode {
    return [NSError branchErrorWithCode:errorCode error:nil message:nil];
}

+ (NSError*_Nonnull) branchErrorWithCode:(BNCErrorCode)errorCode error:(NSError*_Nullable)error {
    return [NSError branchErrorWithCode:errorCode error:error message:nil];
}

+ (NSError*_Nonnull) branchErrorWithCode:(BNCErrorCode)errorCode message:(NSString*_Nullable)message {
    return [NSError branchErrorWithCode:errorCode error:nil message:message];
}

@end
