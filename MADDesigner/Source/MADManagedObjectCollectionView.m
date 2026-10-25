//
//  MADManagedObjectCollectionView.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#include "MADManagedObjectCollectionView.h"

@implementation MADManagedObjectCollectionView

@synthesize identifier = _identifier;

- (id <NSCopying>)key {
	return @(self.identifier);
}

@end
