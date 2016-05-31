//
//  NSURL+ConvenienceConstructors.h
//  MADFileManager
//
//  Created by Michael Thomason on 5/31/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (ConvenienceConstructors)

+ (NSURL *)newURLLocalDocumentWithName:(NSString *)name
                             extention:(NSString *)extention
                             fileGroup:(NSString *)fileGroup;

@end
