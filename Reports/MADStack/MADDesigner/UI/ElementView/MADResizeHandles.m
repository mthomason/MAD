//
//  MADResizeHandles.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADResizeHandles.h"

#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import "MADResizeHandleView.h"

@interface MADResizeHandles ()
    <MADResizeHandleViewDelegate>

    @property (nonatomic, strong, readwrite) NSArray *resizeHandles;

    @property (nonatomic, strong) MADResizeHandleView *handleEdgeRight;
    @property (nonatomic, strong) MADResizeHandleView *handleEdgeLeft;
    @property (nonatomic, strong) MADResizeHandleView *handleEdgeTop;
    @property (nonatomic, strong) MADResizeHandleView *handleEdgeBottom;
    @property (nonatomic, strong) MADResizeHandleView *handleCornerTopRight;
    @property (nonatomic, strong) MADResizeHandleView *handleCornerTopLeft;
    @property (nonatomic, strong) MADResizeHandleView *handleCornerBottomRight;
    @property (nonatomic, strong) MADResizeHandleView *handleCornerBottomLeft;

    @property (nonatomic, assign) CGRect frame;

@end

@implementation MADResizeHandles

- (void)resizeHandle:(MADResizeHandleView *)handle translate:(CGPoint)distance {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width + distance.x, self.frame.size.height + distance.y);
    [self.delegate resizeHandle:self resize:self.frame.size];
}

- (instancetype)init {
    if (self = [super init]) {
        CGSize handleSize = CGSizeMake(52.0000f, 52.0000f);
        CGRect frame = CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height);

        MADResizeHandleView *handleCornerTopLeft = [[MADResizeHandleView alloc] initWithFrame: frame andType: northWest];
        handleCornerTopLeft.delegate = self;
        handleCornerTopLeft.hidden = YES;
        NSArray *resizeHandles = [NSArray arrayWithObject:handleCornerTopLeft];
        self.handleCornerTopLeft = handleCornerTopLeft;
        
        MADResizeHandleView *handleCornerTopRight = [[MADResizeHandleView alloc] initWithFrame: frame andType: northEast];
        handleCornerTopRight.delegate = self;
        handleCornerTopRight.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerTopRight];
        self.handleCornerTopRight = handleCornerTopRight;
        
        MADResizeHandleView *handleCornerBottomRight = [[MADResizeHandleView alloc] initWithFrame: frame andType: southEast];
        handleCornerBottomRight.delegate = self;
        handleCornerBottomRight.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerBottomRight];
        self.handleCornerBottomRight = handleCornerBottomRight;
        
        MADResizeHandleView *handleCornerBottomLeft = [[MADResizeHandleView alloc] initWithFrame: frame andType: southWest];
        handleCornerBottomLeft.delegate = self;
        handleCornerBottomLeft.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerBottomLeft];
        self.handleCornerBottomLeft = handleCornerBottomLeft;
        
        MADResizeHandleView *handleEdgeTop = [[MADResizeHandleView alloc] initWithFrame: frame andType: north];
        handleEdgeTop.delegate = self;
        handleEdgeTop.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeTop];
        self.handleEdgeTop = handleEdgeTop;
        
        MADResizeHandleView *handleEdgeBottom = [[MADResizeHandleView alloc] initWithFrame: frame andType: south];
        handleEdgeBottom.delegate = self;
        handleEdgeBottom.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeBottom];
        self.handleEdgeBottom = handleEdgeBottom;
        
        MADResizeHandleView *handleEdgeRight = [[MADResizeHandleView alloc] initWithFrame: frame andType: east];
        handleEdgeRight.delegate = self;
        handleEdgeRight.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeRight];
        self.handleEdgeRight = handleEdgeRight;
        
        MADResizeHandleView *handleEdgeLeft = [[MADResizeHandleView alloc] initWithFrame: frame andType: west];
        handleEdgeLeft.delegate = self;
        handleEdgeLeft.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeLeft];
        self.handleEdgeLeft = handleEdgeLeft;
        
        self.resizeHandles = resizeHandles;
        
        self.frame = frame;
    }
    return self;
}

- (void)positionAroundRect:(CGRect)rect {
    self.handleEdgeLeft.center          = CGEdgeLeftPointInRect(rect);
    self.handleEdgeRight.center         = CGEdgeRightPointInRect(rect);
    self.handleEdgeBottom.center        = CGEdgeBottomPointInRect(rect);
    self.handleEdgeTop.center           = CGEdgeTopPointInRect(rect);
    self.handleCornerBottomLeft.center  = CGCornerBottomLeftPointInRect(rect);
    self.handleCornerBottomRight.center = CGCornerBottomRightPointInRect(rect);
    self.handleCornerTopRight.center    = CGCornerTopRightPointInRect(rect);
    self.handleCornerTopLeft.center     = CGCornerTopLeftPointInRect(rect);
    
    self.frame = CGRectMake(CGPointZero.x, CGPointZero.y, rect.size.width, rect.size.height);
}

@end
