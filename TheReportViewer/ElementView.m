//
//  DataObject.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "ElementView.h"
#import <QuartzCore/QuartzCore.h>
#import "CGGeometry+Extras.h"

@implementation ElementView


@synthesize originalSize;
@synthesize stringElm;
//@synthesize pieceChangeTimer;
@synthesize inPlay;
@synthesize movingInPlay;
@synthesize upSized;
@synthesize isSmall;
@synthesize useExtendsTime;
@synthesize useGivePointsMultiplier;
@synthesize useGivesExtraShake;
@synthesize originalPointCenter;
@synthesize currentRateOfChange;
@synthesize isMoving;
@synthesize isHeldDown;
@synthesize level;
@synthesize orientation;
@synthesize row;
@synthesize allowTileToFlip;
@synthesize tileImage;

@synthesize inGoalPoint;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		CGPoint offScreen = CGPointMakeRandomOffscreen();
		[self setFrame:CGRectMake(offScreen.x, offScreen.y, self.frame.size.width, self.frame.size.height)];
		
		[self setBackgroundColor:[UIColor clearColor]];

		originalSize = self.frame.size;
		
		largeSize.width = self.frame.size.width * 1.2000f;
		largeSize.height = self.frame.size.height * 1.2000f;

		inPlay = YES;
		movingInPlay = NO;
		upSized = NO;
		isSmall = NO;
		isHeldDown = NO;
		allowTileToFlip = YES;
		[self setOpaque: YES];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextAddPath(currentContext, path);
    [[UIColor whiteColor] setFill];
    [[UIColor blackColor] setStroke];
    CGContextSetLineWidth(currentContext, 1.0000f);
    CGContextDrawPath(currentContext, kCGPathFillStroke);
    CGPathRelease(path);
    
}

- (void)setOriginalPoint:(CGPoint)point {
	originalPoint = point;
	originalPointCenter = CGPointMake(CGRectGetMidX(CGRectMake(originalPoint.x, originalPoint.y, self.frame.size.width, self.frame.size.height)),
									  CGRectGetMidY(CGRectMake(originalPoint.x, originalPoint.y, self.frame.size.width, self.frame.size.height)));	
}

- (CGPoint)originalPoint {
	return originalPoint;
}
- (CGPoint)originalPointLandscape {
	return originalPointLandscape;
}

#pragma mark Standard Overrides

- (void)dealloc {
	if (tileImage != nil) {
		[tileImage release];
		tileImage = nil;
	}
	if (stringElm != nil) {
		[stringElm release];
		stringElm = nil;
	}
	[super dealloc];
}

- (void)invalidateTimer {	//Tile won't be deallocated until timer is invalidated
	if (pieceChangeTimer != nil) {
		[pieceChangeTimer invalidate];
		pieceChangeTimer = nil;
	}	
}

- (CGPoint)origionalPointInFrame:(CGRect)rect
						   onRow:(NSInteger)r
					 ofTotalRows:(NSInteger)rows
						  andCol:(NSInteger)col
					 ofTotalCols:(NSInteger)cols
					  paddingTop:(CGFloat)paddingTop
				   paddingBottom:(CGFloat)paddingBottom {
	
	rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height - paddingTop - paddingBottom);
	CGFloat moveDistanceX = (rect.size.width - (self.frame.size.width * cols)) / (((cols - 1) * 2) + 2);
	CGFloat moveDistanceY = (rect.size.height - (self.frame.size.height * rows)) / (((rows - 1) * 2) + 2);
	return CGPointMake((self.frame.size.width * col) + (moveDistanceX * col * 2) + moveDistanceX,
					   (self.frame.size.width * r) + (moveDistanceY * r * 2) + moveDistanceY + paddingTop);
}

- (NSTimeInterval)intervalForLevel {
	if (level <= 0) level = 1;
#if WORDFLICK == TRUE
	int i = ceil(50 / (level * 0.50));
#elif WORDFLICKJR == TRUE
	int i = ceil(150 / (level * 0.50));	//Don't change letters as quickly.
#else
	int i = ceil(50 / (level * 0.50));
#endif
	long r = random();
	return (8.0 + (0.001 * (r%1000)) + (r%i));
}

#pragma mark Points and Sizes

- (CGPoint)topLeftPoint {
	return CGPointMake(self.frame.origin.x,
					   self.frame.origin.y);
}

- (CGPoint)topRightPoint {
	return CGPointMake(self.frame.origin.x + self.frame.size.width,
					   self.frame.origin.y);
}

- (CGPoint)bottomLeftPoint {
	return CGPointMake(self.frame.origin.x, self.frame.origin.y + self.frame.size.height);	
}

- (CGPoint)bottomRightPoint {
	return CGPointMake(self.frame.origin.x + self.frame.size.width, self.frame.origin.y + self.frame.size.height);
}

#pragma mark Linear Algebra

+ (float)distance:(CGPoint)one pointTwo:(CGPoint)two {
	return sqrt(pow((two.x - one.x), 2) + pow((two.y - one.y), 2));
}

