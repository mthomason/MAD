//
//  MTViewControllerBarcodeOptions.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTViewControllerBarcodeOptions_h
#define Barcodes_MTViewControllerBarcodeOptions_h

#import <MAD/MTKeyChain.h>
#import <MAD/MTQuery.h>
#import <MAD/MADDataTable.h>

#import <MADBarcodes/MADBarcodeBorderStyle.h>

#import "MTViewControllerBarcodeType.h"
#import "MTTableViewControllerBarcodeExtraAztec.h"
#import "MTTableViewControllerBarcodeExtraGridMatrix.h"
#import "MTTableViewControllerBarcodeExtraMicroQrCode.h"
#import "MTTableViewControllerBarcodeExtraQrCode.h"
#import "MTTableViewControllerBarcodeExtraMaxicode.h"
#import "MTTableViewControllerBarcodeExtraDataMatrix.h"
#import "MTTableViewControllerBarcodeExtraPdf417Iso24728.h"

@protocol MTViewControllerBarcodeOptionsDelegate;

@class MTBarcode;

@interface MTViewControllerBarcodeOptions : UITableViewController
    <MADQueryChooseFieldProtocol,
        MTViewControllerBarcodeTypeDelegate,
        MTTableViewControllerBarcodeExtraAztecDelegate,
        MTTableViewControllerBarcodeExtraGridMatrixDelegate,
        MTTableViewControllerBarcodeExtraMicroQrCodeDelegate,
        MTTableViewControllerBarcodeExtraQrCodeDelegate,
        MTTableViewControllerBarcodeExtraMaxicodeDelegate,
        MTTableViewControllerBarcodeExtraDataMatrixDelegate,
        MTTableViewControllerBarcodeExtraPdf417Iso24728Delegate>

    @property (nonatomic, weak) id <MTViewControllerBarcodeOptionsDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, retain) NSArray *sampleBarcodeData;
    @property (nonatomic, retain) NSArray *sampleBarcodeData2dComponent;
    @property (nonatomic, retain) NSArray *sampleBarcodeDataMaxicode;

@end

#endif
