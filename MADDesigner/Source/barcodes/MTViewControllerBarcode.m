//
//  MTViewControllerBarcode.m
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTViewControllerBarcode.h"
#import "MADViewControllerBarcodeDelegate.h"


#import <UIKit/UIStoryboard.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UIStoryboardSegue.h>

#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MADAlertController.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>

#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>
#import <MAD/RptqDocumentElementBarcode+Extras.h>
#import <MAD/MADDataTable+Constructor.h>
#import <MAD/MADQuery+Extras.h>
#import <MAD/MADDatabase+Constructor.h>

#import <MADBarcodes/MADBarcodeDataMatrixIso16022.h>
#import <MADBarcodes/MADBarcodeCode39Iso16388.h>
#import <MADBarcodes/MADBarcodeAztec.h>
#import <MADBarcodes/MADBarcodeQrCodeIso18004.h>
#import <MADBarcodes/MADBarcodeGridMatrix.h>
#import <MADBarcodes/MADBarcodeMicroQrCode.h>
#import <MADBarcodes/MADBarcodeMaxicodeIso16023.h>
#import <MADBarcodes/MADBarcodePdf417Iso15438.h>
#import <MADBarcodes/MADBarcodeCodeOne.h>
#import <MADBarcodes/MADBarcodeDatabarStacked.h>
#import <MADBarcodes/MADBarcodeDatabarExpandedStacked.h>
#import <MADBarcodes/MADBarcodeMsiPlessey.h>
#import <MADBarcodes/MADBarcodeMicroPdf417Iso24728.h>
#import <MADBarcodes/MADBarcodeChannelCode.h>
#import <MADBarcodes/MADBarcodeCode39Extended.h>

#import "MTViewControllerBarcodePreviewDelegate.h"

static NSString * const MTDocumentObjectNewBarcodeNavigationViewControllerIdentifier =
                                @"MTDocumentObjectNewBarcodeNavigationViewControllerIdentifier";

@interface MTViewControllerBarcode ()
    <MADDatabaseResultsProtocol, MTViewControllerBarcodePreviewDelegate>

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

    @property (nonatomic, strong) MADQuery *query;
    @property (nonatomic, strong) MADQuery *query2;

    @property (nonatomic, strong) MADDataTable *dataTableSampleData;
    @property (nonatomic, strong) MADDataTable *dataTableSampleData2;

@end

@implementation MTViewControllerBarcode

@synthesize unwindViewController;

