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
#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADocumentObjectAttributesText.h"
#import "MTAlignment.h"

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
    MADocumentObjectAttributesText *attt;
    MADDocumentObjectDataReference *definition;

    RptqDocumentElement *item;
    definition = self.definition;
    item = definition.item;
    
    attt = definition.fontDescriptors[item.objectID];
    
    if (attt == nil) {
        MADTextStyle style; MADAlignment alignment;
        [(NSValue *)item.style getValue:&style];
        [(NSValue *)item.alignment getValue:&alignment];
        attt = [[MADocumentObjectAttributesText alloc] initWithFontName: item.fontname
                                                               fontSize: item.fontsize
                                                                   bold: style.bold
                                                                 italic: style.italic
                                                              underline: style.underline
                                                                 strike: style.strikethrough
                                                    horizontalAlignment: alignment.horizontal];
        
        definition.fontDescriptors[item.objectID] = attt;
    }
    
    [self.text drawWithRect: rect
                    options: NSStringDrawingUsesLineFragmentOrigin
                 attributes: attt.fontAttributes
                    context: nil];
    
}

@end
