//
//  NSFileManager-Common.m
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSFileManager+Common.h"

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
    BOOL directoryGood;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *urlsForDirectory = [[NSArray alloc] initWithArray:[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]];
    applicationDocumentDirectory = [[urlsForDirectory lastObject] retain];
    directoryGood = [NSFileManager createDirectoryForUrlIfItDoesNotExist:applicationDocumentDirectory];
    [urlsForDirectory release];
    return directoryGood ? [applicationDocumentDirectory autorelease] : nil;
}

+ (NSURL *)applicationSupportDirectoryUrl {
    NSURL *applicationSupportDirectory;
    BOOL directoryGood;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *urlsForDirectory = [[NSArray alloc] initWithArray:[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask]];
    applicationSupportDirectory = [[urlsForDirectory lastObject] retain];
    directoryGood = [NSFileManager createDirectoryForUrlIfItDoesNotExist:applicationSupportDirectory];
    [urlsForDirectory release];
    return directoryGood ? [applicationSupportDirectory autorelease] : nil;
}

+ (NSURL *)applicationLibraryTemplatesDirectoryUrl {
    NSURL *applicationLibraryDirectory;
    BOOL directoryGood;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *urlsForDirectory = [[NSArray alloc] initWithArray:[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask]];
    NSURL *lastObject = [[urlsForDirectory lastObject] retain];
    applicationLibraryDirectory = [lastObject URLByAppendingPathComponent:TEMPLATES];
    directoryGood = [NSFileManager createDirectoryForUrlIfItDoesNotExist:applicationLibraryDirectory];
    [urlsForDirectory release];
    return directoryGood ? [applicationLibraryDirectory autorelease] : nil;
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

+ (NSString *)applicationLibraryTemplatesDirectory {
    NSString *applicationLibrary = [[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:TEMPLATES] retain];
    if (![[NSFileManager defaultManager] fileExistsAtPath:applicationLibrary]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:applicationLibrary withIntermediateDirectories:YES attributes:nil error:&error];   
    }
	return [applicationLibrary autorelease];
}

@end