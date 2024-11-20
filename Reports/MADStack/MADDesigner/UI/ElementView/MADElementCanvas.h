//
//  MADElementCanvas.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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

@end

#endif
