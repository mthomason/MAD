//
//  MADRefreshOperationInitializeMainDataTable.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADOperationRefreshInitalizeMainDataTable.h"
#import <MAD/MADDocumentDataProtocol.h>
#import <MADFoundation/madlog.h>

@interface MADOperationRefreshInitializeMainDataTable ()

	@property (nonatomic, weak) id <MADDocumentDataProtocol> document;
	@property (nonatomic, assign) BOOL success;

@end

@implementation MADOperationRefreshInitializeMainDataTable

- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document {
	if (self = [super init]) {
		_document = document;
		_success = NO;
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	if (self.cancelled) {
		return [self finish];
	}

	[self.document resetCache];
	
	[self finish];
}

@end
