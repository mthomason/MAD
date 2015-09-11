//
//  MADAppLaunchContext.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADAppLaunchContext.h"
#import <UIKit/UIKit.h>

NSString * const MADAppConfigurationUserActivityListURLPathUserInfoKey = @"MADUserInfoKeyFileURL";

@implementation MADAppLaunchContext

- (instancetype)initWithUserActivity:(NSUserActivity *)userActivity {
    self = [super init];
    
    if (self) {
        NSParameterAssert(userActivity.userInfo != nil);
        /*
         The URL may be provided as either a URL or a URL path via separate keys. Check first for
         `NSUserActivityDocumentURLKey`, if not provided, obtain the path and create a file URL from it.
         */
        _fileURL = userActivity.userInfo[NSUserActivityDocumentURLKey];
        
        if (!_fileURL) {
            NSString *listInfoFilePath = userActivity.userInfo[MADAppConfigurationUserActivityListURLPathUserInfoKey];
            
            NSAssert(listInfoFilePath != nil, @"The `userInfo` dictionary provided did not contain a URL or a URL path.");
            
            _fileURL = [NSURL fileURLWithPath:listInfoFilePath isDirectory:NO];
        }
        
        NSAssert(_fileURL != nil, @"`listURL must not be `nil`.");
        
//        NSNumber *listInfoColorNumber = userActivity.userInfo[AAPLAppConfigurationUserActivityListColorUserInfoKey];
        
    //    NSAssert(listInfoColorNumber != nil && listInfoColorNumber.integerValue >= 0 && listInfoColorNumber.integerValue < 6, @"The `userInfo` dictionary provided contains an invalid entry for the list color.");
        // Set the `listColor` by converting the `NSNumber` to an NSInteger and casting to `AAPLListColor`.
    //    _listColor = (AAPLListColor)listInfoColorNumber.integerValue;
    }
    
    return self;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL {
    self = [super init];
    
    if (self) {
        NSParameterAssert(fileURL.scheme != nil && [fileURL.scheme isEqualToString:@"lister"]);
        
        NSParameterAssert(fileURL.path != nil);
        // Construct a file URL from the path of the lister:// URL.
        _fileURL = [NSURL fileURLWithPath:fileURL.path isDirectory:NO];
        
        NSAssert(_fileURL != nil, @"`listURL must not be `nil`.");
        
        // Extract the query items to initialize the `listColor` property from the `color` query item.
        //NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:listerURL resolvingAgainstBaseURL:NO];
        //NSArray *queryItems = urlComponents.queryItems;
        
        // Construct a predicate to extract the `color` query item.
        //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", AAPLAppConfigurationListerColorQueryKey];
        //NSArray *colorQueryItems = [queryItems filteredArrayUsingPredicate:predicate];
        
        //NSAssert(colorQueryItems.count == 1, @"URL provided should contain only one `color` query item.");
        
        //NSURLQueryItem *colorQueryItem = colorQueryItems.firstObject;
        
        //NSAssert(colorQueryItem.value != nil, @"URL provided contains an invalid value for `color`.");
        // Set the `listColor` by converting the `NSString` value to an NSInteger and casting to `AAPLListColor`.
        //_listColor = colorQueryItem.value.integerValue;
    }
    
    return self;
}

@end
