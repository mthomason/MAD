//
//  UICollectionReusableView+Reuse.m
//  Reports
//
//  Created by Michael Thomason on 12/25/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "UICollectionReusableView+Reuse.h"

@implementation UICollectionReusableView (Reuse)

+ (NSString *)reuseIdentifier {
	return NSStringFromClass([self class]);
}

@end
