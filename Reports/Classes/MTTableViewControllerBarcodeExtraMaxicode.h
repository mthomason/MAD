//
//  MTViewControllerBarcodeExtraMaxicode.h
//  MAD
//
//  Created by Michael Thomason on 11/12/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTQueryBuilderChooseFieldViewController.h"

@protocol MTTableViewControllerBarcodeExtraMaxicodeDelegate
- (void)barcodeMaxicodeDidSetEncodingMode:(NSInteger)encodingMode;
- (void)barcodeMaxicodeDidSetPrimaryData:(NSString *)primaryData;
- (void)barcodeMaxicodeDidChooseSampleData:(NSArray *)sampleData;

- (NSInteger)initalEncodingMode;
- (NSString *)initalPrimaryData;
@end

@interface MTTableViewControllerBarcodeExtraMaxicode : UITableViewController
    <MTQueryBuilderChooseFieldDelegate>

@property (nonatomic, weak) id <MTTableViewControllerBarcodeExtraMaxicodeDelegate> delegate;
@property (nonatomic, weak) MAReportDocument *document;

@end
