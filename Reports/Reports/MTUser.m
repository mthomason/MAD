//
//  MTUser.m
//  MAD
//
//  Created by Michael Thomason on 3/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTUser.h"
#import "NSFileManager+Common.h"

@interface MTUser()

@end

@implementation MTUser

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSArray *)hasMadDocuments {
    NSSet *madFiles = [NSFileManager contentsOfDocumentsDirectoryWithPathExtension: MTDocumentExtentionMobleApplicationDocument];
    SEL selectorPath = @selector(path);
    SEL selectorSort = @selector(caseInsensitiveCompare:);
    NSString *key = NSStringFromSelector(selectorPath);
    NSSortDescriptor *sortByFileName = [NSSortDescriptor sortDescriptorWithKey:key ascending:YES selector:selectorSort];
    NSArray *sortDescriptors = @[sortByFileName];
    return [[[madFiles sortedArrayUsingDescriptors:sortDescriptors] retain] autorelease];
}

@end
