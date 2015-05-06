//
//  MADFileUtilities.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MADList;
@interface MADFileUtilities : NSObject

+ (NSURL *)localDocumentsDirectory:(NSString *)groupIdentifier;

+ (void)copyInitialFiles:(NSString *)fileExtension groupId:(NSString *)groupId;

+ (void)migrateLocalListsToCloud:(NSString *)groupIdentifier;

+ (void)readListAtURL:(NSURL *)url withCompletionHandler:(void (^)(MADList *list, NSError *error))completionHandler;

+ (void)createList:(MADList *)list atURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *error))completionHandler;

+ (void)removeListAtURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *error))completionHandler;


@end
