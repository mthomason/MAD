//
//  CloudManager.h
//  Reports
//
//  Created by Michael Thomason on 8/4/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

NSString * const ICloudStateUpdatedNotification;
NSString * const UbiquitousContainerFetchingWillBeginNotification;
NSString * const UbiquitousContainerFetchingDidEndNotification;

@interface MACloudManager : NSObject

@property (nonatomic, assign) BOOL isCloudEnabled;
@property (nonatomic, retain, readonly) NSURL *dataDirectoryURL;
@property (nonatomic, retain, readonly) NSURL *documentsDirectoryURL;

- (NSURL *)documentsDataDirectoryURL;   //Only used in version 1.0 of designer.
+ (MACloudManager *)sharedManager;

@end
