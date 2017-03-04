//
//  UITableViewCellQueryGroup.m
//  Reports
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADTableViewCellQueryGroup.h"

@interface MADTableViewCellQueryGroup ()

@property (nonatomic, weak) IBOutletCollection(NSLayoutConstraint) NSArray *bogusConstraints;

@end

@implementation MADTableViewCellQueryGroup

+ (CGFloat)defaultHeight {
    return 88.0000f;
}

@end
