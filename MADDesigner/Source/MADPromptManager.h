//
//  MADPromptManager.h
//  MAD
//
//  Created by Michael Thomason on 9/9/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADPromptManager_h
#define Reports_MADPromptManager_h

#import <Foundation/NSObject.h>

@interface MADPromptManager : NSObject

@property (nonatomic, strong) NSString *prompt;
@property (nonatomic, strong, readonly) NSString *defaultPrompt;

- (instancetype)initWithDefaultPrompt:(NSString *)defaultPrompt;

- (void)addString:(NSString *)string;
- (void)removeString:(NSString *)string;
- (void)removeAll;

@end

#endif
