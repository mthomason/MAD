//
//  UICollectionViewCell+Reuse.m
//  Reports
//
//  Created by Michael Thomason on 12/25/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UICollectionViewCell+Reuse.h"

@implementation UICollectionViewCell (Reuse)

+ (NSString *)reuseIdentifier {
    return NSStringFromClass([self class]);
}

@end