//
//  ApplicationSettings.m
//  Reports
//
//  Created by Michael Thomason on 11/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "ApplicationSettings.h"

NSString * const FILENAME = @"appsettings.asd";

@interface ApplicationSettings()

@property (nonatomic, retain) UIManagedDocumentPreferencesApplication *managedDocumentTrvApplicationData;

@end

@implementation ApplicationSettings

static ApplicationSettings *_sharedApplicationSettings = nil;

+ (void)initialize {
    _sharedApplicationSettings = [[super allocWithZone:NULL] init];

    NSURL *applicationSupportDirectory = [NSFileManager applicationSupportDirectoryUrl];
    NSURL *applicationDataFile = [applicationSupportDirectory URLByAppendingPathComponent: FILENAME];

    [UIManagedDocument openManagedDocumentAtUrl:applicationDataFile withCompletionHandler:^(id managedDocument, BOOL success) {
        if (success) {
            [_sharedApplicationSettings setManagedDocumentTrvApplicationData: managedDocument];
        }
    }];
    
}

+ (ApplicationSettings *)sharedSettings {
    return _sharedApplicationSettings;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedSettings] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

@end