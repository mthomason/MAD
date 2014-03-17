//
//  UICollectionReusableView+Reuse.m
//  Reports
//
//  Created by Michael Thomason on 12/25/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UICollectionReusableView+Reuse.h"

@implementation UICollectionReusableView (Reuse)

+ (NSString *)reuseIdentifier {
    return NSStringFromClass([self class]);
}

@end
