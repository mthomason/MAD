//
//  MADOperationUniqueUrlForFilename.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/27/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationUniqueUrlForFilename.h"
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSPathUtilities.h>
#import <MADFileManager/MADFileUtilities.h>

@interface MADOperationUniqueUrlForFilename ()

    @property (nonatomic, copy) NSString *desiredFilename;
    @property (nonatomic, copy) NSString *pathExtension;
    @property (nonatomic, copy) NSURL *documentsDirectory;
    @property (nonatomic, copy, readwrite) NSURL *uniqueUrl;

@end

@implementation MADOperationUniqueUrlForFilename

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
    NSString *filename = [self.desiredFilename stringByAppendingPathExtension:self.pathExtension];
    NSURL *desiredUrl = [self.documentsDirectory URLByAppendingPathComponent: filename isDirectory:NO];
    NSURL *uniqueUrl = [MADFileUtilities uniqueURLForURL: desiredUrl];
    self.uniqueUrl = uniqueUrl;
}

@end
