//
//  MADocumentState.m
//  MAD
//
//  Created by Michael Thomason on 5/27/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADocumentState.h"

@implementation MADocumentState

- (instancetype)init {
	if (self = [super init]) {
		self.saveInProgress = NO;
		self.needsSave = NO;
		self.contextChagned = NO;
	}
	return self;
}

@end
