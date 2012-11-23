//
//  NSURL+Document.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSFileManager+Common.h"

@interface NSURL (Document)

+ (NSURL *)uniqueUrlForDocumentWithName:(NSString *)name withExtension:(NSString *)extension;

@end