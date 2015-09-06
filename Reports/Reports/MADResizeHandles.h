//
//  MADResizeHandles.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MADResizeHandles;

@protocol MTResizeHandlesDelegate
- (void)resizeHandle:(MADResizeHandles *)handles resize:(CGSize)size;
@end

@interface MADResizeHandles : NSObject

- (void)positionAroundRect:(CGRect)rect;

@property (nonatomic, strong, readonly) NSArray *resizeHandles;
@property (nonatomic, weak) id <MTResizeHandlesDelegate> delegate;

@end
