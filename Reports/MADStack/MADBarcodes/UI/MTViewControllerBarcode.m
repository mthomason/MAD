//
//  MTViewControllerBarcode.m
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTViewControllerBarcode.h"
#import "MADNavigationBarTitleView.h"

NSString * const MTDocumentObjectNewBarcodeNavigationViewControllerIdentifier = @"MTDocumentObjectNewBarcodeNavigationViewControllerIdentifier";

@interface MTViewControllerBarcode ()
    <MTDatabaseProtocol>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemSave;

@property (nonatomic, assign) BOOL editModeBarcodeType;

@property (nonatomic, strong) MTViewControllerBarcodePreview *previewViewController;
@property (nonatomic, strong, readwrite) MTViewControllerBarcodeOptions *optionsViewController;

@property (nonatomic, strong) NSString *barcodeInput;

@property (nonatomic, strong) NSArray *cachedData;
@property (nonatomic, strong) NSArray *cachedDataMaxicode;
@property (nonatomic, strong) NSArray *cachedData2dComponent;

@property (nonatomic, weak) IBOutlet UIView *topView;
@property (nonatomic, weak) IBOutlet UIView *bottomView;

@property (nonatomic, strong) MTQuery *query;
@property (nonatomic, strong) MTQuery *query2;

@property (nonatomic, strong) MTDataTable *dataTableSampleData;
@property (nonatomic, strong) MTDataTable *dataTableSampleData2;

@end

@implementation MTViewControllerBarcode

@synthesize unwindViewController;

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return NO;
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return self.unwindViewController ?
            self.unwindViewController :
            [super viewControllerForUnwindSegueAction: action
                           fromViewController: fromViewController
                                   withSender: sender];
}

- (void)dealloc {
    NSString *barcodeTypeString = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessages = NSStringFromSelector(@selector(showErrorMessages));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    [self.optionsViewController removeObserver:self.barcode forKeyPath:barcodeTypeString];
    [self.optionsViewController removeObserver:self.barcode forKeyPath:showErrorMessages];
    [self.optionsViewController removeObserver:self.barcode forKeyPath:humanReadable];
    [self setEditmode:NO];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];
    titleView.text = NSLocalizedString(@"MAD Barcodes", @"Title of the barcode creator.");
    self.navigationItem.titleView = titleView;

    [self.barButtonItemSave setEnabled:NO];
    
    UIView *topView = [self topView];
    UIView *bottomView = [self bottomView];
    
    NSString *barcodeViewerHeight = @"200.0000";
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        barcodeViewerHeight = @"250.0000";
    }
    NSString *asciiArtVertConstraint = @"V:|-(==0.0000)-[topView(==%@)]-(==0.0000)-[bottomView]-(==0.0000)-|";
    NSString *asciiArtVert = [NSString stringWithFormat: asciiArtVertConstraint, barcodeViewerHeight];
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(topView, bottomView);
    NSArray *constraintsVert = [NSLayoutConstraint constraintsWithVisualFormat:asciiArtVert
                                                                             options:0
                                                                             metrics:nil
                                                                               views:viewsDictionary];
    [self.view addConstraints:constraintsVert];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.editmode) {
        self.barButtonItemSave.enabled = YES;
        
        if (self.queryField1 != nil) {

            MTQuery *querySampleDataField = [[MTQuery alloc] initWithQueryType: MTQueryTypeSampleDataField
                                                                        object: self.queryField1.databaseSchemaField];
            [querySampleDataField database].delegate = self;
            self.query = querySampleDataField;
            NSError * __autoreleasing error = NULL;
            bool success = [self.query performQueryWithError:&error];
            if (success) {
                NSArray *allObjects = [self.dataTableSampleData allObjects];
                [self.optionsViewController setSampleBarcodeData:allObjects];
                [self.optionsViewController.tableView reloadData];
            } else {
                __weak MTViewControllerBarcode *weakself2 = self;
                [NSError presentError: error
                     onViewController: weakself2
                           completion:^(BOOL presentErrorSuccess) {
                               NSString *key = [NSString stringWithString:querySampleDataField.database.databaseConnection.connectionString];
                               [[MTKeyChain sharedObject] deleteKey:key usingViewController:weakself2];
                           }];
                
            }
        }
        
        if (self.queryField2 != nil) {
            
            MTQuery *querySampleDataField = [[MTQuery alloc] initWithQueryType: MTQueryTypeSampleDataField
                                                                        object: self.queryField2.databaseSchemaField];
            [querySampleDataField database].delegate = self;
            self.query2 = querySampleDataField;
            NSError * __autoreleasing error = NULL;
            bool success = [self.query2 performQueryWithError:&error];

            if (success) {
                NSArray *allObjects = [self.dataTableSampleData2 allObjects];
                [self.optionsViewController setSampleBarcodeData2dComponent:allObjects];
                [self.optionsViewController.tableView reloadData];
            } else {
                __weak MTViewControllerBarcode *weakself = self;
                [NSError presentError: error
                     onViewController: weakself
                           completion:^(BOOL presentErrorSuccess) {
                               __strong MTViewControllerBarcode *strongself2 = weakself;
                               __weak MTViewControllerBarcode *weak = strongself2;
                               NSString *key = [NSString stringWithString:querySampleDataField.database.databaseConnection.connectionString];
                               [[MTKeyChain sharedObject] deleteKey:key usingViewController:weak];
                           }];
                
            }
        }

    }
    
    self.preferredContentSize = CGSizeMake(320.0000f, 1024.0000f);
    self.navigationController.preferredContentSize = CGSizeMake(320.0000f, 1024.0000f);
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    if ([query isEqual:self.query]) {
        return [self dataTableSampleData];
    } else if ([query isEqual:self.query2]) {
        return [self dataTableSampleData2];
    } else {
        NSAssert(false, @"Unknown query at %s.", __PRETTY_FUNCTION__);
        return nil;
    }
}

