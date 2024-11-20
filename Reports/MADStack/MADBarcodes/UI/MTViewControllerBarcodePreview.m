//
//  MTViewControllerBarcodePreview.m
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTViewControllerBarcodePreview.h"

#import <UIKit/UIPickerView.h>

#import <MADBarcodes/MTBarcode.h>
#import <MADBarcodes/MTBarcodeView.h>


@interface MTViewControllerBarcodePreview ()

    @property (nonatomic, weak) IBOutlet UIPickerView *barcodePicker;
    @property (nonatomic, weak) IBOutlet MTBarcodeView *barcodeView;

    @property (nonatomic, strong) NSDictionary *barcodeNamesByType;
    @property (nonatomic, strong) NSArray *barcodeNamesOrdered;
    @property (nonatomic, strong) MTBarcode *barcode;

@end

@implementation MTViewControllerBarcodePreview

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSDictionary *namesByType = [MTBarcode newDictionaryNames];
        NSArray *names = namesByType.allValues;

        self.barcodeNamesByType = namesByType;
        
        NSArray *namesSorted = [names sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        namesSorted = [[NSArray alloc] initWithArray: namesSorted];
        self.barcodeNamesOrdered = namesSorted;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.barcodeView.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void)setBarcodeToPreview:(MTBarcode *)barcode {
    self.barcode = barcode;
    (self.barcodeView).barcode = barcode;
}

- (void)update {
    if ((self.barcodeView).barcode == nil) {
        (self.barcodeView).barcode = self.barcode;
    }
    [self.barcodeView setNeedsDisplay];
}

@end
