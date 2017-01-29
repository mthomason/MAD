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
#import "RptqDocumentElement+CoreDataClass.h"
#import "MADDocumentObjectReference.h"
#import "MADPrintPageRendererDataSource.h"
#import "MADocumentObjectAttributesText.h"

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
        attt = [[MADocumentObjectAttributesText alloc] initWithFontName: item.fontname
                                                               fontSize: item.fontsize
                                                                   bold: item.bold.boolValue
                                                                 italic: item.italic.boolValue
                                                              underline: item.underline.boolValue
                                                                 strike: item.strike.boolValue
                                                    horizontalAlignment: item.horizontalAlignment.integerValue];
        
        definition.fontDescriptors[item.objectID] = attt;
    }
    
    [self.text drawWithRect: rect
                    options: NSStringDrawingUsesLineFragmentOrigin
                 attributes: attt.fontAttributes
                    context: nil];
    
}

@end
