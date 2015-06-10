//
//  MADResizeHandles.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADResizeHandles.h"
#import "MTResizeHandleView.h"

@interface MADResizeHandles ()

@property (nonatomic, strong, readwrite) NSArray *resizeHandles;

@property (nonatomic, strong) MTResizeHandleView *handleEdgeRight;
@property (nonatomic, strong) MTResizeHandleView *handleEdgeLeft;
@property (nonatomic, strong) MTResizeHandleView *handleEdgeTop;
@property (nonatomic, strong) MTResizeHandleView *handleEdgeBottom;
@property (nonatomic, strong) MTResizeHandleView *handleCornerTopRight;
@property (nonatomic, strong) MTResizeHandleView *handleCornerTopLeft;
@property (nonatomic, strong) MTResizeHandleView *handleCornerBottomRight;
@property (nonatomic, strong) MTResizeHandleView *handleCornerBottomLeft;

@end

@implementation MADResizeHandles

- (instancetype)init {
    if (self = [super init]) {
        CGSize handleSize = CGSizeMake(10.0000f, 10.0000f);
        CGRect frame = CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height);

        MTResizeHandleView *handleCornerTopLeft = [[MTResizeHandleView alloc] initWithFrame: frame andType: northWest];
        handleCornerTopLeft.hidden = YES;
        NSArray *resizeHandles = [NSArray arrayWithObject:handleCornerTopLeft];
        self.handleCornerTopLeft = handleCornerTopLeft;
        
        MTResizeHandleView *handleCornerTopRight = [[MTResizeHandleView alloc] initWithFrame: frame andType: northEast];
        handleCornerTopRight.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerTopRight];
        self.handleCornerTopRight = handleCornerTopRight;
        
        MTResizeHandleView *handleCornerBottomRight = [[MTResizeHandleView alloc] initWithFrame: frame andType: southEast];
        handleCornerBottomRight.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerBottomRight];
        self.handleCornerBottomRight = handleCornerBottomRight;
        
        MTResizeHandleView *handleCornerBottomLeft = [[MTResizeHandleView alloc] initWithFrame: frame andType: southWest];
        handleCornerBottomLeft.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerBottomLeft];
        self.handleCornerBottomLeft = handleCornerBottomLeft;
        
        MTResizeHandleView *handleEdgeTop = [[MTResizeHandleView alloc] initWithFrame: frame andType: north];
        handleEdgeTop.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeTop];
        self.handleEdgeTop = handleEdgeTop;
        
        MTResizeHandleView *handleEdgeBottom = [[MTResizeHandleView alloc] initWithFrame: frame andType: south];
        handleEdgeBottom.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeBottom];
        self.handleEdgeBottom = handleEdgeBottom;
        
        MTResizeHandleView *handleEdgeRight = [[MTResizeHandleView alloc] initWithFrame: frame andType: east];
        handleEdgeRight.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeRight];
        self.handleEdgeRight = handleEdgeRight;
        
        MTResizeHandleView *handleEdgeLeft = [[MTResizeHandleView alloc] initWithFrame: frame andType: west];
        handleEdgeLeft.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeLeft];
        self.handleEdgeLeft = handleEdgeLeft;
        
        self.resizeHandles = resizeHandles;
    }
    return self;
}

- (void)positionAroundRect:(CGRect)rect {
    self.handleEdgeLeft.center = CGEdgeLeftPointInRect(rect);
    self.handleEdgeRight.center = CGEdgeRightPointInRect(rect);
    self.handleEdgeBottom.center = CGEdgeBottomPointInRect(rect);
    self.handleEdgeTop.center = CGEdgeTopPointInRect(rect);
    self.handleCornerBottomLeft.center = CGCornerBottomLeftPointInRect(rect);
    self.handleCornerBottomRight.center = CGCornerBottomRightPointInRect(rect);
    self.handleCornerTopRight.center = CGCornerTopRightPointInRect(rect);
    self.handleCornerTopLeft.center = CGCornerTopLeftPointInRect(rect);
}

@end
