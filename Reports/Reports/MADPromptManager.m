//
//  MADPromptManager.m
//  MAD
//
//  Created by Michael Thomason on 9/9/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADPromptManager.h"

@interface MADPromptManager ()

@property (nonatomic, strong, readwrite) NSMutableArray *promptItems;

@end

@implementation MADPromptManager

- (instancetype)init {
    self = [super init];
    if (self) {
        
        NSMutableArray *promptItems = [[NSMutableArray alloc] init];
        self.promptItems = promptItems;
        
    }
    return self;
}

- (void)addString:(NSString *)string {
    [self.promptItems insertObject:string atIndex:0];
    [self updatePrompt];
}

- (void)removeString:(NSString *)string {
    NSUInteger i = [self.promptItems indexOfObjectIdenticalTo:string];
    [self.promptItems removeObjectAtIndex:i];
    [self updatePrompt];
}

- (void)removeAll {
    [self.promptItems removeAllObjects];
    [self updatePrompt];
}

- (void)updatePrompt {
    NSMutableString *prompt = [[NSMutableString alloc] init];
    NSUInteger i = 0;
    if (self.promptItems.count > 0) {
        for (NSString *string in self.promptItems) {
            if (i > 0) {
                [prompt appendString:@", "];
            }
            [prompt appendString:string];
            i++;
        }
        self.prompt = prompt;
    } else {
        self.prompt = nil;
    }
}

@end
