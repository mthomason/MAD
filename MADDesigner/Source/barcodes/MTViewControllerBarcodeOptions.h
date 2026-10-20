//
//  MTViewControllerBarcodeOptions.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTViewControllerBarcodeOptions_h
#define Barcodes_MTViewControllerBarcodeOptions_h

#import <MADFoundation/MADDataTable.h>

#import <MADFoundation/MADKeyChain.h>
#import <MADAPI/MADQuery.h>

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

@class MADBarcode;

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
