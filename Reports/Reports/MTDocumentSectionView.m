//
//  MTDocumentSectionView.m
//  Reports
//
//  Created by Michael Thomason on 2/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDocumentSectionView.h"
#import "CGGeometry+Extras.h"

@interface MTDocumentSectionView ()

@property (nonatomic, assign) CGFloat resizeHeightDifferenceInital;
@property (nonatomic, assign) CGFloat resizeHeightBoundsHeightInital;

@end

@implementation MTDocumentSectionView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
}

- (CGSize)intrinsicContentSize {
    CGSize intrinsicContentSize = [[self collectionViewLayout] collectionViewContentSize];
    CGSize fingerSize = CGSizeFingerDefault();
    return CGSizeMake(intrinsicContentSize.width, intrinsicContentSize.height + fingerSize.height);
}

@end
