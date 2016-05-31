//
//  NSURL+ConvenienceConstructors.m
//  MADFileManager
//
//  Created by Michael Thomason on 5/31/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "NSURL+ConvenienceConstructors.h"
#import "NSURL+CommonURLs.h"

@implementation NSURL (ConvenienceConstructors)

+ (NSURL *)newURLLocalDocumentWithName:(NSString *)name
                             extention:(NSString *)extention
                             fileGroup:(NSString *)fileGroup {
    NSURL *url = [NSURL newURLLocalDocumentsDirectoryForGroupIdentifier:fileGroup];
    NSURL *documentURLWithoutExtension = [url URLByAppendingPathComponent:name];
    return [documentURLWithoutExtension URLByAppendingPathExtension:extention];
}

@end
