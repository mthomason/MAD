//
//  MTViewControllerBarcode.m
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerBarcode.h"
#import "MTBarcodeAztec.h"
#import "MTBarcodeQrCodeIso18004.h"
#import "MTBarcodeMicroQrCode.h"
#import "MTBarcodeGridMatrix.h"
#import "MTBarcodeMaxicodeIso16023.h"
#import "UIDevice+Hack.h"
#import "AppDelegate.h"

NSString * const MTIdentifierSegueDocumentObjectEditBarcode = @"MTIdentifierSegueDocumentObjectEditBarcode";
NSString * const MTDocumentObjectNewBarcodeViewControllerIdentifier = @"MTDocumentObjectNewBarcodeViewControllerIdentifier";

NSString * const MTDocumentObjectNewBarcodeNavigationViewControllerIdentifier = @"MTDocumentObjectNewBarcodeNavigationViewControllerIdentifier";

@interface MTViewControllerBarcode ()

@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemSave;

@property (nonatomic, assign) BOOL editModeBarcodeType;

@property (nonatomic, retain) MTViewControllerBarcodePreview *previewViewController;
@property (nonatomic, retain, readwrite) MTViewControllerBarcodeOptions *optionsViewController;

@property (nonatomic, retain) NSString *barcodeInput;

//@property (nonatomic, retain, readwrite) RptqQueryField *queryField1;
//@property (nonatomic, retain, readwrite) RptqQueryField *queryField2;
//@property (nonatomic, retain, readwrite) MTBarcode *barcode;

@property (nonatomic, retain) NSArray *cachedData;
@property (nonatomic, retain) NSArray *cachedDataMaxicode;
@property (nonatomic, retain) NSArray *cachedData2dComponent;

@property (nonatomic, retain) IBOutlet UIView *topView;
@property (nonatomic, retain) IBOutlet UIView *bottomView;

@end

@implementation MTViewControllerBarcode

- (void)dealloc {
    NSString *barcodeTypeString = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessages = NSStringFromSelector(@selector(showErrorMessages));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    [[self optionsViewController] removeObserver:[self barcode] forKeyPath:barcodeTypeString];
    [[self optionsViewController] removeObserver:[self barcode] forKeyPath:showErrorMessages];
    [[self optionsViewController] removeObserver:[self barcode] forKeyPath:humanReadable];
    [_cachedData release];
    [_cachedDataMaxicode release];
    [_cachedData2dComponent release];
    [_barcode release];
    [_barcodeInput release];
    [_previewViewController release];
    [_optionsViewController release];
    [_queryField1 release];
    [_queryField2 release];
    [_barButtonItemSave release];
    [self setEditmode:NO];
    [_topView release];
    [_bottomView release];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self barButtonItemSave] setEnabled:NO];
    
    UIView *topView = [self topView];
    UIView *bottomView = [self bottomView];
    
    NSString *barcodeViewerHeight = @"200.0000";
    if ([UIDevice isPad]) {
        barcodeViewerHeight = @"250.0000";
    }
    NSString *asciiArtVertConstraint = @"V:|-(==0.0000)-[topView(==%@)]-(==0.0000)-[bottomView]-(==0.0000)-|";
    NSString *asciiArtVert = [NSString stringWithFormat: asciiArtVertConstraint, barcodeViewerHeight];
    NSLog(@"%@", asciiArtVert);
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(topView, bottomView);
    NSArray *constraintsVert = [NSLayoutConstraint constraintsWithVisualFormat:asciiArtVert
                                                                             options:0
                                                                             metrics:nil
                                                                               views:viewsDictionary];
    [[self view] addConstraints:constraintsVert];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([self editmode]) {
        [[self barButtonItemSave] setEnabled:YES];

        
        MTApplicaitonInstance *applicationInstance = [AppDelegate applicationInstance];
        MAReportDocument *reportDocument = [applicationInstance activeDocument];
        RptqDocument *document = [reportDocument activeDocument];
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
        
        __block MTViewControllerBarcodeOptions *optionsViewController = [self optionsViewController];
        if ([self queryField1] != nil) {
            [mnsDatabase sampleDataForSchemaField:[[self queryField1] databaseSchemaField] completion:^(BOOL success, NSError *error, NSArray *resultStrings) {
                if (success) {
                    [optionsViewController setSampleBarcodeData:resultStrings];
                    [[optionsViewController tableView] reloadData];
                }
            }];
        }
        
        if ([self queryField2] != nil) {
            [mnsDatabase sampleDataForSchemaField:[[self queryField2] databaseSchemaField] completion:^(BOOL success, NSError *error, NSArray *resultStrings) {
                if (success) {
                    [optionsViewController setSampleBarcodeData2dComponent:resultStrings];
                    [[optionsViewController tableView] reloadData];
                }
            }];
        }

    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self editmode]) {
        [self setEditmode:NO];
        [self updateBarcode];
    }
}

- (void)commonInit {
    
    [self setEditModeBarcodeType:NO];

    MTBarcode *barcode = [[MTBarcode barcodeWithType:MTBarcodeTypeAztec] retain];
    [barcode setShowErrorMessages:YES];
    [self setBarcode:barcode];
    [barcode release];

}

- (void)updateBarcode {
    [[self barcode] setInput:[self barcodeInput]];
    [[self previewViewController] update];

    if ([self delegate] != nil) {
        [[self delegate] didUpdateBarcode:[self barcode]
                             withFieldOne:[self queryField1]
                              andFieldTwo:[self queryField2]];
    }
    
}