+ (MTDataTable *)newDataTableForMangedObject:(NSManagedObjectID *)objectID {
    return [MTDataTable newDataTableForIdentifier:[[objectID URIRepresentation] absoluteString]];
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

    MTBarcode *barcode = [MTBarcode barcodeWithType:MTBarcodeTypeAztec];
    [barcode setShowErrorMessages:YES];
    [self setBarcode:barcode];
}

- (void)updateBarcode {
    [self.barcode setInput:[self barcodeInput]];
    [[self previewViewController] update];

    if (self.delegate != nil) {
        [self.delegate didUpdateBarcode:self.barcode
                             withFieldOne:[self queryField1]
                              andFieldTwo:[self queryField2]];
    }
}

- (void)didSetField1:(RptqQueryField *)field {
    if (field != nil) {
        [self.barButtonItemSave setEnabled:YES];
    }
    [self setQueryField1:field];
}

- (void)didSetField2:(RptqQueryField *)field {
    [self setQueryField2:field];
}

- (RptqQueryField *)barcodeQueryField1 {
    return [self queryField1];
}

- (RptqQueryField *)barcodeQueryField2 {
    return [self queryField2];
}

- (void)setBarcodeToEdit:(RptqDocumentObjectBarcode *)barcodeDocumentObject {
    MTBarcode *barcode = [RptqDocumentObjectBarcode barcodeWithDocumentObject:barcodeDocumentObject];
    [self setBarcode:barcode];
    
    RptqQueryField *field1 = [barcodeDocumentObject referencesField1];
    RptqQueryField *field2 = [barcodeDocumentObject referencesField2];
    [self setQueryField1:field1];
    [self setQueryField2:field2];
    [self setEditmode:YES];

}

#pragma mark - MTViewControllerBarcodeOptionsDelegate

- (void)barcode2dComponentSetEnabled:(BOOL)enabled {
    [self.barcode setHas2dComponentEnabled:enabled];
    [self updateBarcode];
}