+ (instancetype)newViewControllerBarcode {
    static NSString * const ObjectSelector = @"MADDesignerObjectSelector";
    static NSString * const MainIdentifier = @"MADIdentifierBarcodeViewController";
    id bundle = [NSBundle mainBundle];
    id storyboard = [UIStoryboard storyboardWithName: ObjectSelector bundle: bundle];
    id result = [storyboard instantiateViewControllerWithIdentifier: MainIdentifier];
    return result;
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController sender:(id)sender {
	return NO;
}

- (void)dealloc {
    NSString *barcodeTypeString = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessage = NSStringFromSelector(@selector(showErrorMessage));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    [self.optionsViewController removeObserver:self.barcode forKeyPath:barcodeTypeString];
    [self.optionsViewController removeObserver:self.barcode forKeyPath:showErrorMessage];
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
    NSString *vertConstraint;
    vertConstraint = @"V:|-(==0.0000)-[topView(==%@)]-(==0.0000)-[bottomView]-(==0.0000)-|";
    NSString *asciiArtVert = [NSString stringWithFormat: vertConstraint, barcodeViewerHeight];
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
        RptqStoreContext *moc = self.document.storeContext;
        if (self.queryField1ID != 0) {

            RptqQueryField *queryField1 = (RptqQueryField *)[moc objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:self.queryField1ID];
            MADQuery <MADQueryDatabaseProtocol> *querySampleDataField;
            RptqDatabaseSchemaField *databaseSchemaField1 = queryField1.databaseSchemaField;
            querySampleDataField = (MADQuery <MADQueryDatabaseProtocol> *)[[MADQuery alloc] initWithQueryType: MADQueryTypeSampleDataField
                                                                                                     object: databaseSchemaField1];
            querySampleDataField.database.delegate = self;
            self.query = querySampleDataField;
            
            MADDatabaseConnection *connection;
            connection = [MADDatabaseConnection newDatabaseConnection:((NSObject <MADConnectionsPropertiesProtocol> *)queryField1.databaseSchemaField.inTable.inDatabase.ownedByUser)];
            MADDatabase *db = [MADDatabase newDatabaseWithConnection:connection];
                db.delegate = self;
            NSError * __autoreleasing error = NULL;
            BOOL success = [db executeQuery:self.query withError:&error];

            if (success) {
                
                NSArray *allObjects = [self.dataTableSampleData allObjects];
                (self.optionsViewController).sampleBarcodeData = allObjects;
                [self.optionsViewController.tableView reloadData];
                
            } else {
                
                MTViewControllerBarcode * __weak weakself2 = self;
                
                [NSError presentError: error
                     onViewController: weakself2
                           completion: ^(BOOL __unused presentErrorSuccess) {
                               
                               UIAlertController *alertController;
                               NSString *key;
                               
                               key = [NSString stringWithString:querySampleDataField.database.databaseConnection.connectionString];
                               
                               alertController = [MADAlertController removeCredentials:^(UIAlertAction *__unused action) {
                                   [MADKeyChain deleteKey:key];
                               } cancel:nil];
                               
                               [weakself2 presentViewController: alertController
                                                       animated: YES
                                                     completion: nil];
                               
                           }];
                
            }
        }
        
        if (self.queryField2ID != 0) {
            
            RptqQueryField *queryField2;
            MADQuery <MADQueryDatabaseProtocol> *querySampleDataField;
            queryField2 = (RptqQueryField *)[moc objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:self.queryField2ID];
            querySampleDataField = (MADQuery <MADQueryDatabaseProtocol> *)[[MADQuery alloc] initWithQueryType: MADQueryTypeSampleDataField
                                                                                                     object: queryField2.databaseSchemaField];
            querySampleDataField.database.delegate = self;
            self.query2 = querySampleDataField;
            NSError * __autoreleasing error = NULL;

            MADDatabaseConnection *connection;
            connection = [MADDatabaseConnection newDatabaseConnection:((NSObject <MADConnectionsPropertiesProtocol> *)queryField2.databaseSchemaField.inTable.inDatabase.ownedByUser)];
            MADDatabase *db = [MADDatabase newDatabaseWithConnection:connection];
            if ([self.query2 conformsToProtocol:@protocol(MADDatabaseResultsProtocol)]) {
                db.delegate = self;
            }
            BOOL success = [db executeQuery:querySampleDataField withError:&error];

            
            
            if (success) {
                NSArray *allObjects = [self.dataTableSampleData2 allObjects];
                (self.optionsViewController).sampleBarcodeData2dComponent = allObjects;
                [self.optionsViewController.tableView reloadData];
            } else {
                MTViewControllerBarcode * __weak weakself = self;
                
                [NSError presentError: error
                     onViewController: weakself
                           completion:^(BOOL __unused presentErrorSuccess) {
                               MTViewControllerBarcode *strongself2 = weakself;

                               NSString *key = [NSString stringWithString:querySampleDataField.database.databaseConnection.connectionString];
                               UIAlertController *alertController = [MADAlertController removeCredentials:^(UIAlertAction *__unused action) {
                                   [MADKeyChain deleteKey:key];
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

- (MADDataTable *)dataTableForQuery:(MADQuery *)query {

    if ([query isEqual:self.query]) {
        return self.dataTableSampleData;

    } else if ([query isEqual:self.query2]) {
        return self.dataTableSampleData2;

    } else {
        NSAssert(NO, @"Unknown query at %s.", __PRETTY_FUNCTION__);
        return nil;
    }
}

+ (MADDataTable *)newDataTableForMangedObject:(int64_t)objectID {
    return [MADDataTable newDataTableForIdentifier:[[NSString alloc] initWithFormat:@"%lld", objectID]];
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

    MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypeAztec];
    barcode.showErrorMessage = YES;
    self.barcode = barcode;
}

- (void)updateBarcode {

    self.barcode.input = self.barcodeInput;
    [self.previewViewController update];
    
    [self.delegate didUpdateBarcodeWithObjectID: self.bartcodeToEditObjectID
                                  barcodeObject: self.barcode
                                   withFieldOne: self.queryField1ID
                                    andFieldTwo: self.queryField2ID];
}

- (void)didSetField1ID:(int64_t)fieldID {
    if (fieldID != 0) {
        [self.barButtonItemSave setEnabled:YES];
    }
    self.queryField1ID = fieldID;
}

- (void)didSetField2ID:(int64_t)fieldID {
    self.queryField2ID = fieldID;
}

- (RptqQueryField *)queryFieldForIdentifier:(int64_t)identifier {
    if (identifier == 0) {
        return nil;
    }
    RptqStoreContext *context = self.document.storeContext;
    return (RptqQueryField *)[context objectForEntity:NSStringFromClass([RptqQueryField class])
                                           identifier:identifier];
}

- (RptqQueryField *)barcodeQueryField1 {
    return [self queryFieldForIdentifier:self.queryField1ID];
}

- (RptqQueryField *)barcodeQueryField2 {
    return [self queryFieldForIdentifier:self.queryField2ID];
}

- (void)setBarcodeToEdit:(RptqDocumentElementBarcode *)barcodeDocumentObject {

    MADBarcode *barcode;
    barcode = [MADBarcode newBarcode:barcodeDocumentObject];
    self.barcode = barcode;
    
    self.queryField1ID = barcodeDocumentObject.referencesField1.identifier;
    self.queryField2ID = barcodeDocumentObject.referencesField2.identifier;
    
    self.editmode = YES;

}

- (void)setBarcodeObjectIDToEdit:(int64_t)objectID {
    
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

- (MADBarcode *)barcodeToDisplay {
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
    BOOL showErrorMessage = !(self.barcode).showErrorMessage;
    (self.barcode).showErrorMessage = showErrorMessage;
    [self updateBarcode];
    return showErrorMessage;
}

- (void)didChangeSymbolHeight:(int16_t)symbolHeight {
    self.barcode.barcodeHeight = symbolHeight;
    [self updateBarcode];
}

- (void)setBorderWidth:(int16_t)borderWidth {
    self.barcode.barcodeBorderWidth = borderWidth;
    [self updateBarcode];
}

- (void)setBorderType:(MADBarcodeBorderStyle)borderStyle {
    (self.barcode).barcodeBorderStyle = borderStyle;
    [self updateBarcode];
}

- (void)setInput:(NSString *)barcodeInput {
    self.barcodeInput = barcodeInput.copy;
    [self updateBarcode];
}

#pragma mark Aztec

- (void)barcodeAztecDidEnableAutomaticResizing {
    MADBarcodeAztec *barcode = (MADBarcodeAztec *)self.barcode;
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeAztecDidSetSize:(NSUInteger)size {
    MADBarcodeAztec *barcode = (MADBarcodeAztec *)self.barcode;
    barcode.size = size;
    [self updateBarcode];
}

- (void)barcodeAztecDidSetErrorCorrection:(NSUInteger)errorCorrection {
    MADBarcodeAztec *barcode = (MADBarcodeAztec *)self.barcode;
    [barcode setMinmumErrorCorrection:errorCorrection];
    [self updateBarcode];
}

#pragma mark Qr Code

- (void)barcodeQrCodeDidEnableAutomaticResizing {
    MADBarcodeQrCodeIso18004 *barcode = (MADBarcodeQrCodeIso18004 *)self.barcode;
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeQrCodeDidSetSize:(NSInteger)size {
    MADBarcodeQrCodeIso18004 *barcode = (MADBarcodeQrCodeIso18004 *)self.barcode;
    [barcode setSize:size];
    [self updateBarcode];
}

- (void)barcodeQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection {
    MADBarcodeQrCodeIso18004 *barcode = (MADBarcodeQrCodeIso18004 *)self.barcode;
    [barcode setErrorCorrection:errorCorrection];
    [self updateBarcode];
}

#pragma mark Maxicode

- (void)barcodeMaxicodeDidSetEncodingMode:(NSInteger)encodingMode {
    MADBarcodeMaxicodeIso16023 *barcode = (MADBarcodeMaxicodeIso16023 *)self.barcode;
    [barcode setEncodingMode:encodingMode];
    [self updateBarcode];
}
- (void)barcodeMaxicodeDidSetPrimaryData:(NSString *)primaryData {
    MADBarcodeMaxicodeIso16023 *barcode = (MADBarcodeMaxicodeIso16023 *)self.barcode;
    [barcode setPrimaryDataString:primaryData];
    [self updateBarcode];
}

#pragma mark Micro Qr Code

- (void)barcodeMicroQrCodeDidEnableAutomaticResizing {
    MADBarcodeMicroQrCode *barcode = (MADBarcodeMicroQrCode *)self.barcode;
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeMicroQrCodeDidSetSize:(NSInteger)size {
    MADBarcodeMicroQrCode *barcode = (MADBarcodeMicroQrCode *)self.barcode;
    [barcode setSize:size];
    [self updateBarcode];
}

- (void)barcodeMicroQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection {
    MADBarcodeMicroQrCode *barcode = (MADBarcodeMicroQrCode *)self.barcode;
    [barcode setMinmumErrorCorrection:errorCorrection];
    [self updateBarcode];
}

#pragma mark GridMatrix

- (void)barcodeGridMatrixDidEnableAutomaticResizing {
    MADBarcodeGridMatrix *barcode = (MADBarcodeGridMatrix *)self.barcode;
    [barcode enableAutomaticResizing];
    [self updateBarcode];
}

- (void)barcodeGridMatrixDidSetSize:(NSInteger)size {
    MADBarcodeGridMatrix *barcode = (MADBarcodeGridMatrix *)self.barcode;
    [barcode setSize:size];
    [self updateBarcode];
}

- (void)barcodeGridMatrixDidSetErrorCorrection:(NSInteger)errorCorrection {
    MADBarcodeGridMatrix *barcode = (MADBarcodeGridMatrix *)self.barcode;
    [barcode setMinmumErrorCorrection:errorCorrection];
    [self updateBarcode];
}

#pragma mark PDF 417

- (void)barcodePDF417DidSetColumns:(NSInteger)columns {
    ((MADBarcodePdf417Iso15438 *)self.barcode).width = columns;
    [self updateBarcode];
}

- (void)barcodePDF417DidSetFormat:(NSInteger)format {
    ((MADBarcodePdf417Iso15438 *)self.barcode).format = format;
    [self updateBarcode];
}

- (void)barcodePDF417DidSetErrorCorrection:(NSInteger)errorCorrection {
    ((MADBarcodePdf417Iso15438 *)self.barcode).errorCorrectionCapacity = errorCorrection;
    [self updateBarcode];
}

#pragma mark - MTViewControllerBarcodePreviewDelegate
- (void)didChangeBarcodeType:(MADBarcodeType)barcodeType {
    MADBarcode *barcode = [MADBarcode newBarcodeWithType:barcodeType];
    
    NSString *barcodeTypeString = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessage = NSStringFromSelector(@selector(showErrorMessage));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    [self.optionsViewController removeObserver:self.barcode forKeyPath:barcodeTypeString];
    [self.optionsViewController removeObserver:self.barcode forKeyPath:showErrorMessage];
    [self.optionsViewController removeObserver:self.barcode forKeyPath:humanReadable];
    [self.optionsViewController addObserver:barcode forKeyPath:barcodeTypeString options:NSKeyValueObservingOptionNew context:NULL];
    [self.optionsViewController addObserver:barcode forKeyPath:showErrorMessage options:NSKeyValueObservingOptionNew context:NULL];
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
