//
//  MADPromptManager.m
//  MAD
//
//  Created by Michael Thomason on 9/9/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADPromptManager.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>

@interface MADPromptManager ()

@property (nonatomic, strong, readwrite) NSMutableArray *promptItems;
@property (nonatomic, strong, readwrite) NSString *defaultPrompt;

@end

@implementation MADPromptManager

- (instancetype)initWithDefaultPrompt:(NSString *)defaultPrompt {
	self = [self init];
	if (self) {
		
		NSMutableArray *promptItems = [[NSMutableArray alloc] init];
		self.promptItems = promptItems;
		
		NSString *dp = defaultPrompt == nil ? nil : [NSString stringWithString:defaultPrompt];
		self.defaultPrompt = dp;
		
		[self updatePrompt];
	}
	return self;
}

- (void)addString:(NSString *)string {
	[self.promptItems insertObject:string atIndex:0];
	[self updatePrompt];
}

- (void)removeString:(NSString *)string {
	NSUInteger i = [self.promptItems indexOfObjectIdenticalTo:string];
	if (i != NSNotFound) {
		[self.promptItems removeObjectAtIndex:i];
		[self updatePrompt];
	}
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
		self.prompt = self.defaultPrompt;
	}
}

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *classname = NSStringFromClass([self class]);
	id uppercaseClassname = [classname uppercaseString];
	[debug appendFormat:@"--%@--\n", uppercaseClassname];
	[debug appendFormat:@"Default prompt:       %@", self.prompt];
	[debug appendFormat:@"Prompt items:         %@", self.promptItems];
	return debug;
}

@end
