//
//  NSFileManager-Common.m
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSFileManager+Common.h"
#import "MACloudManager.h"

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

+ (NSMutableArray *)contentsOfTemplateDirectoryWithPathExtension:(NSString *)extension {
    return [NSFileManager contentsOfDirectory:[NSFileManager applicationLibraryTemplatesDirectory] withPathExtension:extension];
}

+ (NSMutableArray *)contentsOfApplicationSupportDirectoryWithPathExtension:(NSString *)extension {
    return [NSFileManager contentsOfDirectory:[NSFileManager applicationSupportDirectory] withPathExtension:extension];
}

+ (NSMutableArray *)contentsOfDirectory:(NSString *)directory withPathExtension:(NSString *)extension {
    NSMutableArray *result = [[NSMutableArray array] retain];
	NSArray *directoryContents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL] retain];
    
    [directoryContents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

		NSString *filePath = [[directory stringByAppendingPathComponent:obj] retain];
		NSURL *fileURL = [[NSURL fileURLWithPath:filePath] retain];
		BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory]) {
            if ([[fileURL pathExtension] isEqualToString:extension]) {
                [result addObject:fileURL];
            }

        }
        
        [fileURL release];
        [filePath release];
    }];
    
    [directoryContents release];
    return [result autorelease];
}

+ (NSURL *)applicationDocumentsDirectoryUrl {
    NSURL *applicationDocumentDirectory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *urlsForDirectory = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    applicationDocumentDirectory = [urlsForDirectory lastObject];
    [NSFileManager createDirectoryForUrlIfItDoesNotExist:applicationDocumentDirectory];
    return applicationDocumentDirectory;
}

+ (NSURL *)applicationSupportDirectoryUrl {
    NSURL *applicationSupportDirectory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *urlsForDirectory = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    applicationSupportDirectory = [urlsForDirectory lastObject];
    [NSFileManager createDirectoryForUrlIfItDoesNotExist:applicationSupportDirectory];
    return applicationSupportDirectory;
}

+ (NSURL *)applicationLibraryTemplatesDirectoryUrl {
    NSURL *applicationLibraryDirectory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *urlsForDirectory = [fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    NSURL *lastObject = [urlsForDirectory lastObject];
    applicationLibraryDirectory = [lastObject URLByAppendingPathComponent:TEMPLATES];
    [NSFileManager createDirectoryForUrlIfItDoesNotExist:applicationLibraryDirectory];
    return applicationLibraryDirectory;
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

@end