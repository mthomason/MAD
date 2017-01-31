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
#import "MADViewControllerBarcodeDelegate.h"

#import <CoreData/NSManagedObjectID.h>

#import <UIKit/UIStoryboard.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UIStoryboardSegue.h>

#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MADAlertController.h>

#import <MAD/MTDataTable.h>
#import <MAD/MTDatabase.h>
#import <MAD/MADDatabaseProtocol.h>
#import <MAD/MADDatabaseConnection.h>

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>

#import <MAD/RptqDocumentElementBarcode.h>
#import <MAD/RptqDocumentElementBarcode+Extras.h>

#import <MADBarcodes/MTBarcodeDataMatrixIso16022.h>
#import <MADBarcodes/MTBarcodeCode39Iso16388.h>
#import <MADBarcodes/MTBarcodeAztec.h>
#import <MADBarcodes/MTBarcodeQrCodeIso18004.h>
#import <MADBarcodes/MTBarcodeGridMatrix.h>
#import <MADBarcodes/MTBarcodeMicroQrCode.h>
#import <MADBarcodes/MTBarcodeMaxicodeIso16023.h>
#import <MADBarcodes/MTBarcodePdf417Iso15438.h>
#import <MADBarcodes/MTBarcodeCodeOne.h>
#import <MADBarcodes/MTBarcodeDatabarStacked.h>
#import <MADBarcodes/MTBarcodeDatabarExpandedStacked.h>
#import <MADBarcodes/MTBarcodeMsiPlessey.h>
#import <MADBarcodes/MTBarcodeMicroPdf417Iso24728.h>
#import <MADBarcodes/MTBarcodeChannelCode.h>
#import <MADBarcodes/MTBarcodeCode39Extended.h>

#import "MADNavigationBarTitleView.h"
#import "MTViewControllerBarcodePreviewDelegate.h"

#import "MADLabelTitle.h"

static NSString * const MTDocumentObjectNewBarcodeNavigationViewControllerIdentifier =
                                @"MTDocumentObjectNewBarcodeNavigationViewControllerIdentifier";

@interface MTViewControllerBarcode ()
    <MTDatabaseProtocol, MTViewControllerBarcodePreviewDelegate>

    @property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemSave;

    @property (nonatomic, assign) BOOL editModeBarcodeType;

    @property (nonatomic, strong) MTViewControllerBarcodePreview *previewViewController;
    @property (nonatomic, strong, readwrite) MTViewControllerBarcodeOptions *optionsViewController;

    @property (nonatomic, copy) NSString *barcodeInput;

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

