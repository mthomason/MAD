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

@property (nonatomic, retain) NSArray *cachedData;

@end

@implementation MTViewControllerBarcode

- (void)dealloc {
    NSString *barcodeTypeString = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessages = NSStringFromSelector(@selector(showErrorMessages));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    [[self optionsViewController] removeObserver:[self barcode] forKeyPath:barcodeTypeString];
    [[self optionsViewController] removeObserver:[self barcode] forKeyPath:showErrorMessages];
    [[self optionsViewController] removeObserver:[self barcode] forKeyPath:humanReadable];

    [_barcode release];
    [_barcodeInput release];
    [_previewViewController release];
    [_optionsViewController release];
    [_cachedData release];
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

    MTBarcode *barcode = [[MTBarcode barcodeWithType:MTBarcodeTypeAztec] retain];
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
    [[self previewViewController] update];
}

#pragma mark - MTViewControllerBarcodeOptionsDelegate

- (MTBarcode *)barcodeToDisplay {
    return [self barcode];
}

- (void)setSampleData:(NSArray *)sampleData {
    [self setCachedData:sampleData];
    if ([sampleData count] > 0) {
        [self setBarcodeInput:[sampleData objectAtIndex:0]];
    }
    [self updateBarcode];
}

- (BOOL)didToggleHumanReadable {
    BOOL humanReadable = ![[self barcode] humanReadable];
    [[self barcode] setHumanReadable:humanReadable];
    [self updateBarcode];
    return humanReadable;
}

- (BOOL)didToggleShowErrorMessages {
    BOOL showErrorMessages = ![[self barcode] showErrorMessages];
    [[self barcode] setShowErrorMessages:showErrorMessages];
    [self updateBarcode];
    return showErrorMessages;
}

- (void)didChangeSymbolHeight:(NSInteger)symbolHeight {
    [[self barcode] setHeight:symbolHeight];
    [self updateBarcode];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    [[self barcode] setBorderWidth:borderWidth];
    [self updateBarcode];
}

- (void)setBorderType:(MTBarcodeBorderStyle)borderStyle {
    [[self barcode] setBorderStyle:borderStyle];
    [self updateBarcode];
}

- (void)setInput:(NSString *)barcodeInput {
    [self setBarcodeInput:barcodeInput];
    [self updateBarcode];
}

#pragma mark - MTViewControllerBarcodePreviewDelegate
- (void)didChangeBarcodeType:(MTBarcodeType)barcodeType {
    MTBarcode *barcode = [[MTBarcode barcodeWithType:barcodeType] retain];
    
    NSString *barcodeTypeString = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessages = NSStringFromSelector(@selector(showErrorMessages));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    [[self optionsViewController] removeObserver:[self barcode] forKeyPath:barcodeTypeString];
    [[self optionsViewController] removeObserver:[self barcode] forKeyPath:showErrorMessages];
    [[self optionsViewController] removeObserver:[self barcode] forKeyPath:humanReadable];
    [[self optionsViewController] addObserver:barcode forKeyPath:barcodeTypeString options:NSKeyValueObservingOptionNew context:NULL];
    [[self optionsViewController] addObserver:barcode forKeyPath:showErrorMessages options:NSKeyValueObservingOptionNew context:NULL];
    [[self optionsViewController] addObserver:barcode forKeyPath:humanReadable options:NSKeyValueObservingOptionNew context:NULL];
    [[self previewViewController] setBarcodeToPreview:barcode];
    [self setBarcode:barcode];
    [barcode release];
    
    //[[self barcode] setBarcodeType:barcodeType];
    //[[self optionsViewController] setBarcodeType:barcodeType];
    [self updateBarcode];
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
        MTViewControllerBarcodeOptions *ovc = (MTViewControllerBarcodeOptions *)[[[segue destinationViewController] topViewController] retain];
        

        [ovc setDelegate:self];
        [self setOptionsViewController:ovc];
        [ovc release];
    }
}

@end
