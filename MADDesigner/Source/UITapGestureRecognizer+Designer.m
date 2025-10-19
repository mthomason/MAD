//
//  UITapGestureRecognizer+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/5/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "UITapGestureRecognizer+Designer.h"

@implementation MADTapGestureRecognizer

+ (instancetype)newTapGestureRecognizerSectionToggleWithTarget:(id)target
														action:(SEL)action
													  delegate:(id<UIGestureRecognizerDelegate>)delegate {
	MADTapGestureRecognizer *tap = [[self alloc] initWithTarget: target action: action];
	tap.numberOfTapsRequired = 1;
	tap.numberOfTouchesRequired = 1;
	tap.delaysTouchesBegan = YES;
	tap.delaysTouchesEnded = NO;
	tap.delegate = delegate;
	return tap;
}

+ (instancetype)newTapGestureRecognizerTapWithTarget:(id)target
											  action:(SEL)action
											delegate:(id<UIGestureRecognizerDelegate>)delegate {
	MADTapGestureRecognizer *tap = [[self alloc] initWithTarget: target action: action];
	tap.numberOfTapsRequired = 1;
	tap.numberOfTouchesRequired = 1;
	tap.delaysTouchesBegan = YES;
	tap.delaysTouchesEnded = NO;
	tap.delegate = delegate;
	return tap;
}

+ (instancetype)newTapGestureRecognizerStrayTouchWithTarget:(id)target
													 action:(SEL)action
												   delegate:(id<UIGestureRecognizerDelegate>)delegate {
	MADTapGestureRecognizer *tap = [[self alloc] initWithTarget: target action: action];
	tap.numberOfTapsRequired = 1;
	tap.numberOfTouchesRequired = 1;
	tap.delegate = delegate;
	tap.delaysTouchesBegan = YES;
	return tap;
}

@end

@implementation MADPanGestureRecognizer

+ (instancetype)newPanGestureRecognizerElement:(id)target
					action:(SEL)action
				  delegate:(id<UIGestureRecognizerDelegate>)delegate {
	MADPanGestureRecognizer *panGesture = [[self alloc] initWithTarget: target action: action];
	panGesture.minimumNumberOfTouches = 1;
	panGesture.maximumNumberOfTouches = 2;
	panGesture.delegate = delegate;
	return panGesture;
}

@end

@implementation MADPinchGestureRecognizer

+ (instancetype)newPinchGestureRecognizerElement:(id)target
					  action:(SEL)action
					delegate:(id<UIGestureRecognizerDelegate>)delegate {
	MADPinchGestureRecognizer *panGesture = [[self alloc] initWithTarget: target action: action];
	panGesture.delegate = delegate;
	return panGesture;
}

@end
