//
//  BarcodeInterface.h
//  Barcodes
//
//  Created by Michael Thomason on 2/15/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTBarcodeProtocol_h
#define Barcodes_MTBarcodeProtocol_h

#import <Foundation/NSObject.h>
#import <MADBarcodes/MADBarcodeType.h>
#import <MADBarcodes/MADBarcodeBorderStyle.h>

@protocol MTBarcodeProtocol <NSObject>

  @required

    @property (nonatomic, assign, readonly) int16_t barcodeType;
	@property (nonatomic, assign) int16_t barcodeBorderStyle;
    @property (nonatomic, assign) int16_t whitespaceWidth;
    @property (nonatomic, assign) BOOL has2dComponentEnabled;
    @property (nonatomic, assign) int16_t barcodeBorderWidth;
    @property (nonatomic, assign) int16_t barcodeHeight;
    @property (nonatomic, assign) BOOL humanReadable;
    @property (nonatomic, assign) int16_t option1;
    @property (nonatomic, assign) int16_t option2;
    @property (nonatomic, assign) int16_t option3;
    @property (nonatomic, assign) BOOL showErrorMessage;
    @property (nonatomic, assign) float scale;


  @optional

@end

#endif
