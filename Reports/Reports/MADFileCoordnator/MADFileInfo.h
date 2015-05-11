//
//  MADFileInfo.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADFileInfo : NSObject

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, strong, readonly) NSURL *URL;

@property (nonatomic, copy, readonly) NSString *name;

- (void)fetchInfoWithCompletionHandler:(void (^)(void))completionHandler;

@end
