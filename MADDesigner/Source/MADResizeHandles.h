//
//  MADResizeHandles.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADResizeHandles_h
#define MAD_Designer_MADResizeHandles_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@class MADResizeHandles;

@protocol MTResizeHandlesDelegate
- (void)resizeHandle:(MADResizeHandles *)handles resize:(CGSize)size;
@end

@interface MADResizeHandles : NSObject

- (void)positionAroundRect:(CGRect)rect;

@property (nonatomic, strong, readonly) NSArray *resizeHandles;
@property (nonatomic, weak) id <MTResizeHandlesDelegate> delegate;

@end

#endif