+ (instancetype)newViewControllerBarcode {
    static NSString * const ObjectSelector = @"MADStoryboardObjectSelector";
    static NSString * const MainIdentifier = @"MADIdentifierBarcodeViewController";
    id bundle = [NSBundle mainBundle];
    id storyboard = [UIStoryboard storyboardWithName: ObjectSelector bundle: bundle];
    id result = [storyboard instantiateViewControllerWithIdentifier: MainIdentifier];
    return result;
}

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
    
    MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
    titleView.text = NSLocalizedString(@"MAD Barcodes", @"Title of the barcode creator.");
    self.navigationItem.titleView = titleView;

    [self.barButtonItemSave setEnabled:NO];
    
    UIView *topView = self.topView;
    UIView *bottomView = self.bottomView;
    
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

            MTQuery *querySampleDataField = [[MTQuery alloc] initWithQueryType: MADQueryTypeSampleDataField
                                                                        object: self.queryField1.databaseSchemaField];
            querySampleDataField.database.delegate = self;
            self.query = querySampleDataField;
            NSError * __autoreleasing error = NULL;
            BOOL success = [self.query performQueryWithError:&error];
            if (success) {
                
                NSArray *allObjects = [self.dataTableSampleData allObjects];
                (self.optionsViewController).sampleBarcodeData = allObjects;
                [self.optionsViewController.tableView reloadData];
                
            } else {
                
                MTViewControllerBarcode * __weak weakself2 = self;
                
                [NSError presentError: error
                     onViewController: weakself2
                           completion: ^(BOOL presentErrorSuccess) {
                               
                               UIAlertController *alertController;
                               NSString *key;
                               
                               key = [NSString stringWithString:querySampleDataField.database.databaseConnection.connectionString];
                               
                               alertController = [MADAlertController removeCredentials:^(UIAlertAction *action) {
                                   [MTKeyChain deleteKey:key];
                               } cancel:nil];
                               
                               [weakself2 presentViewController: alertController
                                                       animated: YES
                                                     completion: nil];
                               
                           }];
                
            }
        }
        
        if (self.queryField2 != nil) {
            
            MTQuery *querySampleDataField = [[MTQuery alloc] initWithQueryType: MADQueryTypeSampleDataField
                                                                        object: self.queryField2.databaseSchemaField];
            querySampleDataField.database.delegate = self;
            self.query2 = querySampleDataField;
            NSError * __autoreleasing error = NULL;
            BOOL success = [self.query2 performQueryWithError:&error];

            if (success) {
                NSArray *allObjects = [self.dataTableSampleData2 allObjects];
                (self.optionsViewController).sampleBarcodeData2dComponent = allObjects;
                [self.optionsViewController.tableView reloadData];
            } else {
                MTViewControllerBarcode * __weak weakself = self;
                
                [NSError presentError: error
                     onViewController: weakself
                           completion:^(BOOL presentErrorSuccess) {
                               MTViewControllerBarcode *strongself2 = weakself;

                               NSString *key = [NSString stringWithString:querySampleDataField.database.databaseConnection.connectionString];
                               UIAlertController *alertController = [MADAlertController removeCredentials:^(UIAlertAction *action) {
                                   [MTKeyChain deleteKey:key];
                               } cancel:nil];
                               [strongself2 presentViewController:alertController animated:YES
                                                       completion:nil];
                           }];
                
            }
        }

    }
    
    self.preferredContentSize = CGSizeMake(320.0000f, 1024.0000f);
    self.navigationController.preferredContentSize = CGSizeMake(320.0000f, 1024.0000f);
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {

    if ([query isEqual:self.query]) {
        return self.dataTableSampleData;

    } else if ([query isEqual:self.query2]) {
        return self.dataTableSampleData2;

    } else {
        NSAssert(NO, @"Unknown query at %s.", __PRETTY_FUNCTION__);
        return nil;
    }
}

+ (MTDataTable *)newDataTableForMangedObject:(NSManagedObjectID *)objectID {
    return [MTDataTable newDataTableForIdentifier:[objectID URIRepresentation].absoluteString];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.editmode) {
        [self setEditmode:NO];
        [self updateBarcode];
    }
}

- (void)commonInit {
    
    [self setEditModeBarcodeType:NO];

    MTBarcode *barcode = [MTBarcode newBarcodeWithType:MTBarcodeTypeAztec];
    [barcode setShowErrorMessages:YES];
    self.barcode = barcode;
}

- (void)updateBarcode {

    self.barcode.input = self.barcodeInput;
    [self.previewViewController update];
    
    [self.delegate didUpdateBarcodeWithObjectID:self.bartcodeToEditObjectID barcodeObject:self.barcode withFieldOne:self.queryField1 andFieldTwo:self.queryField2];
}

- (void)didSetField1:(RptqQueryField *)field {
    if (field != nil) {
        [self.barButtonItemSave setEnabled:YES];
    }
    self.queryField1 = field;
}

- (void)didSetField2:(RptqQueryField *)field {
    self.queryField2 = field;
}

- (RptqQueryField *)barcodeQueryField1 {
    return self.queryField1;
}

- (RptqQueryField *)barcodeQueryField2 {
    return self.queryField2;
}

- (void)setBarcodeToEdit:(RptqDocumentElementBarcode *)barcodeDocumentObject {

    MTBarcode *barcode = [RptqDocumentElementBarcode newBarcodeWithDocumentObject:barcodeDocumentObject];
    self.barcode = barcode;
    
    self.queryField1 = barcodeDocumentObject.referencesField1;
    self.queryField2 = barcodeDocumentObject.referencesField2;
    
    self.editmode = YES;

}

- (void)setBarcodeObjectIDToEdit:(NSManagedObjectID *)objectID {
    
}

#pragma mark - MTViewControllerBarcodeOptionsDelegate