- (void)didSetField1:(RptqQueryField *)field {
    if (field != nil) {
        [[self barButtonItemSave] setEnabled:YES];
    }
    [field retain];
    [self setQueryField1:field];
    [field release];
}

- (void)didSetField2:(RptqQueryField *)field {
    [field retain];
    [self setQueryField2:field];
    [field release];
}

- (RptqQueryField *)barcodeQueryField1 {
    return [[[self queryField1] retain] autorelease];
}

- (RptqQueryField *)barcodeQueryField2 {
    return [[[self queryField2] retain] autorelease];
}

- (void)setBarcodeToEdit:(RptqDocumentObjectBarcode *)barcodeDocumentObject {
    MTBarcode *barcode = [[RptqDocumentObjectBarcode barcodeWithDocumentObject:barcodeDocumentObject] retain];
    
    [self setBarcode:barcode];
    RptqQueryField *field1 = [barcodeDocumentObject referencesField1];
    RptqQueryField *field2 = [barcodeDocumentObject referencesField2];
    [self setQueryField1:field1];
    [self setQueryField2:field2];
    [self setEditmode:YES];

}

#pragma mark - MTViewControllerBarcodeOptionsDelegate

- (void)barcode2dComponentSetEnabled:(BOOL)enabled {
    [[self barcode] setHas2dComponentEnabled:enabled];
    [self updateBarcode];
}

- (void)barcode2dComponentSetType:(NSInteger)type {
    [[self barcode] setHas2dComponentType:type];
    [self updateBarcode];
}

- (void)barcode2dComponentsetSampleData:(NSArray *)sampleData {
 
    [self setCachedData2dComponent:sampleData];
    if ([sampleData count] > 0) {
        [[self barcode] setPrimaryData: [sampleData objectAtIndex:0]];
    }
    [self updateBarcode];

}

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

#pragma mark Aztec

- (void)barcodeAztecDidEnableAutomaticResizing {
    MTBarcodeAztec *barcode = (MTBarcodeAztec *)[self barcode];
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeAztecDidSetSize:(NSInteger)size {
    MTBarcodeAztec *barcode = (MTBarcodeAztec *)[self barcode];
    [barcode setSize:size];
    [self updateBarcode];
}

- (void)barcodeAztecDidSetErrorCorrection:(NSInteger)errorCorrection {
    MTBarcodeAztec *barcode = (MTBarcodeAztec *)[self barcode];
    [barcode setMinmumErrorCorrection:errorCorrection];
    [self updateBarcode];
}

#pragma mark Qr Code

- (void)barcodeQrCodeDidEnableAutomaticResizing {
    MTBarcodeQrCodeIso18004 *barcode = (MTBarcodeQrCodeIso18004 *)[self barcode];
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeQrCodeDidSetSize:(NSInteger)size {
    MTBarcodeQrCodeIso18004 *barcode = (MTBarcodeQrCodeIso18004 *)[self barcode];
    [barcode setSize:size];
    [self updateBarcode];
}

- (void)barcodeQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection {
    MTBarcodeQrCodeIso18004 *barcode = (MTBarcodeQrCodeIso18004 *)[self barcode];
    [barcode setErrorCorrection:errorCorrection];
    [self updateBarcode];
}

#pragma mark Maxicode

- (void)barcodeMaxicodeDidSetEncodingMode:(NSInteger)encodingMode {
    MTBarcodeMaxicodeIso16023 *barcode = (MTBarcodeMaxicodeIso16023 *)[self barcode];
    [barcode setEncodingMode:encodingMode];
    [self updateBarcode];
}
- (void)barcodeMaxicodeDidSetPrimaryData:(NSString *)primaryData {
    MTBarcodeMaxicodeIso16023 *barcode = (MTBarcodeMaxicodeIso16023 *)[self barcode];
    [barcode setPrimaryDataString:primaryData];
    [self updateBarcode];
}

#pragma mark Micro Qr Code

- (void)barcodeMicroQrCodeDidEnableAutomaticResizing {
    MTBarcodeMicroQrCode *barcode = (MTBarcodeMicroQrCode *)[self barcode];
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeMicroQrCodeDidSetSize:(NSInteger)size {
    MTBarcodeMicroQrCode *barcode = (MTBarcodeMicroQrCode *)[self barcode];
    [barcode setSize:size];
    [self updateBarcode];
}

- (void)barcodeMicroQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection {
    MTBarcodeMicroQrCode *barcode = (MTBarcodeMicroQrCode *)[self barcode];
    [barcode setMinmumErrorCorrection:errorCorrection];
    [self updateBarcode];
}

#pragma mark GridMatrix

- (void)barcodeGridMatrixDidEnableAutomaticResizing {
    MTBarcodeGridMatrix *barcode = (MTBarcodeGridMatrix *)[self barcode];
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeGridMatrixDidSetSize:(NSInteger)size {
    MTBarcodeGridMatrix *barcode = (MTBarcodeGridMatrix *)[self barcode];
    [barcode setSize:size];
    [self updateBarcode];
}

- (void)barcodeGridMatrixDidSetErrorCorrection:(NSInteger)errorCorrection {
    MTBarcodeGridMatrix *barcode = (MTBarcodeGridMatrix *)[self barcode];
    [barcode setMinmumErrorCorrection:errorCorrection];
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

//- (IBAction)save:(id)sender {

//}

@end
