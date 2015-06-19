//
//  MADCollectionViewCellProductFeature.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/18/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADCollectionViewCellProductFeature.h"
#import "MADBackgroundViewSelected.h"
#import "MADBackgroundView.h"
#import "UIColor+EverydayApps.h"

@implementation MADCollectionViewCellProductFeature

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        UIView *selectedBackgroundView = [[MADBackgroundViewSelected alloc] initWithFrame:self.bounds];
        self.selectedBackgroundView = selectedBackgroundView;
        UIView *backgroundView = [[MADBackgroundView alloc] initWithFrame:self.bounds];
        self.backgroundView = backgroundView;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];

}

@end
