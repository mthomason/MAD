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

	for (NSString* curFileName in [documentsDirectoryContents objectEnumerator]){
		NSString *filePath = [[documentsDirectoryPath stringByAppendingPathComponent:curFileName] retain];
        
		NSURL *fileURL = [[NSURL fileURLWithPath:filePath] retain];
		BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        //FIXME
        if (!(isDirectory /*&& [curFileName isEqualToString: @"Inbox"]*/)){//é um arquivo normal
            [doc addObject:fileURL];
        }else{//é a pasta inbox
            NSError *error;
            NSString *arquivoNaInbox=[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:&error] objectAtIndex:0];//pega o arquivo que esta dentro dela
            NSString *arquivoNaInboxPath=[NSString stringWithFormat:@"%@/%@",filePath,arquivoNaInbox];
            if ( [[NSFileManager defaultManager] fileExistsAtPath:arquivoNaInboxPath]){
                NSString *toURL=[NSString stringWithFormat:@"%@/%@",[NSFileManager applicationDocumentsDirectory],arquivoNaInbox];
                if ([[NSFileManager defaultManager] moveItemAtPath:arquivoNaInboxPath toPath:toURL error:&error]) {//move o arquivo
                    [[NSFileManager defaultManager]removeItemAtPath:filePath error:&error];//deleta a pasta
                    NSURL *fileInboxURL = [NSURL fileURLWithPath:toURL];
                    [doc addObject:fileInboxURL];
                }
            }
        }
        [fileURL release];
        [filePath release];
	}
    
    [documentsDirectoryContents release];
    [documentsDirectoryPath release];
    return [doc autorelease];
}

+ (NSArray *)contentsOfPrivateDirectory {
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSFileManager applicationPrivateDocumentsDirectory] error:NULL];
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