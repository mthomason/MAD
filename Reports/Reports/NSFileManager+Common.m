//
//  NSFileManager-Common.m
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSFileManager+Common.h"
#import "NSURL+Document.h"
#import "MACloudManager.h"
#import "MTLog.h"

@implementation NSFileManager (Common)

+ (NSMutableArray *)contentsOfDocumentsDirectory {
    NSMutableArray *doc = [[NSMutableArray array] retain];
    NSString *documentsDirectoryPath = [[NSFileManager applicationDocumentsDirectory] retain];
	NSArray *documentsDirectoryContents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL] retain];

    [documentsDirectoryContents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *filePath = [[documentsDirectoryPath stringByAppendingPathComponent:obj] retain];
		NSURL *fileURL = [[NSURL fileURLWithPath:filePath] retain];
		BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        if (!isDirectory){
            [doc addObject:fileURL];
        }
        [fileURL release];
        [filePath release];
        
    }];
        
    [documentsDirectoryContents release];
    [documentsDirectoryPath release];
    return [doc autorelease];
}


+ (NSMutableArray *)contentsOfDocumentsDataDirectoryWithPathExtension:(NSString *)extension {
    NSURL *documentsDataDirectory = [[MACloudManager sharedManager] documentsDataDirectoryURL];
    return [NSFileManager contentsOfDirectory:[documentsDataDirectory path] withPathExtension:extension];
}

+ (NSMutableArray *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension {
    return [NSFileManager contentsOfDirectory:[NSFileManager applicationDocumentsDirectory] withPathExtension:extension];
}

+ (NSMutableArray *)contentsOfDirectory:(NSString *)directory withPathExtension:(NSString *)extension {
    NSString *directoryPath = [directory retain];
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
	NSArray *directoryContents = [defaultFileManager contentsOfDirectoryAtPath:directory error:&error];
    for (NSString *filename in directoryContents) {
        @autoreleasepool {
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:filename];
            NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
            BOOL isDirectory;
            NSString *filePath = [fileURL path];
            if ([defaultFileManager fileExistsAtPath:filePath isDirectory:&isDirectory]) {
                NSString *pathExtension = [fileURL pathExtension];
                if ([pathExtension isEqualToString:extension]) {
                    [result addObject:fileURL];
                }
            }
        }
    }
    [directoryPath release];
    return [result autorelease];
}

+ (BOOL)createDirectoryForUrlIfItDoesNotExist:(NSURL *)url {
    NSError *error = nil;
    BOOL directoryGood = [[NSFileManager defaultManager] createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil) {
        directoryGood = NO;
        NSAssert(error, @"Error creating directory!  %@", error);
    }
    return directoryGood;
}

+ (NSString *)applicationSupportDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSURL *)localTemporaryDirectory {
    return  [[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES] URLByAppendingPathComponent:@"tmp" isDirectory:YES];
}

+ (NSString *)applicationLibraryTemplatesDirectory {
    NSString *applicationLibrary = [[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:TEMPLATES] retain];
    if (![[NSFileManager defaultManager] fileExistsAtPath:applicationLibrary]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:applicationLibrary withIntermediateDirectories:YES attributes:nil error:&error];   
    }
	return [applicationLibrary autorelease];
}

+ (void)wrapFile:(NSURL *)fileToAttach withExtention:(NSString *)extention overwrite:(BOOL)overwrite completion:(void (^)(BOOL success, NSURL *resultUrl))completion {
    NSURL *resultUrl = nil;
    NSError *fileWrapperError = nil;
    BOOL success = NO;
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL: fileToAttach
                                                            options: NSFileWrapperReadingImmediate
                                                              error: &fileWrapperError];
    
    if (fileWrapperError == nil) {
        NSString *fileName = [[fileToAttach lastPathComponent] stringByDeletingPathExtension];
        if (overwrite) {
            fileName = [fileName stringByAppendingPathExtension:extention];
            resultUrl = [[[[MACloudManager sharedManager] documentsDirectoryURL] URLByAppendingPathComponent:fileName isDirectory:NO] retain];
            NSData *data = [fileWrapper serializedRepresentation];
            NSError *errorWriting = nil;
            success = [data writeToURL:resultUrl options:NSDataWritingAtomic error:&errorWriting];
            if (errorWriting != nil) {
                MTLog(@"%@", errorWriting);
            }
        } else {
            resultUrl = [[NSURL uniqueUrlForDocumentWithName:fileName
                                               withExtension:extention] retain];
            NSData *data = [[fileWrapper serializedRepresentation] retain];
            success = [data writeToURL:resultUrl atomically:YES];
            [data release];
        }
    }
    [fileWrapper release];
    if (completion != NULL) {
        completion(success, [resultUrl autorelease]);
    } else {
        [resultUrl autorelease];
    }
}

@end