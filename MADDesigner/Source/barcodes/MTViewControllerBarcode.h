//
//  MTViewControllerBarcode.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Barcodes_MTViewControllerBarcode_h
#define Barcodes_MTViewControllerBarcode_h

#import "MADViewControllerBarcodeOptionsDelegate.h"
#import "MTViewControllerBarcodePreview.h"
#import "MTViewControllerBarcodeOptions.h"
#import "MADUnwindProtocol.h"

#import <UIKit/UIViewController.h>

@protocol MADViewControllerBarcodeDelegate;

@class RptqDocumentElementBarcode;

@interface MTViewControllerBarcode : UIViewController <MTViewControllerBarcodeOptionsDelegate, MADUnwindProtocol>

@property (nonatomic, weak) id <MADViewControllerBarcodeDelegate> delegate;
@property (nonatomic, weak) MADocument *document;

@property (nonatomic, assign, readwrite) int64_t queryField1ID;
@property (nonatomic, assign, readwrite) int64_t queryField2ID;
@property (nonatomic, strong, readwrite) MADBarcode *barcode;
@property (nonatomic, strong, readonly) MTViewControllerBarcodeOptions *optionsViewController;

@property (nonatomic, assign) BOOL editmode;

@property (nonatomic, assign) int64_t bartcodeToEditObjectID;
@property (nonatomic, assign) int64_t queryField1ObjectID;
@property (nonatomic, assign) int64_t queryField2ObjectID;

+ (instancetype)newViewControllerBarcode;

- (void)updateBarcode;

- (void)setBarcodeToEdit:(RptqDocumentElementBarcode *)barcodeDocumentObject;

@end

#endif
