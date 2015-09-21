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
    <MTResizeHandleViewDelegate>
@property (nonatomic, strong, readwrite) NSArray *resizeHandles;

@property (nonatomic, strong) MTResizeHandleView *handleEdgeRight;
@property (nonatomic, strong) MTResizeHandleView *handleEdgeLeft;
@property (nonatomic, strong) MTResizeHandleView *handleEdgeTop;
@property (nonatomic, strong) MTResizeHandleView *handleEdgeBottom;
@property (nonatomic, strong) MTResizeHandleView *handleCornerTopRight;
@property (nonatomic, strong) MTResizeHandleView *handleCornerTopLeft;
@property (nonatomic, strong) MTResizeHandleView *handleCornerBottomRight;
@property (nonatomic, strong) MTResizeHandleView *handleCornerBottomLeft;

@property (nonatomic, assign) CGRect frame;

@end

@implementation MADResizeHandles

- (void)resizeHandle:(MTResizeHandleView *)handle translate:(CGPoint)distance {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width + distance.x, self.frame.size.height + distance.y);
    [self.delegate resizeHandle:self resize:self.frame.size];
}

- (instancetype)init {
    if (self = [super init]) {
        CGSize handleSize = CGSizeMake(52.0000f, 52.0000f);
        CGRect frame = CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height);

        MTResizeHandleView *handleCornerTopLeft = [[MTResizeHandleView alloc] initWithFrame: frame andType: northWest];
        handleCornerTopLeft.delegate = self;
        handleCornerTopLeft.hidden = YES;
        NSArray *resizeHandles = [NSArray arrayWithObject:handleCornerTopLeft];
        self.handleCornerTopLeft = handleCornerTopLeft;
        
        MTResizeHandleView *handleCornerTopRight = [[MTResizeHandleView alloc] initWithFrame: frame andType: northEast];
        handleCornerTopRight.delegate = self;
        handleCornerTopRight.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerTopRight];
        self.handleCornerTopRight = handleCornerTopRight;
        
        MTResizeHandleView *handleCornerBottomRight = [[MTResizeHandleView alloc] initWithFrame: frame andType: southEast];
        handleCornerBottomRight.delegate = self;
        handleCornerBottomRight.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerBottomRight];
        self.handleCornerBottomRight = handleCornerBottomRight;
        
        MTResizeHandleView *handleCornerBottomLeft = [[MTResizeHandleView alloc] initWithFrame: frame andType: southWest];
        handleCornerBottomLeft.delegate = self;
        handleCornerBottomLeft.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerBottomLeft];
        self.handleCornerBottomLeft = handleCornerBottomLeft;
        
        MTResizeHandleView *handleEdgeTop = [[MTResizeHandleView alloc] initWithFrame: frame andType: north];
        handleEdgeTop.delegate = self;
        handleEdgeTop.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeTop];
        self.handleEdgeTop = handleEdgeTop;
        
        MTResizeHandleView *handleEdgeBottom = [[MTResizeHandleView alloc] initWithFrame: frame andType: south];
        handleEdgeBottom.delegate = self;
        handleEdgeBottom.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeBottom];
        self.handleEdgeBottom = handleEdgeBottom;
        
        MTResizeHandleView *handleEdgeRight = [[MTResizeHandleView alloc] initWithFrame: frame andType: east];
        handleEdgeRight.delegate = self;
        handleEdgeRight.hidden = YES;
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeRight];
        self.handleEdgeRight = handleEdgeRight;
        
        MTResizeHandleView *handleEdgeLeft = [[MTResizeHandleView alloc] initWithFrame: frame andType: west];
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
    self.handleEdgeLeft.center = CGEdgeLeftPointInRect(rect);
    self.handleEdgeRight.center = CGEdgeRightPointInRect(rect);
    self.handleEdgeBottom.center = CGEdgeBottomPointInRect(rect);
    self.handleEdgeTop.center = CGEdgeTopPointInRect(rect);
    self.handleCornerBottomLeft.center = CGCornerBottomLeftPointInRect(rect);
    self.handleCornerBottomRight.center = CGCornerBottomRightPointInRect(rect);
    self.handleCornerTopRight.center = CGCornerTopRightPointInRect(rect);
    self.handleCornerTopLeft.center = CGCornerTopLeftPointInRect(rect);
    
    self.frame = CGRectMake(CGPointZero.x, CGPointZero.y, rect.size.width, rect.size.height);
}

@end
