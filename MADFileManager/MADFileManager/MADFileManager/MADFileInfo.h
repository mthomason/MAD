//
//  MADFileInfo.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADFileInfo_h
#define MADDesigner_MADFileInfo_h

#import <Foundation/NSObject.h>

@interface MADFileInfo : NSObject

    @property (nonatomic, copy, readonly) NSURL *URL;
    @property (readonly) NSString *name;

    - (instancetype)initWithURL:(NSURL *)URL;
    - (void)fetchInfoWithCompletionHandler:(void (^)(void))completionHandler;

@end

#endif
