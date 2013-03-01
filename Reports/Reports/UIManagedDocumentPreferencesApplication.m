//
//  UIManagedDocumentTrvApplicationData.m
//  Reports
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIManagedDocumentPreferencesApplication.h"

@implementation UIManagedDocumentPreferencesApplication

+ (NSString *)persistentStoreName {
    return APPLICATIONDATA_FILENAME;
}

@end
