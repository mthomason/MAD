//
//  MTViewControllerBarcodeExtraMaxicode.h
//  MAD
//
//  Created by Michael Thomason on 11/12/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTTableViewControllerBarcodeExtraMaxicode_h
#define Barcodes_MTTableViewControllerBarcodeExtraMaxicode_h

#import <UIKit/UIKit.h>
#import "MTQueryBuilderChooseFieldDelegate.h"

@protocol MTTableViewControllerBarcodeExtraMaxicodeDelegate
- (void)barcodeMaxicodeDidSetEncodingMode:(NSInteger)encodingMode;
- (void)barcodeMaxicodeDidSetPrimaryData:(NSString *)primaryData;
- (void)barcodeMaxicodeDidChooseSampleData:(NSArray *)sampleData;

- (NSInteger)initalEncodingMode;
- (NSString *)initalPrimaryData;
@end

@class MADocument;

@interface MTTableViewControllerBarcodeExtraMaxicode : UITableViewController
    <MTQueryBuilderChooseFieldDelegate>

@property (nonatomic, weak) id <MTTableViewControllerBarcodeExtraMaxicodeDelegate> delegate;
@property (nonatomic, weak) MADocument *document;

@end

#endif
