//
//  MADQueryVisulizationSchemaDefination.h
//  MAD Designer
//
//  Created by Michael Thomason on 8/30/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADQueryVisulizationTableDefination : NSObject

@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) NSUInteger depth;
@property (nonatomic, assign) BOOL isRoot;
@property (nonatomic, strong) NSURL *tableID;

- (instancetype)initWithAnchorPoint:(CGPoint)point andDepth:(NSUInteger)depth;

@end
