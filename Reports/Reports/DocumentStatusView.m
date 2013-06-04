#import "DocumentStatusView.h"

@interface DocumentStatusView()

@property (nonatomic, assign) UIDocumentState state;

@end

@implementation DocumentStatusView


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor: [UIColor clearColor]];
        [self setDocumentState: UIDocumentStateNormal];
    }
    
    return self;
}


- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(size.height + 80, size.height);
}

- (void)setDocumentState:(UIDocumentState)documentState {
    [self setNeedsDisplay];
    [self setState:documentState];
}

- (void)drawRect:(CGRect)rect {
    rect = CGRectInset(rect, 3.0000f, 3.0000f);
    CGMutablePathRef circlePath = CGPathCreateMutable();
    CGPathAddArc(circlePath, NULL, CGRectGetMidX(rect), CGRectGetMidY(rect), CGRectGetWidth(rect) / 2.0000f, 0.0000f, M_PI, NO);
    CGPathAddArc(circlePath, NULL, CGRectGetMidX(rect), CGRectGetMidY(rect), CGRectGetWidth(rect) / 2.0000f, M_PI, 0.0000f, NO);
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextAddPath(currentContext, circlePath);
    
    switch ([self state]) {
        
        case UIDocumentStateClosed:
            [[UIColor greenColor] setFill];
            break;
        
        case UIDocumentStateEditingDisabled:
            [[UIColor greenColor] setFill];
            break;
        
        case UIDocumentStateInConflict:
            [[UIColor yellowColor] setFill];
            break;
        
        case UIDocumentStateNormal:
            [[UIColor greenColor] setFill];
            break;
        
        case UIDocumentStateSavingError:
            [[UIColor redColor] setFill];
            break;
        
        default:
            [[UIColor greenColor] setFill];
            break;

    }
    [[UIColor blackColor] setStroke];
    
    CGContextSetLineWidth(currentContext, 3.0000f);
    
    CGContextDrawPath(currentContext, kCGPathEOFillStroke);
    CGPathRelease(circlePath);
}

@end
