//
//  MTConnectorView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIColor+EverydayApps.h"

typedef NS_ENUM(NSUInteger, MNSConnectorPosition) {
	MNSConnectorPositionA = 1,
	MNSConnectorPositionB = 2,
	MNSConnectorPositionC = 3,
	MNSConnectorPositionD = 4
};

@interface MTConnectorView : UIView

@property (nonatomic, retain) UIView *anchorViewLeft;
@property (nonatomic, retain) UIView *anchorViewRight;
@property (nonatomic, retain) NSNumber *topLeftToBottomRight;
@property (nonatomic, retain) NSString *linkDescription;

@property (nonatomic, assign) BOOL leftViewIsInital;
@property (nonatomic, assign) MNSConnectorPosition connectorPosition;
@property (nonatomic, assign) MNSConnectorPosition connectorPositionB;

- (void)setOriginPoint:(CGPoint)originPoint andDestinationPoint:(CGPoint)destinationPoint;

@end
