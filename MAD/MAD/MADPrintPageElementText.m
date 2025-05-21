//
//  MADPrintPageElementText.m
//  MAD
//
//  Created by Michael on 1/17/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPrintPageElementText.h"

#import <UIKit/UIFontDescriptor.h>
#import <UIKit/NSStringDrawing.h>

#import <MADCocoaExtensions/MADTextStyle.h>

#import "RptqDocumentElement.h"
#import "RptqTextStyle.h"
#import "RptqAlignment.h"

#import "MADDocumentObjectDataReference.h"
#import "MADAlignment.h"
#import "MADElementStylizedText.h"

@interface MADPrintPageElementText()
    @property (readwrite, nonatomic, weak) MADDocumentObjectDataReference *definition;
@end

@implementation MADPrintPageElementText

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super init]) {
        _definition = definition;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    NSDictionary <NSString *, id> *fontAttributes = [self.definition fontAttributes];
    [self.text drawWithRect: rect
                    options: NSStringDrawingUsesLineFragmentOrigin
                 attributes: fontAttributes
                    context: nil];
    
}

@end