+ (CGFloat)slope:(CGPoint)one pointTwo:(CGPoint)two {
	return ((two.y - one.y) / (two.x - one.x));
}

+ (float)intercept:(CGPoint)one pointTwo:(CGPoint)two slope:(float)m {	//y-intercept
	return (two.y - (m * two.x));
}

+ (float)rateOfChange:(CGPoint)one touchTwo:(CGPoint)two timeOne:(NSTimeInterval)t1 timeTwo:(NSTimeInterval)t2 {
	if (t2 - t1 != 0) return ([ElementView distance:one pointTwo:two] / ((t2 - t1)*3));
	else return 0;
}

+ (CGPoint)yInversePlusDistance:(CGPoint)one pointTwo:(CGPoint)two distance:(long)d { //d >= 0
	CGPoint returnVal;
	long double m = -1 * [ElementView slope:one pointTwo:two];
	long double b = [ElementView intercept:one pointTwo:two slope:m];
	BOOL movingUp;
	if (one.y < two.y) movingUp = YES;
	else movingUp = NO;
	
	long double x = two.x;
	long double y = two.y;
	
	if (d >= 0) {		
		long double mPow2 = pow(m, 2);
		long double bPow2 = pow(b, 2);
		long double dPow2 = pow(d, 2);
		long double u = two.x;
		long double v = two.y;
		long double sqrtPart = 0.0;
		sqrtPart = (mPow2)*( ((-1)*(bPow2)) + ((dPow2)*(1+mPow2)) - (pow((((-1)*(m)*(u)) + v),2)) + (b*(((-1)*(2)*(m)*(u))+((2)*(v)))) );
		if (!isnan(sqrtPart)) {
			if (movingUp) y = ((b)+((m)*(u))+((mPow2)*(v))+sqrt(sqrtPart)) / (1+mPow2);
			else y = ((b)+((m)*(u))+((mPow2)*(v))-sqrt(sqrtPart)) / (1+mPow2);
			
			x=(y-b)/m;
		}
		if (!isnan(x) && !isnan(y)) {
			returnVal.x = x;
			returnVal.y = y;
		} else {
			returnVal.x = two.x;
			returnVal.y = two.y;			
		}
	}
	return returnVal;
}

+ (CGPoint)yPlusDistance:(CGPoint)one pointTwo:(CGPoint)two distance:(long)d { //d >= 0
	CGPoint returnVal;
	long double m = [ElementView slope:one pointTwo:two];
	long double b = [ElementView intercept:one pointTwo:two slope:m];
	BOOL movingUp;
	if (one.y < two.y) movingUp = YES;
	else movingUp = NO;
	
	long double x = two.x;
	long double y = two.y;
	d = abs(d);
	long double mPow2 = pow(m, 2);
	long double bPow2 = pow(b, 2);
	long double dPow2 = pow(d, 2);
	long double u = two.x;
	long double v = two.y;
	long double sqrtPart = 0.0;
	sqrtPart = (mPow2)*( ((-1)*(bPow2)) + ((dPow2)*(1+mPow2)) - (pow((((-1)*(m)*(u)) + v),2)) + (b*(((-1)*(2)*(m)*(u))+((2)*(v)))) );
	if (!isnan(sqrtPart)) {
		if (movingUp) y = ((b)+((m)*(u))+((mPow2)*(v))+sqrt(sqrtPart)) / (1+mPow2);
		else y = ((b)+((m)*(u))+((mPow2)*(v))-sqrt(sqrtPart)) / (1+mPow2);
		
		x=(y-b)/m;
	}
	if (!isnan(x) && !isnan(y)) {
		returnVal.x = x;
		returnVal.y = y;
	} else {
		returnVal.x = two.x;
		returnVal.y = two.y;			
	}
	return returnVal;
}

- (MNSDirection)collisionDetectionSides {
	MNSDirection returnVal;
	if ([self superview].frame.origin.x + [self superview].frame.size.width > currentPoint.x) { //test right
		returnVal = right;
	} else if ([self superview].frame.origin.x < currentPoint.x) { //test left
		returnVal = left;
	}else if ([self superview].frame.origin.y < currentPoint.y) { //test top
		returnVal = up;
	} else if ([self superview].frame.origin.y + [self superview].frame.size.height > currentPoint.x) { //test bottom
		returnVal = down;
	} else {
		returnVal = none;
	}
	return returnVal;
}

