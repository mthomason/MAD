//
//  MADPromptManager.h
//  MAD
//
//  Created by Michael Thomason on 9/9/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADPromptManager : NSObject

@property (nonatomic, strong) NSString *prompt;

- (void)addString:(NSString *)string;
- (void)removeString:(NSString *)string;
- (void)removeAll;

@end
