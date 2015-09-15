//
//  MTViewControllerBarcodePreview.m
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTViewControllerBarcodePreview.h"

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
        NSDictionary *namesByType = [MTBarcode names];
        [self setBarcodeNamesByType:namesByType];
        
        NSArray *allNames = [[self barcodeNamesByType] allValues];
        NSArray *allNamesSorted = [allNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [self setBarcodeNamesOrdered: allNamesSorted];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self barcodeView].backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setBarcodeToPreview:(MTBarcode *)barcode {
    [self setBarcode:barcode];
    [[self barcodeView] setBarcode:barcode];
}

- (void)update {
    if ([[self barcodeView] barcode] == nil) {
        [[self barcodeView] setBarcode:[self barcode]];
    }
    [[self barcodeView] setNeedsDisplay];
}

@end
