//
//  MTQueryVisulizationLinkDefination.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSObject.h>
#import <MADDataStructures/MTPair.h>
#import <CoreGraphics/CGBase.h>

@class NSURL;

@interface MTQueryVisualizationLinkDefination : NSObject

@property (nonatomic, strong) NSURL *linkID;
@property (nonatomic, strong) MTPair *fieldsIDs;
@property (nonatomic, strong) MTPair *anchorPoints;
@property (nonatomic, assign) CGFloat length;

@end
