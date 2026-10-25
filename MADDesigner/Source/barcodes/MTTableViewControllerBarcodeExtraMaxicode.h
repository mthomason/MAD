//
//  MTViewControllerBarcodeExtraMaxicode.h
//  MAD
//
//  Created by Michael Thomason on 11/12/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MTTableViewControllerBarcodeExtraMaxicode_h
#define Barcodes_MTTableViewControllerBarcodeExtraMaxicode_h

#import <UIKit/UITableViewController.h>
#import "MADQueryChooseFieldProtocol.h"

@protocol MTTableViewControllerBarcodeExtraMaxicodeDelegate
    - (void)barcodeMaxicodeDidSetEncodingMode:(NSInteger)encodingMode;
    - (void)barcodeMaxicodeDidSetPrimaryData:(NSString *)primaryData;
    - (void)barcodeMaxicodeDidChooseSampleData:(NSArray *)sampleData;

    - (NSInteger)initalEncodingMode;
    - (NSString *)initalPrimaryData;
@end

@class MADocument;

@interface MTTableViewControllerBarcodeExtraMaxicode : UITableViewController
    <MADQueryChooseFieldProtocol>

@property (nonatomic, weak) id <MTTableViewControllerBarcodeExtraMaxicodeDelegate> delegate;
@property (nonatomic, weak) MADocument *document;

@end

#endif
