//
//  ApplicationSettings.h
//  Reports
//
//  Created by Michael Thomason on 11/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSFileManager+Common.h"
#import "UIManagedDocument+FileOperations.h"
#import "UIManagedDocumentPreferencesApplication.h"

@interface ApplicationSettings : NSObject

+ (ApplicationSettings *)sharedSettings;

@end