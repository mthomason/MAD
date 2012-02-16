//
//  DataObject.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	left,
	right,
	up,
	down,
	none
} MNSDirection;


@interface ElementView : UIView {
	NSString *stringElm;
	NSTimer *pieceChangeTimer;
	UIImage *tileImage;
	NSInteger level;
	CGSize originalSize;
	CGSize largeSize;
	CGPoint originalPoint;					//Do not synthsize
	CGPoint originalPointCenter;
	CGPoint originalPointLandscape;			//Do not synthsize
	CGPoint originalPointCenterLandscape;
	CGPoint inGoalPoint;
	CGPoint lastPointPlusOne;
	CGPoint lastPoint;
	CGPoint currentPoint;
	NSTimeInterval delay;
	NSTimeInterval lastTimePlusOne;
	NSTimeInterval lastTime;
	NSTimeInterval currentTime;
	CGFloat currentRateOfChange;
	UIInterfaceOrientation orientation;
	NSInteger row;
	BOOL inPlay;
	BOOL movingInPlay;
	BOOL upSized;	
	BOOL isSmall;
	BOOL useExtendsTime;
	BOOL useGivePointsMultiplier;
	BOOL useGivesExtraShake;
	BOOL isMoving;
	BOOL isHeldDown;
	BOOL allowTileToFlip;
}

@property (nonatomic, retain) UIImage *tileImage;
@property (nonatomic, retain) NSString *stringElm;

@property (nonatomic, assign) NSInteger level;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, assign) BOOL inPlay;
@property (nonatomic, assign) BOOL movingInPlay;
@property (nonatomic, assign) BOOL upSized;
@property (nonatomic, assign) BOOL isSmall;
@property (nonatomic, assign) BOOL useExtendsTime;
@property (nonatomic, assign) BOOL useGivePointsMultiplier;
@property (nonatomic, assign) BOOL useGivesExtraShake;
@property (nonatomic, assign) BOOL allowTileToFlip;
@property (nonatomic, assign) CGSize originalSize;

@property (nonatomic, assign) CGPoint inGoalPoint;
@property (nonatomic, assign) CGPoint originalPointCenter;

@property (nonatomic, assign) CGFloat currentRateOfChange;
@property (nonatomic, assign) BOOL isMoving;
@property (nonatomic, assign) BOOL isHeldDown;

- (void)invalidateTimer;
- (void)setOriginalPoint:(CGPoint)point;
- (void)setOriginalPointLandscape:(CGPoint)point;
- (CGPoint)originalPoint;
- (CGPoint)originalPointLandscape;

- (CGPoint)origionalPointInFrame:(CGRect)rect
						   onRow:(NSInteger)row
					 ofTotalRows:(NSInteger)rows
						  andCol:(NSInteger)col
					 ofTotalCols:(NSInteger)cols
					  paddingTop:(CGFloat)paddingTop
				   paddingBottom:(CGFloat)paddingBottom;

+ (CGFloat)slope:(CGPoint)one pointTwo:(CGPoint)two;
+ (float)distance:(CGPoint)one pointTwo:(CGPoint)two;
+ (CGRect)frameOffScreenRandom;
- (BOOL)pointInGoal:(CGPoint)myPoint;
- (MNSDirection)collisionDetectionSides;
- (CGPoint)slide:(float)rateOfChange;
- (void)addToGameGoal:(BOOL)userCenter;
- (void)animateTouchesMoved:(CFTimeInterval)duration location:(CGPoint)location
			  animationType:(UIViewAnimationCurve)animationType
				  boundSize:(CGSize)boundSize;
- (void)animateOffScreen:(CFTimeInterval)duration location:(CGPoint)location
		   animationType:(UIViewAnimationCurve)animationType
			   boundSize:(CGSize)boundSize;
- (void)animateTouchesMovedToOrigin;
- (void)animateMakeSmall;
- (void)animateToOrigin:(NSString *)animationID context:(void *)context;

@end