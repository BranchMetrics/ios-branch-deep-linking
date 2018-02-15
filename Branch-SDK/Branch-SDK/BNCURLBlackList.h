/**
 @file          BNCURLBlackList.h
 @package       Branch-SDK
 @brief         Manages a list of URLs that we should ignore.

 @author        Edward Smith
 @date          February 14, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

@interface BNCURLBlackList : NSObject

/**
 @brief         Checks if a given URL should be ignored (blacklisted).

 @param url     The URL to be checked.
 @return        Returns true if the provided URL should be ignored.
*/
- (BOOL) isBlackListedURL:(NSURL*_Nullable)url;

/// Refreshes the list of ignored URLs from the server.
- (void) refreshBlackListFromServerWithCompletion:(void (^_Nullable) (NSError*_Nullable error, NSArray*_Nullable list))completion;

/// Is YES if the listed has already been updated from the server.
@property (assign, readonly) BOOL hasRefreshedBlackListFromServer;

@end
