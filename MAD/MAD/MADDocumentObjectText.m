//
//  MADDocumentObjectText.m
//  MAD
//
//  Created by Michael on 1/17/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObjectText.h"
#import <UIKit/UIFontDescriptor.h>
#import <UIKit/NSStringDrawing.h>
#import <MADCocoaExtensions/MADTextStyle.h>
#import "RptqDocumentElement.h"
#import "RptqTextStyle.h"
#import "RptqAlignment.h"
#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADElementStylizedText.h"
#import "MADAlignment.h"

@interface MADDocumentObjectText()
    @property (readwrite, nonatomic, weak) MADDocumentObjectDataReference *definition;
@end

@implementation MADDocumentObjectText

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition {
    if (self = [super init]) {
        _definition = definition;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect {
    MADElementStylizedText *attt;
    MADDocumentObjectDataReference *definition;

    RptqDocumentElement *item;
    definition = self.definition;
    item = definition.item;
    
    attt = definition.fontDescriptors[definition.item.objectID];
    
    if (attt == nil) {
        attt = [[MADElementStylizedText alloc] initWithFontName: definition.item.fontname
                                                       fontSize: definition.item.fontsize
                                                      textStyle: definition.item.textStyle
                                            horizontalAlignment: definition.item.alignment.horizontal];
        
        definition.fontDescriptors[definition.item.objectID] = attt;
    }
    
    [self.text drawWithRect: rect
                    options: NSStringDrawingUsesLineFragmentOrigin
                 attributes: attt.fontAttributes
                    context: nil];
    
}

@end
