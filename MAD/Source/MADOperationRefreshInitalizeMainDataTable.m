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

static NSString * const MADOperationRefreshInitializeErrorDomain =
	@"com.everydayapps.operation.refresh.initialize";

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

	NSError *error = nil;
	MADDataResult *pending = [self.document beginRefreshResultWithError:&error];
	if (pending == nil) {
		NSError *failure = error ?: [NSError errorWithDomain: MADOperationRefreshInitializeErrorDomain
														code: 1
													userInfo: @{
			NSLocalizedDescriptionKey: NSLocalizedString(@"The refresh result could not be prepared.",
														  @"The staged refresh table could not be created.")
		}];
		[self finishWithError:failure];
		return;
	}

	[self finish];
}

@end
