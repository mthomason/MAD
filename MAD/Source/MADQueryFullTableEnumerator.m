//
//  MADQueryFullTableEnumerator.m
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADQueryFullTableEnumerator.h"
#import <MAD/RptqStoreContext.h>
#import "RptqDocument.h"

@interface MADQueryFullTableEnumerator ()

@property (nonatomic, strong) RptqStoreContext *managedObjectContext;
@property (nonatomic, assign) int64_t documentObjectIdentifier;

@end

@implementation MADQueryFullTableEnumerator

- (instancetype)initWithDocument:(RptqDocument *)document {
	if (self = [super init]) {
		_documentObjectIdentifier = document.identifier;
		self.managedObjectContext = document.storeContext;
		
	}
	return self;
}

@end