#pragma mark Touch events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	isHeldDown = YES;
	allowTileToFlip = NO;
    [self.superview bringSubviewToFront:self];
    [UIView beginAnimations:@"makeLarge" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, largeSize.width, largeSize.height)];
    self.center = [[touches anyObject] locationInView:[self superview]];
    [UIView commitAnimations];
    lastTime = [[touches anyObject] timestamp];
    lastPoint.x = [[touches anyObject] locationInView:[self superview]].x;
    lastPoint.y = -[[touches anyObject] locationInView:[self superview]].y;
    currentTime = [[touches anyObject] timestamp];
    currentPoint.x = [[touches anyObject] locationInView:[self superview]].x;
    currentPoint.y = -[[touches anyObject] locationInView:[self superview]].y;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self animateTouchesMovedToOrigin];
	isHeldDown = NO;
	allowTileToFlip = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self animateTouchesMoved:(currentTime - lastTime) location:[[touches anyObject] locationInView:[self superview]] animationType:UIViewAnimationCurveLinear boundSize:self.bounds.size];
    
    lastTimePlusOne = lastTime;
    lastTime = currentTime;
    currentTime = [[touches anyObject] timestamp];
    
    lastPointPlusOne = lastPoint;
    lastPoint = currentPoint;
    currentPoint.x = [[touches anyObject] locationInView:[self superview]].x;
    currentPoint.y = (-1) * [[touches anyObject] locationInView:[self superview]].y;
    
	isHeldDown = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[self setIsMoving:NO];
    float rateOfChange = [ElementView rateOfChange:lastPointPlusOne
                                          touchTwo:currentPoint
                                           timeOne:lastTimePlusOne
                                           timeTwo:currentTime];
    
    [self slide:rateOfChange];												//Slide the game piece.
}

- (CGPoint)slide:(float)rateOfChange {
    rateOfChange = rateOfChange / 11.0000f;
    if (rateOfChange > 20.0000f && rateOfChange < 400.0000f) {
        rateOfChange += 400.0000f;
    }
	if (rateOfChange <= 0) { rateOfChange = 1; }
	CGPoint c = [ElementView yPlusDistance:lastPointPlusOne pointTwo:currentPoint distance:(rateOfChange)];
	if (!isnan(c.x) && !isnan(c.y)) {
		c.y = (-1) * (c.y);
		[self setCurrentRateOfChange:rateOfChange];
		[self setIsMoving:YES];
		//if ([self pointInGoal:c]) {									//Detect if in goal or not
		
        //}
		float distance = [ElementView distance:self.center pointTwo:c];
		
		CGFloat time = (distance / 1000 / 3);
		//NSLog(@"Time: %f, Distance: %f, Rate of Change: %f", time, distance, rateOfChange);
		NSNumber *t = [[NSNumber alloc] initWithFloat:time];
		[UIView beginAnimations:@"touchesMoved" context:t];
		[UIView setAnimationDuration:time];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animateToOrigin:context:)];
		self.center = c;
		[UIView commitAnimations];
		[t release];
	} else {
		[self animateToOrigin:nil context:nil];
	}
	return c;
}

#pragma mark Animate Tiles

- (void)animateToOrigin:(NSString *)animationID context:(void *)context {
	if (inPlay) {
		CGPoint newCenter;
		newCenter = originalPointCenter;
		CGFloat duration = [(NSNumber *)context floatValue] * .6;
		[UIView beginAnimations:@"touchesFinishedOutsideGoal" context:nil];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationDidStopSelector:@selector(didStopMoving:context:)];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDuration:duration];
		[self setBounds:CGRectMake(self.center.x, self.center.y, originalSize.width, originalSize.height)];
		[self setCenter:newCenter];
		[UIView commitAnimations];
		//[self removeFromGameGoal];
	} else {
		[UIView beginAnimations:@"touchesMoved" context:nil];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(didStopMoving:context:)];
		self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, originalSize.width, originalSize.height);
		self.center = self.center;
		[UIView commitAnimations];		
	}
	[self setIsMoving:NO];
}

- (void)didStopMoving:(NSString *)animationID context:(void *)context {
	isHeldDown = NO;
}

- (void)animateMakeSmall {
	[UIView beginAnimations:@"touchesMoved" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, originalSize.width, originalSize.height)];
	[UIView commitAnimations];
}

- (void)animateTouchesMoved:(CFTimeInterval)duration location:(CGPoint)location	//Animates to the point in the goal view
			  animationType:(UIViewAnimationCurve)animationType					//	May add sound when this stops to show it
				  boundSize:(CGSize)boundSize {									//	sticks in the goal.
	[UIView beginAnimations:@"touchesMoved" context:nil];
	self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, boundSize.width, boundSize.height);
	self.center = location;
	[UIView commitAnimations];
}

- (void)animateOffScreen:(CFTimeInterval)duration location:(CGPoint)location
		   animationType:(UIViewAnimationCurve)animationType
			   boundSize:(CGSize)boundSize {
	[UIView beginAnimations:@"touchesMoved" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationCurve:animationType];
	self.bounds = CGRectMake(self.bounds.origin.x * 3.6f,
							 self.bounds.origin.y * 3.6f,
							 boundSize.width * 3.6f,
							 boundSize.height * 3.6f);
	self.center = location;
	[UIView commitAnimations];
}

- (void)animateTouchesMovedToOrigin {
	[UIView beginAnimations:@"touchesFinishedOutsideGoal" context:nil];
	[self setBounds:CGRectMake(self.center.x, self.center.y, originalSize.width, originalSize.height)];
    [self setCenter:originalPointCenter];
    [self setCenter:originalPointCenter];
	[UIView commitAnimations];	
}

@end