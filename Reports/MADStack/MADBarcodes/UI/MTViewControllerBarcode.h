//
//  MTViewControllerBarcode.h
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTViewControllerBarcode_h
#define Barcodes_MTViewControllerBarcode_h

#import <UIKit/UIViewController.h>
#import "MADViewControllerBarcodeOptionsDelegate.h"

#import "MTViewControllerBarcodePreview.h"
#import "MTViewControllerBarcodeOptions.h"
#import "MADUnwindProtocol.h"

@protocol MADViewControllerBarcodeDelegate;

@class RptqDocumentElementBarcode, NSManagedObjectID;

@interface MTViewControllerBarcode : UIViewController
    <MTViewControllerBarcodeOptionsDelegate,
        MADUnwindProtocol>

    + (instancetype)newViewControllerBarcode;

    @property (nonatomic, weak) id <MADViewControllerBarcodeDelegate> delegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, strong, readwrite) NSManagedObjectID *queryField1ID;
    @property (nonatomic, strong, readwrite) NSManagedObjectID *queryField2ID;
    @property (nonatomic, strong, readwrite) MTBarcode *barcode;
    @property (nonatomic, strong, readonly) MTViewControllerBarcodeOptions *optionsViewController;

    @property (nonatomic, assign) BOOL editmode;

    - (void)updateBarcode;

    - (void)setBarcodeToEdit:(RptqDocumentElementBarcode *)barcodeDocumentObject;

    @property (nonatomic, copy) NSManagedObjectID *bartcodeToEditObjectID;
    @property (nonatomic, copy) NSManagedObjectID *queryField1ObjectID;
    @property (nonatomic, copy) NSManagedObjectID *queryField2ObjectID;

@end

#endif
