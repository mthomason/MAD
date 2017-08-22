//
//  MADDesignerLayout.h
//  MAD
//
//  Created by Michael on 8/21/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADocumentLayout_h
#define Reports_MADocumentLayout_h

#import <Foundation/NSObject.h>

@class NSManagedObjectContext;
@protocol MADocumentDesignerProtocol;

@interface MADDesignerLayout : NSObject

    @property (nonatomic, weak) id <MADocumentDesignerProtocol> delegate;

    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setBold:(BOOL)bold;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setItalic:(BOOL)italic;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setStrikethrough:(BOOL)strikethrough;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setUnderline:(BOOL)underline;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setFontsize:(double)fontsize;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setFontname:(NSString *)fontname;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setVerticalAlignment:(int16_t)verticalAlignment;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setHorizontalAlignment:(int16_t)horizontalAlignment;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setSizeWidth:(float)width;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setSizeHeight:(float)height;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginBottom:(float)bottom;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginTop:(float)top;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginLeft:(float)left;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginRight:(float)right;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingBottom:(float)bottom;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingTop:(float)top;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingLeft:(float)left;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingRight:(float)right;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderBottom:(float)bottom;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderTop:(float)top;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderLeft:(float)left;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderRight:(float)right;
    - (void)updateElements:(NSSet <NSNumber *> *)identifiers
                actionName:(NSString *)actionName
             updateHandler:(void (^)(long long identifier))updateHandler
               undoHandler:(void (^)(id target))undoHandler;

@end

#endif
