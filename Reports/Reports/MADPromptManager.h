//
//  MADPromptManager.h
//  MAD
//
//  Created by Michael Thomason on 9/9/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADPromptManager_h
#define Reports_MADPromptManager_h

#import <Foundation/Foundation.h>

@interface MADPromptManager : NSObject

@property (nonatomic, strong) NSString *prompt;
@property (nonatomic, strong, readonly) NSString *defaultPrompt;

- (instancetype)initWithDefaultPrompt:(NSString *)defaultPrompt NS_DESIGNATED_INITIALIZER;

- (void)addString:(NSString *)string;
- (void)removeString:(NSString *)string;
- (void)removeAll;

@end

#endif
