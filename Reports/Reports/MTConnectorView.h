//
//  MTConnectorView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTConnectorView_h
#define Reports_MTConnectorView_h

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MNSConnectorPosition) {
	MNSConnectorPositionA = 1,
	MNSConnectorPositionB = 2,
	MNSConnectorPositionC = 3,
	MNSConnectorPositionD = 4
};

@interface MTConnectorView : UIView

@property (nonatomic, strong) UIView *anchorViewLeft;
@property (nonatomic, strong) UIView *anchorViewRight;
@property (nonatomic, strong) NSNumber *topLeftToBottomRight;
@property (nonatomic, strong) NSString *linkDescription;

@property (nonatomic, assign) BOOL leftViewIsInital;
@property (nonatomic, assign) MNSConnectorPosition connectorPosition;
@property (nonatomic, assign) MNSConnectorPosition connectorPositionB;

- (void)setOriginPoint:(CGPoint)originPoint andDestinationPoint:(CGPoint)destinationPoint;

@end

#endif
