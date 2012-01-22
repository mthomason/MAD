//
//  NSFileManager-Common.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSFileManager+Common.h"
#import "Constants.h"

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
        //FIXME
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
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory] &&
            [[fileURL pathExtension] isEqualToString:extension]) {
            
            [result addObject:fileURL];

        }
        
        [fileURL release];
        [filePath release];
    }];
    
    [directoryContents release];
    return [result autorelease];
}

+ (NSURL *)applicationDocumentsDirectoryUrl {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSURL *)applicationSupportDirectoryUrl {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSURL *)applicationLibraryTemplatesDirectoryUrl {
    NSURL *applicationLibrary = [[[[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:TEMPLATES] retain];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[applicationLibrary path]]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:[applicationLibrary path] withIntermediateDirectories:YES attributes:nil error:&error];   
    }
	return [applicationLibrary autorelease];
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