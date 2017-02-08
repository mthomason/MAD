//
//  MTElementCanvas.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MTElementCanvas_h
#define MAD_Designer_MTElementCanvas_h

#import <MADBarcodes/MADBarcodes.h>
#import <UIKit/NSStringDrawing.h>

@protocol MADElementCanvasDelegate <NSObject>
    - (id)displayObject;
@end

@class NSParagraphStyle;

@interface MADElementCanvas : UIView

    @property (nonatomic, weak) id <MADElementCanvasDelegate>canvasDelegate;
    @property (nonatomic, strong) UIFont *displayFont;
    @property (nonatomic, strong) NSParagraphStyle *paragraphStyle;
    @property (nonatomic, strong) NSNumber *underlineStyle;
    @property (nonatomic, strong) NSNumber *strikeThroughStyle;
    @property (nonatomic, assign) CGRect drawingRect;

    @property (readonly) NSStringDrawingOptions drawingOptions;

@end

#endif
