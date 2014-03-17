#import "MTDocumentStatusView.h"

@interface MTDocumentStatusView()

@property (nonatomic, assign) UIDocumentState state;
@property (nonatomic, retain) NSString *message;
@property (atomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) BOOL active;

@end

@implementation MTDocumentStatusView

- (void)dealloc {
    [_activityIndicator release];
    [_message release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor: [UIColor clearColor]];
        [self setDocumentState: UIDocumentStateNormal];
        [self setMessage:@""];
    }
    
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(size.height + 80, size.height);
}

- (void)setDocumentState:(UIDocumentState)documentState {
    [self setState:documentState];
    [self setNeedsDisplay];
}

- (void)setDocumentMessage:(NSString *)message {
    [self setMessage:message];
    [self setNeedsDisplay];
}

- (CGRect)statusIndicatorRectForRect:(CGRect)rect {
    rect = CGRectMake(CGPointZero.x, CGPointZero.y, rect.size.height, rect.size.height);
    return CGRectInset(rect, 3.0000f, 3.0000f);;
}

- (void)setActivityState:(BOOL)active {
    @synchronized([self activityIndicator]) {
        [self setActive:active];
        if (active) {
            if ([self activityIndicator] == nil) {
                UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:[self statusIndicatorRectForRect:[self frame]]];
                [activityIndicator setHidesWhenStopped:YES];
                [self addSubview:activityIndicator];
                [self setActivityIndicator:activityIndicator];
                [activityIndicator release];
            }
            [[self activityIndicator] startAnimating];
        } else {
            [[self activityIndicator] stopAnimating];
            //[[self activityIndicator] removeFromSuperview];
            //[[self activityIndicator] release];
            //[self setActivityIndicator:nil];
        }
        [self setNeedsDisplay];
    }
}

//Draw a circluar status indicator on the left.  Draw
//  a label on the right.  The diameter of the status indicator
//  is related to the height.
- (void)drawRect:(CGRect)rect {
    
    //Draw status indicator
    CGRect statusIndicatorBox = [self statusIndicatorRectForRect:rect];

    CGMutablePathRef circlePath = CGPathCreateMutable();
    CGFloat centerX = CGRectGetMidX(statusIndicatorBox),
            centerY = CGRectGetMidY(statusIndicatorBox),
            radius = CGRectGetWidth(statusIndicatorBox) / 2.0000f;
    CGPathAddArc(circlePath, NULL, centerX, centerY, radius, 0.0000f, M_PI, NO);
    CGPathAddArc(circlePath, NULL, centerX, centerY, radius, M_PI, 0.0000f, NO);
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextAddPath(currentContext, circlePath);
    
    UIColor *statusColor;
    switch ([self state]) {
        
        case UIDocumentStateClosed:
            statusColor = [UIColor greenColor];
            break;
        case UIDocumentStateEditingDisabled:
            statusColor = [UIColor greenColor];
            break;
        case UIDocumentStateInConflict:
            statusColor = [UIColor yellowColor];
            break;
        case UIDocumentStateNormal:
            statusColor = [UIColor greenColor];
            break;
        case UIDocumentStateSavingError:
            statusColor = [UIColor redColor];
            break;
        default:
            statusColor = [UIColor greenColor];
            break;

    }
    [statusColor setFill];
    [[UIColor blackColor] setStroke];
    
    if ([self active]) {
        [[UIColor clearColor] set];
    }
    CGFloat lineWidth = ([UIDevice isModernOS] ? 1.0000f : 3.0000f);
    CGContextSetLineWidth(currentContext, lineWidth);
    
    CGContextDrawPath(currentContext, kCGPathEOFillStroke);
    CGPathRelease(circlePath);
    
    //Draw label
    if ([self active] == NO) {
        [[UIColor lightTextColor] set];
        
       // CGRect labelBox = CGRectMake(CGPointZero.x + rect.size.height, CGPointZero.y + 9.0000f, rect.size.width - rect.size.height, rect.size.height - 13.0000f);
        
        CGFloat actualFontSize = 9.0000f;
        UIFont *desiredfont = [UIFont boldSystemFontOfSize:9.0000f];
        
        CGSize constrainedSize = CGSizeMake((rect.size.width - rect.size.height), rect.size.height);
        CGSize actualLabelBoxSize = [[self message] sizeWithFont:desiredfont
                                               constrainedToSize:constrainedSize
                                                   lineBreakMode:NSLineBreakByWordWrapping];
//        CGSize actualLabelBoxSize = [[self message] sizeWithFont:desiredfont
//                                                     minFontSize:11.0000f
//                                                  actualFontSize:&actualFontSize
//                                                        forWidth:(rect.size.width - rect.size.height)
//                                                   lineBreakMode:NSLineBreakByCharWrapping];
        CGFloat inset = (rect.size.height - actualLabelBoxSize.height) / 2.0000f;
        CGRect printbox = CGRectMake(CGPointZero.x + rect.size.height, CGPointZero.y + inset, actualLabelBoxSize.width, actualLabelBoxSize.height);
        [[self message] drawInRect:printbox withFont:[UIFont boldSystemFontOfSize:actualFontSize] lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];
    }
}

@end
