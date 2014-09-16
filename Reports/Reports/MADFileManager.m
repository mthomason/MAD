//
//  MADFileManager
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADFileManager.h"

NSString * const MADFileManagerOpenUrl      = @"MADFileManagerOpenUrl";
NSString * const MADFileManagerOpenFiles    = @"MADFileManagerOpenFiles";

@implementation MADFileManager

- (instancetype)init {
    self = [super init];
    if (self) {
        NSMutableDictionary *openFiles = [NSMutableDictionary new];
        self.openFiles = openFiles;
        self.openUrl = nil;
    }
    return self;
}

@end
