//
//  MTBarcodeView.h
//  Barcodes
//
//  Created by Michael Thomason on 11/3/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Barcodes.h"

@interface MTBarcodeView : UIView

- (id)initWithFrame:(CGRect)frame
               type:(MTBarcodeType)barcodeType
        borderStyle:(MTBarcodeBorderStyle)borderStyle
     stringToEncode:(NSString *)stringToEncode
    whitespaceWidth:(NSInteger)whitespaceWidth;

@end