- (void)barcode2dComponentSetEnabled:(BOOL)enabled {
    (self.barcode).has2dComponentEnabled = enabled;
    [self updateBarcode];
}

- (void)barcode2dComponentSetType:(NSInteger)type {
    (self.barcode).has2dComponentType = type;
    [self updateBarcode];
}

- (void)barcode2dComponentsetSampleData:(NSArray *)sampleData {
 
    self.cachedData2dComponent = sampleData;
    if (sampleData.count > 0) {
        (self.barcode).primaryData = sampleData[0];
    }
    [self updateBarcode];

}

- (MTBarcode *)barcodeToDisplay {
    return self.barcode;
}

- (void)setSampleData:(NSArray *)sampleData {
    self.cachedData = sampleData;
    if (sampleData.count > 0) {
        self.barcodeInput = sampleData[0];
    }
    [self updateBarcode];
}

- (BOOL)didToggleHumanReadable {
    BOOL humanReadable = !self.barcode.humanReadable;
    self.barcode.humanReadable = humanReadable;
    [self updateBarcode];
    return humanReadable;
}

- (BOOL)didToggleShowErrorMessages {
    BOOL showErrorMessages = !(self.barcode).showErrorMessages;
    (self.barcode).showErrorMessages = showErrorMessages;
    [self updateBarcode];
    return showErrorMessages;
}

- (void)didChangeSymbolHeight:(NSInteger)symbolHeight {
    self.barcode.height = symbolHeight;
    [self updateBarcode];
}

- (void)setBorderWidth:(NSInteger)borderWidth {
    self.barcode.borderWidth = borderWidth;
    [self updateBarcode];
}

- (void)setBorderType:(MTBarcodeBorderStyle)borderStyle {
    (self.barcode).borderStyle = borderStyle;
    [self updateBarcode];
}

- (void)setInput:(NSString *)barcodeInput {
    self.barcodeInput = barcodeInput.copy;
    [self updateBarcode];
}

#pragma mark Aztec

- (void)barcodeAztecDidEnableAutomaticResizing {
    MTBarcodeAztec *barcode = (MTBarcodeAztec *)self.barcode;
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeAztecDidSetSize:(NSUInteger)size {
    MTBarcodeAztec *barcode = (MTBarcodeAztec *)self.barcode;
    barcode.size = size;
    [self updateBarcode];
}

- (void)barcodeAztecDidSetErrorCorrection:(NSUInteger)errorCorrection {
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
    MTBarcode *barcode = [MTBarcode newBarcodeWithType:barcodeType];
    
    NSString *barcodeTypeString = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessages = NSStringFromSelector(@selector(showErrorMessages));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    [self.optionsViewController removeObserver:self.barcode forKeyPath:barcodeTypeString];
    [self.optionsViewController removeObserver:self.barcode forKeyPath:showErrorMessages];
    [self.optionsViewController removeObserver:self.barcode forKeyPath:humanReadable];
    [self.optionsViewController addObserver:barcode forKeyPath:barcodeTypeString options:NSKeyValueObservingOptionNew context:NULL];
    [self.optionsViewController addObserver:barcode forKeyPath:showErrorMessages options:NSKeyValueObservingOptionNew context:NULL];
    [self.optionsViewController addObserver:barcode forKeyPath:humanReadable options:NSKeyValueObservingOptionNew context:NULL];
    [self.previewViewController setBarcodeToPreview:barcode];
    self.barcode = barcode;
    
    [self updateBarcode];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    NSString *identifier = segue.identifier;
    if ([identifier isEqualToString:@"MTIdentifierSegueBarcodePreview"]) {
        MTViewControllerBarcodePreview *pvc = segue.destinationViewController;
        pvc.delegate = self;
        [pvc setBarcodeToPreview:self.barcode];
        [pvc.view layoutIfNeeded];
        self.previewViewController = pvc;
    } else if ([identifier isEqualToString:@"MTIdentifierSegueBarcodeTable"]) {
        MTViewControllerBarcodeOptions *ovc = (MTViewControllerBarcodeOptions *)[(segue.destinationViewController) topViewController];
        ovc.delegate = self;
        ovc.document = self.document;
        self.optionsViewController = ovc;
    }
}

@end