- (void)barcode2dComponentSetType:(NSInteger)type {
    [self.barcode setHas2dComponentType:type];
    [self updateBarcode];
}

- (void)barcode2dComponentsetSampleData:(NSArray *)sampleData {
 
    [self setCachedData2dComponent:sampleData];
    if ([sampleData count] > 0) {
        [self.barcode setPrimaryData: sampleData[0]];
    }
    [self updateBarcode];

}

- (MTBarcode *)barcodeToDisplay {
    return self.barcode;
}

- (void)setSampleData:(NSArray *)sampleData {
    [self setCachedData:sampleData];
    if ([sampleData count] > 0) {
        [self setBarcodeInput:sampleData[0]];
    }
    [self updateBarcode];
}

- (BOOL)didToggleHumanReadable {
    BOOL humanReadable = ![self.barcode humanReadable];
    [self.barcode setHumanReadable:humanReadable];
    [self updateBarcode];
    return humanReadable;
}

- (BOOL)didToggleShowErrorMessages {
    BOOL showErrorMessages = ![self.barcode showErrorMessages];
    [self.barcode setShowErrorMessages:showErrorMessages];
    [self updateBarcode];
    return showErrorMessages;
}

- (void)didChangeSymbolHeight:(NSInteger)symbolHeight {
    [self.barcode setHeight:symbolHeight];
    [self updateBarcode];
}

- (void)setBorderWidth:(NSUInteger)borderWidth {
    self.barcode.borderWidth = borderWidth;
    [self updateBarcode];
}

- (void)setBorderType:(MTBarcodeBorderStyle)borderStyle {
    [self.barcode setBorderStyle:borderStyle];
    [self updateBarcode];
}

- (void)setInput:(NSString *)barcodeInput {
    [self setBarcodeInput:barcodeInput];
    [self updateBarcode];
}

#pragma mark Aztec

