//
//  UICollectionReusableView+Reuse.m
//  Reports
//
//  Created by Michael Thomason on 12/25/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "UICollectionReusableView+Reuse.h"

@implementation UICollectionReusableView (Reuse)

+ (NSString *)reuseIdentifier {
	return NSStringFromClass([self class]);
}

@end
