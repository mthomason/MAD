//
//  MTViewControllerBarcode.m
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerBarcode.h"
#import "zint.h"

@interface MTViewControllerBarcode ()

@property (nonatomic, assign) BOOL editModeBarcodeType;
@property (nonatomic, retain) MTViewControllerBarcodePreview *previewViewController;
@property (nonatomic, retain) MTViewControllerBarcodeOptions *optionsViewController;

@property (nonatomic, retain) NSString *barcodeInput;

@property (nonatomic, retain) MTBarcode *barcode;

@end

@implementation MTViewControllerBarcode

- (void)dealloc {
    [_barcode release];
    [_barcodeInput release];
    [_previewViewController release];
    [_optionsViewController release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    [self setEditModeBarcodeType:NO];

    MTBarcode *barcode = [[MTBarcode alloc] init];
    [barcode setShowErrorMessages:YES];
    [self setBarcode:barcode];
    [barcode release];

}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

- (void)updateBarcode {
    [[self barcode] setInput:[self barcodeInput]];
    [[self barcode] encodeAndBuffer];
    [[self previewViewController] update];
}

#pragma mark - MTViewControllerBarcodeOptionsDelegate

- (void)didToggleHumanReadable {
    BOOL humanReadable = [[self barcode] humanReadable];
    [[self barcode] setHumanReadable:!humanReadable];
    [[self previewViewController] update];
}

- (void)didToggleShowErrorMessages {
    BOOL showErrorMessages = [[self barcode] showErrorMessages];
    [[self barcode] setShowErrorMessages:!showErrorMessages];
    [[self previewViewController] update];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    [[self barcode] setBorderWidth:borderWidth];
    [[self previewViewController] update];
}

- (void)setBorderType:(MTBarcodeBorderStyle)borderStyle {
    [[self barcode] setBorderStyle:borderStyle];
    [[self previewViewController] update];
}

- (void)setInput:(NSString *)barcodeInput {
    [self setBarcodeInput:barcodeInput];
    [[self previewViewController] update];
}

#pragma mark - MTViewControllerBarcodePreviewDelegate

- (void)didChangeBarcodeType:(MTBarcodeType)type {
    [[self barcode] setBarcodeType:type];
    [[self optionsViewController] setBarcodeType:type];
    [[self previewViewController] update];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    NSString *identifier = [segue identifier];
    if ([identifier isEqualToString:@"MTIdentifierSegueBarcodePreview"]) {
        MTViewControllerBarcodePreview *pvc = [[segue destinationViewController] retain];
        [pvc setDelegate:self];
        [pvc setBarcodeToPreview:[self barcode]];
        [[pvc view] layoutIfNeeded];
        [self setPreviewViewController:pvc];
        [pvc release];
    } else if ([identifier isEqualToString:@"MTIdentifierSegueBarcodeTable"]) {
        MTViewControllerBarcodeOptions *ovc = [[segue destinationViewController] retain];
        [self setOptionsViewController:ovc];
        [ovc release];
    }
}

@end
