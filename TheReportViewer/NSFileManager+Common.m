//
//  NSFileManager-Common.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
    NSMutableArray *doc = [[NSMutableArray array] retain];
    NSString *documentsDirectoryPath = [[NSFileManager applicationDocumentsDirectory] retain];
	NSArray *documentsDirectoryContents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL] retain];
    
    [documentsDirectoryContents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSString *filePath = [[documentsDirectoryPath stringByAppendingPathComponent:obj] retain];
        
		NSURL *fileURL = [[NSURL fileURLWithPath:filePath] retain];
		BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        if ([[fileURL pathExtension] isEqualToString:extension]) {
            [doc addObject:fileURL];
        }
        [fileURL release];
        [filePath release];
    }];
    
    [documentsDirectoryContents release];
    [documentsDirectoryPath release];
    return [doc autorelease];
}

+ (NSArray *)contentsOfPrivateDirectory {
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSFileManager applicationPrivateDocumentsDirectory] error:NULL];
}

+ (NSURL *)applicationDocumentsDirectoryUrl {
    NSArray *directories = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask ] retain];
    NSURL *result = [[[directories lastObject] retain] autorelease];
    [directories release];
    return result;
}

+ (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)applicationPrivateDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *privateDict = [paths objectAtIndex:0];
    privateDict = [privateDict stringByAppendingPathComponent:@"Private Documents"];
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:privateDict withIntermediateDirectories:YES attributes:nil error:&error];   
	return privateDict;
}

@end