//
//  MADResizeHandles.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADResizeHandles : NSObject

- (void)positionAroundRect:(CGRect)rect;

@property (nonatomic, strong, readonly) NSArray *resizeHandles;

@end
