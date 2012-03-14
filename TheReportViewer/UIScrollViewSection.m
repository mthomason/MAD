//
//  UIScrollViewDashboard.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIScrollViewSection.h"

@implementation UIScrollViewSection
@synthesize objectID = _objectID;
@synthesize localizedName = _localizedName;
@synthesize highlighted = _highlighted;

- (void)dealloc {
    [_objectID release];
    [_localizedName release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame name:(NSString *)name andObjectID:(NSManagedObjectID *)objid {
    self = [super initWithFrame:frame];
    if (self) {
        [self setObjectID: objid];
        [self setLocalizedName: name];

        [self setBackgroundColor: [UIColor edaBlackTwentyFivePercent]];
        [[self layer] setCornerRadius: 5.0000f];
        //[self setOpaque: NO];
        [self setClipsToBounds: YES];

    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect: rect];
    [[UIColor blueColor] set];
    [[self localizedName] drawInRect: rect
                            withFont: [UIFont systemFontOfSize:([UIFont systemFontSize])]
                       lineBreakMode: UILineBreakModeClip
                           alignment: UITextAlignmentLeft];
}

@end