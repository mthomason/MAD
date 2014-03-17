//
//  MTViewControllerBarcodePreview.m
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerBarcodePreview.h"
#import "MTBarcodeView.h"
#import "MTBarcode.h"

@interface MTViewControllerBarcodePreview ()

@property (nonatomic, retain) IBOutlet UIPickerView *barcodePicker;
@property (nonatomic, retain) IBOutlet MTBarcodeView *barcodeView;

@property (nonatomic, retain) NSDictionary *barcodeNamesByType;
@property (nonatomic, retain) NSArray *barcodeNamesOrdered;
@property (nonatomic, retain) MTBarcode *barcode;

@end

@implementation MTViewControllerBarcodePreview

- (void)dealloc {
    [_barcode release];
    [_barcodeNamesOrdered release];
    [_barcodeNamesByType release];
    [_barcodePicker release];
    [_barcodeView release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSDictionary *namesByType = [[MTBarcode names] retain];
        [self setBarcodeNamesByType:namesByType];
        [namesByType release];
        
        NSArray *allNames = [[self barcodeNamesByType] allValues];
        NSArray *allNamesSorted = [[allNames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
        [self setBarcodeNamesOrdered: allNamesSorted];
        [allNamesSorted release];
        
        
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self barcodeView] setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

//- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    
//}


@end
