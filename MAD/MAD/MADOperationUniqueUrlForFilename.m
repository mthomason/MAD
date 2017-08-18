//
//  MADOperationUniqueUrlForFilename.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/27/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import <os/log.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSError.h>
#import <Foundation/NSPathUtilities.h>
#import "MADOperationUniqueUrlForFilename.h"
#import <MADFoundation/MADURL.h>

@interface MADOperationUniqueUrlForFilename ()

    @property (nonatomic, copy) NSString *desiredFilename;
    @property (nonatomic, copy) NSString *pathExtension;
    @property (nonatomic, copy) NSURL *documentsDirectory;
    @property (nonatomic, copy, readwrite) NSURL *uniqueUrl;

@end

@implementation MADOperationUniqueUrlForFilename

- (void)dealloc {
    //os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (instancetype)initWithDesiredFilename:(NSString *)filename pathExtension:(NSString *)pathExtension
                  andDocumentsDirectory:(NSURL *)documentsDirectory {
    if (self = [super init]) {
        _desiredFilename = filename.copy;
        _pathExtension = pathExtension.copy;
        _documentsDirectory = documentsDirectory.copy;
    }
    return self;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)execute {
    //os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);

    if (self.cancelled) {
        return [self finish];
    }

    NSURL *uniqueUrl = [MADURL newURLUniqueUrlInDirectory: self.documentsDirectory
                                        withDesiredHandle: self.desiredFilename
                                             andExtension: self.pathExtension];


    if (uniqueUrl != nil) {
        self.uniqueUrl = uniqueUrl;
        [self finish];
    } else {
        NSString *domain = NSStringFromClass(self.class);
        NSError *error = [NSError errorWithDomain:domain code:389 userInfo:nil];
        [self finishWithError:error];
    }
    
}

@end