- (void)barcodeAztecDidEnableAutomaticResizing {
    MTBarcodeAztec *barcode = (MTBarcodeAztec *)self.barcode;
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeAztecDidSetSize:(NSInteger)size {
    MTBarcodeAztec *barcode = (MTBarcodeAztec *)self.barcode;
    [barcode setSize:size];
    [self updateBarcode];
}

- (void)barcodeAztecDidSetErrorCorrection:(NSInteger)errorCorrection {
    MTBarcodeAztec *barcode = (MTBarcodeAztec *)self.barcode;
    [barcode setMinmumErrorCorrection:errorCorrection];
    [self updateBarcode];
}

#pragma mark Qr Code

- (void)barcodeQrCodeDidEnableAutomaticResizing {
    MTBarcodeQrCodeIso18004 *barcode = (MTBarcodeQrCodeIso18004 *)self.barcode;
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeQrCodeDidSetSize:(NSInteger)size {
    MTBarcodeQrCodeIso18004 *barcode = (MTBarcodeQrCodeIso18004 *)self.barcode;
    [barcode setSize:size];
    [self updateBarcode];
}

- (void)barcodeQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection {
    MTBarcodeQrCodeIso18004 *barcode = (MTBarcodeQrCodeIso18004 *)self.barcode;
    [barcode setErrorCorrection:errorCorrection];
    [self updateBarcode];
}

#pragma mark Maxicode

- (void)barcodeMaxicodeDidSetEncodingMode:(NSInteger)encodingMode {
    MTBarcodeMaxicodeIso16023 *barcode = (MTBarcodeMaxicodeIso16023 *)self.barcode;
    [barcode setEncodingMode:encodingMode];
    [self updateBarcode];
}
- (void)barcodeMaxicodeDidSetPrimaryData:(NSString *)primaryData {
    MTBarcodeMaxicodeIso16023 *barcode = (MTBarcodeMaxicodeIso16023 *)self.barcode;
    [barcode setPrimaryDataString:primaryData];
    [self updateBarcode];
}

#pragma mark Micro Qr Code

- (void)barcodeMicroQrCodeDidEnableAutomaticResizing {
    MTBarcodeMicroQrCode *barcode = (MTBarcodeMicroQrCode *)self.barcode;
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeMicroQrCodeDidSetSize:(NSInteger)size {
    MTBarcodeMicroQrCode *barcode = (MTBarcodeMicroQrCode *)self.barcode;
    [barcode setSize:size];
    [self updateBarcode];
}

- (void)barcodeMicroQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection {
    MTBarcodeMicroQrCode *barcode = (MTBarcodeMicroQrCode *)self.barcode;
    [barcode setMinmumErrorCorrection:errorCorrection];
    [self updateBarcode];
}

#pragma mark GridMatrix

- (void)barcodeGridMatrixDidEnableAutomaticResizing {
    MTBarcodeGridMatrix *barcode = (MTBarcodeGridMatrix *)self.barcode;
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeGridMatrixDidSetSize:(NSInteger)size {
    MTBarcodeGridMatrix *barcode = (MTBarcodeGridMatrix *)self.barcode;
    [barcode setSize:size];
    [self updateBarcode];
}

- (void)barcodeGridMatrixDidSetErrorCorrection:(NSInteger)errorCorrection {
    MTBarcodeGridMatrix *barcode = (MTBarcodeGridMatrix *)self.barcode;
    [barcode setMinmumErrorCorrection:errorCorrection];
    [self updateBarcode];
}

#pragma mark PDF 417

- (void)barcodePDF417DidSetColumns:(NSInteger)columns {
    ((MTBarcodePdf417Iso15438 *)self.barcode).width = columns;
    [self updateBarcode];
}

- (void)barcodePDF417DidSetFormat:(NSInteger)format {
    ((MTBarcodePdf417Iso15438 *)self.barcode).format = format;
    [self updateBarcode];
}

- (void)barcodePDF417DidSetErrorCorrection:(NSInteger)errorCorrection {
    ((MTBarcodePdf417Iso15438 *)self.barcode).errorCorrectionCapacity = errorCorrection;
    [self updateBarcode];
}

#pragma mark - MTViewControllerBarcodePreviewDelegate
- (void)didChangeBarcodeType:(MTBarcodeType)barcodeType {
    MTBarcode *barcode = [MTBarcode barcodeWithType:barcodeType];
    
    NSString *barcodeTypeString = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessages = NSStringFromSelector(@selector(showErrorMessages));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    [self.optionsViewController removeObserver:self.barcode forKeyPath:barcodeTypeString];
    [self.optionsViewController removeObserver:self.barcode forKeyPath:showErrorMessages];
    [self.optionsViewController removeObserver:self.barcode forKeyPath:humanReadable];
    [self.optionsViewController addObserver:barcode forKeyPath:barcodeTypeString options:NSKeyValueObservingOptionNew context:NULL];
    [self.optionsViewController addObserver:barcode forKeyPath:showErrorMessages options:NSKeyValueObservingOptionNew context:NULL];
    [self.optionsViewController addObserver:barcode forKeyPath:humanReadable options:NSKeyValueObservingOptionNew context:NULL];
    [[self previewViewController] setBarcodeToPreview:barcode];
    [self setBarcode:barcode];
    
    [self updateBarcode];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    NSString *identifier = segue.identifier;
    if ([identifier isEqualToString:@"MTIdentifierSegueBarcodePreview"]) {
        MTViewControllerBarcodePreview *pvc = segue.destinationViewController;
        pvc.delegate = self;
        [pvc setBarcodeToPreview:self.barcode];
        [[pvc view] layoutIfNeeded];
        [self setPreviewViewController:pvc];
    } else if ([identifier isEqualToString:@"MTIdentifierSegueBarcodeTable"]) {
        MTViewControllerBarcodeOptions *ovc = (MTViewControllerBarcodeOptions *)[segue.destinationViewController topViewController];
        ovc.delegate = self;
        ovc.document = self.document;
        [self setOptionsViewController:ovc];
    }
}

@end
