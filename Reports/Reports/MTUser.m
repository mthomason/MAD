//
//  MTUser.m
//  MAD
//
//  Created by Michael Thomason on 3/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTUser.h"
#import "NSFileManager+Common.h"
#import "NSURL+Document.h"
#import "NSError+UserInterface.h"
#import "Constants.h"

@interface MTUser()

@end

@implementation MTUser

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSArray *)hasMadDocuments {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSSet *madFiles = [fileManager contentsOfDocumentsDirectoryWithPathExtension: MTDocumentExtentionMobleApplicationDocument];
    SEL selectorPath = @selector(path);
    SEL selectorSort = @selector(localizedStandardCompare:);
    NSString *key = NSStringFromSelector(selectorPath);
    NSSortDescriptor *sortByFileName = [NSSortDescriptor sortDescriptorWithKey:key ascending:YES selector:selectorSort];
    NSArray *sortDescriptors = @[sortByFileName];
    return [madFiles sortedArrayUsingDescriptors:sortDescriptors];
}

- (BOOL)addDocument:(NSURL *)url error:(NSError **)error {
    NSString *openDocumentName = [[url lastPathComponent] stringByDeletingPathExtension];
    NSString *openDocumentExt = [url pathExtension];
    NSURL *destinationUrl = [NSURL uniqueUrlForDocumentWithName:openDocumentName withExtension:openDocumentExt];
    [[NSFileManager defaultManager] moveItemAtURL:url toURL:destinationUrl error:error];
    return error == nil;
}



@end
