//
//  MTViewControllerBarcodeOptions.m
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTViewControllerBarcodeOptions.h"
#import "MADViewControllerBarcodeOptionsDelegate.h"

#import <CoreData/NSManagedObjectContext.h>

#import <UIKit/UINavigationController.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UIStepper.h>
#import <UIKit/UILabel.h>

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
#import <MADCocoaExtensions/NSError+Constructors.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>

#import <MAD/MADocument.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/MADQuery+Extras.h>
#import <MAD/MADDatabase+Constructor.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>

#import <MADCocoaExtensions/MADAlertController.h>

#import "MADQueryChooseFieldController.h"

#import "MTTableViewControllerBarcodeExtraAztec.h"
#import "MTTableViewControllerStaticSelectRow.h"
#import "MTTableViewControllerBarcodeExtraGridMatrix.h"
#import "MTTableViewControllerBarcodeExtraQrCode.h"
#import "MTTableViewControllerBarcodeExtraPdf417Iso24728.h"

static NSString * const SetDatasource = @"Set Datasource";
static NSString * const StringEmpty = @"";

static inline NSInteger tvsDefination();
static inline NSInteger tvsDefination() { return 0; }

static inline NSInteger tvsRendering(BOOL has2dComponent);
static inline NSInteger tvsRendering(BOOL has2dComponent) {
    return has2dComponent ? 2 : 1;
}
static inline NSInteger tvsBorder(BOOL has2dComponent);
static inline NSInteger tvsBorder(BOOL has2dComponent) {
    return has2dComponent ? 3 : 2;
}
static inline NSInteger tvs2dComponent(BOOL has2dComponent);
static inline NSInteger tvs2dComponent(BOOL has2dComponent) {
    return has2dComponent ? 1 : -1;
}

@interface MTViewControllerBarcodeOptions ()
    <MADDatabaseResultsProtocol,
        MTTableViewControllerStaticSelectRowDelegate>

    @property (nonatomic, assign) NSUInteger sampleBarcodeIndex;
    @property (nonatomic, assign) NSUInteger sampleBarcodeDataMaxicodeIndex;
    @property (nonatomic, assign) NSUInteger sampleBarcodeData2dComponentIndex;

    @property (nonatomic, strong) UIFont *mainFont;
    @property (nonatomic, strong) UIFont *detailFont;

    @property (nonatomic, assign) NSInteger borderWidth;

    @property (nonatomic, assign) BOOL selectingField1;
    @property (nonatomic, assign) BOOL selectingField2;

    @property (nonatomic, assign) BOOL selecting2dComponentType;

    @property (nonatomic, strong) MADDataTable *sampleDataTable;

@end

@implementation MTViewControllerBarcodeOptions

#pragma mark - Exit

- (IBAction)unwindToBarcodeOptions:(UIStoryboardSegue *)action { }

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToBarcodeOptions:);
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return action == @selector(unwindToBarcodeOptions:) ?
            self :
            [super viewControllerForUnwindSegueAction: action
                                   fromViewController: fromViewController
                                           withSender: sender];
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)customInit {
    self.borderWidth = 5;
    self.sampleBarcodeIndex = 0;
    
    NSDictionary *d = @{SetDatasource : SetDatasource};
    NSArray *sampleBarcodeData = @[d];
    self.sampleBarcodeData = sampleBarcodeData;
    
    NSDictionary *d2 = @{StringEmpty : StringEmpty};
    NSArray *sampleBarcodeDataMaxicode = @[d2];
    self.sampleBarcodeDataMaxicode = sampleBarcodeDataMaxicode;
    
    NSDictionary *d3 = @{StringEmpty : StringEmpty};
    NSArray *sampleBarcodeData2dComponent = @[d3];
    self.sampleBarcodeData2dComponent = sampleBarcodeData2dComponent;

    self.selectingField1 = NO;
    self.selectingField2 = NO;
    self.selecting2dComponentType = NO;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *barcodeType = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessage = NSStringFromSelector(@selector(showErrorMessage));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    MTBarcode *barcode = [self.delegate barcodeToDisplay];
    [self addObserver:barcode forKeyPath:barcodeType options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:barcode forKeyPath:showErrorMessage options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:barcode forKeyPath:humanReadable options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    self.selectingField1 = NO;
    self.selectingField2 = NO;
    self.selecting2dComponentType = NO;

    if ([segue.identifier isEqualToString:@"MTIdentifierSegueBarcodeField"]) {

        MADocument *document = self.document;
        [self setSelectingField1:YES];
        ((MADQueryChooseFieldController *)segue.destinationViewController).delegate = self;
        ((MADQueryChooseFieldController *)segue.destinationViewController).document = document;

    } else if ([segue.identifier isEqualToString:@"MTIdentifierSegueBarcodeField2"]) {
        
        MADocument *document = self.document;
        [self setSelectingField2:YES];
        ((MADQueryChooseFieldController *)segue.destinationViewController).delegate = self;
        ((MADQueryChooseFieldController *)segue.destinationViewController).document = document;
        
    } else if ([segue.identifier isEqualToString:@"MTIdentifierSegueBarcode2dComponentType"]) {
        
        // FIXME: Set inital component
        [self setSelecting2dComponentType:YES];
        ((MADQueryChooseFieldController *)segue.destinationViewController).delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"MTIdentifierSegueBarcodeType"]) {

        MTViewControllerBarcodeType *barcodeTypeViewController = segue.destinationViewController;
        MTBarcode *barcode = [self.delegate barcodeToDisplay];
        barcodeTypeViewController.initalKey = barcode.barcodeType;
        barcodeTypeViewController.delegate = self;

    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasAztec"]) {

        ((MTTableViewControllerBarcodeExtraAztec *)segue.destinationViewController).delegate = self;
    
    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasCodeOne"]) {
    
        ((MTTableViewControllerStaticSelectRow *)segue.destinationViewController).delegate = self;
    
    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasGridMatrix"]) {
    
        ((MTTableViewControllerBarcodeExtraGridMatrix *)segue.destinationViewController).delegate = self;

    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasQrCode"]) {
        
        ((MTTableViewControllerBarcodeExtraQrCode *)segue.destinationViewController).delegate = self;

    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasPdf417"]) {
        
        ((MTTableViewControllerBarcodeExtraPdf417Iso24728 *)segue.destinationViewController).delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasMsiPlessey"]) {
        
        ((MTTableViewControllerStaticSelectRow *)segue.destinationViewController).delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasMicroPdf417"]) {
        
        ((MTTableViewControllerStaticSelectRow *)segue.destinationViewController).delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasMicroQrCode"]) {
        
        ((MTTableViewControllerBarcodeExtraMicroQrCode *)segue.destinationViewController).delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasMaxicode"]) {
        MADocument *document = self.document;
        ((MTTableViewControllerBarcodeExtraMaxicode *)segue.destinationViewController).delegate = self;
        ((MTTableViewControllerBarcodeExtraMaxicode *)segue.destinationViewController).document = document;
        
    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasDataMatrix"]) {
        
        ((MTTableViewControllerBarcodeExtraDataMatrix *)segue.destinationViewController).delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasDataBarExpandedStacked"]) {
        
        ((MTTableViewControllerStaticSelectRow *)segue.destinationViewController).delegate = self;
        
    }

}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary <NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    NSInteger numberOfSections = 3;
    MTBarcode *barcode = [self.delegate barcodeToDisplay];

    //There's an optional section section for 2d component.
    if (barcode.has2dComponent) {
        numberOfSections++;
    }
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    MTBarcode *barcode = [self.delegate barcodeToDisplay];
    
    if (section == tvsDefination()) {
        
        NSInteger result = 2;
        if (barcode.hasOptionalInput) { result++; }
        return result;
        
    } else if (section == tvsRendering(barcode.has2dComponent)) {
        return 3;
    } else if (section == tvsBorder(barcode.has2dComponent)) {
        return 4;
    } else if (section == tvs2dComponent(barcode.has2dComponent)) {
        return 3;
    } else {
        return 0;
    }

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *MTIdentifierTvcBarcodeData                         = @"MTIdentifierTvcBarcodeData";
    static NSString *MTIdentifierTvcBarcodeType                         = @"MTIdentifierTvcBarcodeType";

    static NSString *MTIdentifierTvcBarcodeShowHumanReadableText        = @"MTIdentifierTvcBarcodeShowHumanReadableText";
    static NSString *MTIdentifierTvcBarcodeShowErrorMessages            = @"MTIdentifierTvcBarcodeShowErrorMessages";

    
    static NSString *MTIdentifierTvcBarcodeAppearanceBorder             = @"MTIdentifierTvcBarcodeAppearanceBorder";
    //static NSString *MTIdentifierTvcBarcodeAppearanceForegroundColor    = @"MTIdentifierTvcBarcodeAppearanceForegroundColor";
    //static NSString *MTIdentifierTvcBarcodeAppearanceBackgroundColor    = @"MTIdentifierTvcBarcodeAppearanceBackgroundColor";

    static NSString *MTIdentifierTvcBarcodeAppearanceBorderNone         = @"MTIdentifierTvcBarcodeAppearanceBorderNone";
    static NSString *MTIdentifierTvcBarcodeAppearanceBorderOption2      = @"MTIdentifierTvcBarcodeAppearanceBorderOption2";
    static NSString *MTIdentifierTvcBarcodeAppearanceBorderWidth        = @"MTIdentifierTvcBarcodeAppearanceBorderWidth";
    static NSString *MTIdentifierTvcBarcodeAppearanceSymbolHeight       = @"MTIdentifierTvcBarcodeAppearanceSymbolHeight";

    //static NSString *MTIdentifierTvcBarcodeHas2dComponent               = @"MTIdentifierTvcBarcodeHas2dComponent";
    static NSString *MTIdentifierTvcBarcodeHasOptionalInput             = @"MTIdentifierTvcBarcodeHasOptionalInput";
    
    static NSString *MTIdentifierTvcBarcode2dComponentEnabled           = @"MTIdentifierTvcBarcode2dComponentEnabled";
    static NSString *MTIdentifierTvcBarcode2dComponentType              = @"MTIdentifierTvcBarcode2dComponentType";
    static NSString *MTIdentifierTvcBarcode2dComponentDatasource        = @"MTIdentifierTvcBarcode2dComponentDatasource";
    
    //NSString *displayText = nil;
    UITableViewCell *cell = nil;
    id <MTViewControllerBarcodeOptionsDelegate> delegate;
    delegate = self.delegate;
    MTBarcode *barcode = [delegate barcodeToDisplay];
    NSInteger section = indexPath.section;
    if (section == tvsDefination()) {
        switch (indexPath.row) {
            case 0: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeData forIndexPath:indexPath];
                
                NSUInteger sampleBarcodeDataCount = self.sampleBarcodeData.count;
                
                NSAssert(sampleBarcodeDataCount >= 1, @"Sample data is missing");
                
                if (self.sampleBarcodeIndex >= sampleBarcodeDataCount) {
                    self.sampleBarcodeIndex = 0;
                }
                
                NSDictionary *sampleItem = self.sampleBarcodeData[self.sampleBarcodeIndex];
                NSString *sampleText = [NSString stringWithFormat:@"%@", sampleItem.allValues.lastObject];
                [delegate setInput:sampleText];
                
                NSString *fieldOneName = [[delegate barcodeQueryField1] toStringHumanReadable];
                cell.detailTextLabel.text = fieldOneName;
                
                break;
            }
            case 1: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeType forIndexPath:indexPath];
                NSString *barcodeName = [MTBarcode newBarcodeNameForType:barcode.barcodeType];
                cell.detailTextLabel.text = barcodeName;
                break;
            }
            case 2: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeHasOptionalInput forIndexPath:indexPath];
                if ([barcode isKindOfClass:[MTBarcodeCode39Iso16388 class]] ||
                    [barcode isKindOfClass:[MTBarcodeCode39Extended class]]) {
                    NSString *mod43CheckDigit = @"Mod-43 Check Digit";
                    cell.textLabel.text = mod43CheckDigit;
                    BOOL enabled = [(MTBarcodeCode39Iso16388 *)barcode mod43CheckDigitEnabled];
                    UITableViewCellAccessoryType accessory = enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    cell.accessoryType = accessory;
                } else {
                    if (barcode.hasOptionalInput) {
                        NSString *barcodeName = [MTBarcode newBarcodeNameForType:barcode.barcodeType];
                        NSString *textLabel = [NSString stringWithFormat:@"%@ detail", barcodeName];
                        cell.textLabel.text = textLabel;
                        UITableViewCellAccessoryType accessory = UITableViewCellAccessoryDisclosureIndicator;
                        cell.accessoryType = accessory;
                    }
                }
                break;
            }
            default:
                break;
        }
    } else if (section == tvsRendering(barcode.has2dComponent)) {
        switch (indexPath.row) {
            case 0: {
                BOOL humanReadable = barcode.humanReadable;
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeShowHumanReadableText forIndexPath:indexPath];
                UITableViewCellAccessoryType accessory = humanReadable ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                cell.accessoryType = accessory;
                break;
            }
            case 1: {
                BOOL showErrorMessage = barcode.showErrorMessage;
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeShowErrorMessages forIndexPath:indexPath];
                UITableViewCellAccessoryType accessory = showErrorMessage ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                cell.accessoryType = accessory;
                break;
            }
            case 2: {
                
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceSymbolHeight forIndexPath:indexPath];
                NSInteger symbolHeight = barcode.barcodeHeight;
                
                static NSInteger tagWithStepper = 48584;
                if (cell.tag != tagWithStepper) {
                    
                    UIStepper *stepper = [[UIStepper alloc] init];
                    [stepper setWraps:NO];
                    stepper.value = symbolHeight;
                    CGPoint newCenter = CGPointMake(CGRectGetMidY(cell.contentView.bounds),
                                                  CGPointZero.x + cell.contentView.bounds.size.width - (stepper.bounds.size.width / 2.0000f) - 20.0000f);
                    [stepper addTarget:self action:@selector(didChangeSymbolHeight:) forControlEvents:UIControlEventValueChanged];
                    [cell.contentView addSubview:stepper];
                    stepper.center = newCenter;
                    cell.tag = tagWithStepper;
                }
                NSString *detail = [NSString stringWithFormat:@"%ld", (long)symbolHeight];
                NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Symbol height" withDetail:detail];
                cell.textLabel.attributedText = attributedString;
            }
            default:
                break;
        }

    } else if (section == tvsBorder(barcode.has2dComponent)) {
        MTBarcodeBorderStyle borderStyle = barcode.barcodeBorderStyle;
        
        switch (indexPath.row) {
            case 0: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderNone forIndexPath:indexPath];
                UITableViewCellAccessoryType accessory = borderStyle == MTBarcodeBorderStyleNone ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                cell.accessoryType = accessory;
                if (accessory == UITableViewCellAccessoryCheckmark) {
                    NSIndexPath *row1 = [NSIndexPath indexPathForRow:1 inSection:indexPath.section];
                    NSIndexPath *row2 = [NSIndexPath indexPathForRow:2 inSection:indexPath.section];
                    [tableView cellForRowAtIndexPath:row1].accessoryType = UITableViewCellAccessoryNone;
                    [tableView cellForRowAtIndexPath:row2].accessoryType = UITableViewCellAccessoryNone;
                }
                break;
            }
            case 1: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorder forIndexPath:indexPath];
                UITableViewCellAccessoryType accessory = borderStyle == MTBarcodeBorderStyleBox ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                cell.accessoryType = accessory;
                if (accessory == UITableViewCellAccessoryCheckmark) {
                    NSIndexPath *row0 = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
                    NSIndexPath *row2 = [NSIndexPath indexPathForRow:2 inSection:indexPath.section];
                    [tableView cellForRowAtIndexPath:row0].accessoryType = UITableViewCellAccessoryNone;
                    [tableView cellForRowAtIndexPath:row2].accessoryType = UITableViewCellAccessoryNone;
                }
                break;
            }
            case 2: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderOption2 forIndexPath:indexPath];
                UITableViewCellAccessoryType accessory = borderStyle == MTBarcodeBorderStyleBind ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                cell.accessoryType = accessory;
                if (accessory == UITableViewCellAccessoryCheckmark) {
                    NSIndexPath *row0 = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
                    NSIndexPath *row1 = [NSIndexPath indexPathForRow:1 inSection:indexPath.section];
                    UITableViewCell *tvc0 = [tableView cellForRowAtIndexPath:row0];
                    tvc0.accessoryType = UITableViewCellAccessoryNone;
                    UITableViewCell *tvc1 = [tableView cellForRowAtIndexPath:row1];
                    tvc1.accessoryType = UITableViewCellAccessoryNone;
                }
                break;
            }
            case 3: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderWidth forIndexPath:indexPath];
                
                static NSInteger tagWithStepper = 34314;
                if (cell.tag != tagWithStepper) {
                    
                    UIStepper *stepper = [[UIStepper alloc] init];
                    stepper.wraps = NO;
                    stepper.value = self.borderWidth;
                    CGFloat centerY = CGRectGetMidY(cell.contentView.bounds);
                    CGFloat correctX = CGPointZero.x + cell.contentView.bounds.size.width - (stepper.bounds.size.width / 2.0000f) - 20.0000f;
                    [stepper addTarget:self action:@selector(didChangeBorderWidth:) forControlEvents:UIControlEventValueChanged];
                    [cell.contentView addSubview:stepper];
                    CGPoint newCenter = CGPointMake(correctX, centerY);
                    stepper.center = newCenter;
                    cell.tag = tagWithStepper;
                }
                NSString *detail = [NSString stringWithFormat:@"%ld", (long)self.borderWidth];
                NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Border width" withDetail:detail];
                cell.textLabel.attributedText = attributedString;
                
                break;
            }
            default:
                break;
        }
    } else if (section == tvs2dComponent(barcode.has2dComponent)) {
        switch (indexPath.row) {
            case 0: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcode2dComponentEnabled forIndexPath:indexPath];
                cell.accessoryType = barcode.has2dComponentEnabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                break;
            }
            case 1: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcode2dComponentType forIndexPath:indexPath];
                NSInteger type = barcode.has2dComponentType;
                NSString *detailText = [NSString stringWithFormat:@"%ld", (long)type];
                cell.detailTextLabel.text = detailText;
                
                cell.selectionStyle = barcode.has2dComponentEnabled ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
                UIColor *labelColor = barcode.has2dComponentEnabled ? [UIColor darkTextColor] : [UIColor lightGrayColor];
                cell.textLabel.textColor = labelColor;
                break;
            }
            case 2: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcode2dComponentDatasource forIndexPath:indexPath];
                NSDictionary *sampleItem = self.sampleBarcodeData2dComponent[self.sampleBarcodeData2dComponentIndex];
                NSString *sampleText = [NSString stringWithFormat:@"%@", sampleItem.allValues.lastObject];
                NSArray *sampleData = @[sampleText];
                [delegate barcode2dComponentsetSampleData:sampleData];

                NSString *fieldTwoName = [[delegate barcodeQueryField2] toStringHumanReadable];
                cell.detailTextLabel.text = fieldTwoName;
                break;
            }
            default:
                break;
        }
    }
    if (cell == nil) {
        cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeData forIndexPath:indexPath];
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

+ (NSAttributedString *)subject:(NSString *)subjectPart withDetail:(NSString *)detailPart {
    UIFont *boldFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIFont *systemFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    NSDictionary *boldAttributes = @{NSFontAttributeName : boldFont, NSForegroundColorAttributeName : [UIColor blackColor]};
    NSDictionary *normalAttributes = @{NSFontAttributeName : systemFont, NSForegroundColorAttributeName : [UIColor lightGrayColor]};
    
    NSMutableAttributedString *localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString:subjectPart
                                                                                                   attributes:boldAttributes];
    NSString *pointsString = [@" " stringByAppendingString:detailPart];
    
    NSAttributedString *messageSuffix = [[NSAttributedString alloc] initWithString:pointsString attributes:normalAttributes];
    [localizedAttributedMessage appendAttributedString:messageSuffix];
    return localizedAttributedMessage;
}


- (void)didChangeBorderWidth:(UIStepper *)sender {
    self.borderWidth = (NSInteger)sender.value;
    NSString *detail = [NSString stringWithFormat:@"%ld", (long)sender.value];
    NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Border width" withDetail:detail];
    NSIndexPath *path = [NSIndexPath indexPathForRow:3 inSection:2];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    cell.textLabel.attributedText = attributedString;
    
    [self.delegate setBorderWidth: (int16_t)floor(sender.value)];
}

- (void)didChangeSymbolHeight:(UIStepper *)sender {
    NSString *detail = [NSString stringWithFormat:@"%ld", (long)sender.value];
    NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Symbol height" withDetail:detail];
    NSIndexPath *path = [NSIndexPath indexPathForRow:2 inSection:1];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    cell.textLabel.attributedText = attributedString;
    [self.delegate didChangeSymbolHeight: (int16_t)floor(sender.value)];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id <MTViewControllerBarcodeOptionsDelegate> delegate;
    delegate = self.delegate;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    if (section == tvsDefination()) {
        switch (row) {
            case 2: {
                MTBarcode *barcode = [delegate barcodeToDisplay];
                if ([barcode isKindOfClass:[MTBarcodeCode39Iso16388 class]] ||
                    [barcode isKindOfClass:[MTBarcodeCode39Extended class]]) {

                    BOOL enabled = [(MTBarcodeCode39Iso16388 *)barcode mod43CheckDigitEnabled] == NO;
                    UITableViewCellAccessoryType accessory = enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    cell.accessoryType = accessory;
                    [(MTBarcodeCode39Iso16388 *)barcode setMod43CheckDigitEnabled:enabled];
                    

                } else {
                    if (barcode.hasOptionalInput) {
                        [self performSegueWithIdentifier:barcode.detailsSegueIdentifer sender:self];
                    }
                }
                
                break;
            }
            default:
                break;
        }
    } else {
        MTBarcode *barcode = [delegate barcodeToDisplay];
        if (section == tvsRendering(barcode.has2dComponent)) {
            switch (row) {
                    
                case 0: {
                    BOOL humanReadable = [delegate didToggleHumanReadable];
                    UITableViewCellAccessoryType accessory = humanReadable ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    cell.accessoryType = accessory;
                    break;
                }
                    
                case 1: {
                    BOOL showErrorMessage = [delegate didToggleShowErrorMessages];
                    UITableViewCellAccessoryType accessory = showErrorMessage ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    cell.accessoryType = accessory;
                    break;
                }
                    
                default:
                    break;
            }
            
        } else if (section == tvsBorder(barcode.has2dComponent)) {
            
            switch (row) {
                case 0: {
                    
                    [delegate setBorderType:MTBarcodeBorderStyleNone];
                    NSIndexPath *path1 = [NSIndexPath indexPathForRow:1 inSection:2];
                    UITableViewCell *cellBox = [tableView cellForRowAtIndexPath:path1];
                    cellBox.accessoryType = UITableViewCellAccessoryNone;
                    
                    NSIndexPath *path2 = [NSIndexPath indexPathForRow:2 inSection:2];
                    UITableViewCell *cellBind = [tableView cellForRowAtIndexPath:path2];
                    cellBind.accessoryType = UITableViewCellAccessoryNone;
                    
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    break;
                }
                case 1: {
                    
                    [delegate setBorderType:MTBarcodeBorderStyleBox];
                    NSIndexPath *path1 = [NSIndexPath indexPathForRow:0 inSection:2];
                    UITableViewCell *cellNone = [tableView cellForRowAtIndexPath:path1];
                    cellNone.accessoryType = UITableViewCellAccessoryNone;
                    
                    NSIndexPath *path2 = [NSIndexPath indexPathForRow:2 inSection:2];
                    UITableViewCell *cellBind = [tableView cellForRowAtIndexPath:path2];
                    cellBind.accessoryType = UITableViewCellAccessoryNone;
                    
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    
                    break;
                }
                    
                case 2: {
                    
                    [delegate setBorderType:MTBarcodeBorderStyleBind];
                    
                    NSIndexPath *path1 = [NSIndexPath indexPathForRow:0 inSection:2];
                    UITableViewCell *cellNone = [tableView cellForRowAtIndexPath:path1];
                    cellNone.accessoryType = UITableViewCellAccessoryNone;
                    
                    NSIndexPath *path2 = [NSIndexPath indexPathForRow:1 inSection:2];
                    UITableViewCell *cellBox = [tableView cellForRowAtIndexPath:path2];
                    cellBox.accessoryType = UITableViewCellAccessoryNone;
                    
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    
                    break;
                }
                    
                default:
                    break;
            }
            
        } else if (section == tvs2dComponent(barcode.has2dComponent)) {
            
            // FIXME: Not implemented
            
            switch (row) {
                case 0: {
                    BOOL wasEnabled = [delegate barcodeToDisplay].has2dComponentEnabled;
                    UITableViewCellAccessoryType accessory = wasEnabled ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
                    cell.accessoryType = accessory;
                    [delegate barcode2dComponentSetEnabled: !wasEnabled ];
                    break;
                }
                default:
                    break;
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    
    if (section == tvsDefination()) {
        title = @"Definition";
    } else {
        MTBarcode *barcode = [self.delegate barcodeToDisplay];
        if (section == tvsRendering(barcode.has2dComponent)) {
            title = @"Rendering";
        } else if (section == tvsBorder(barcode.has2dComponent)) {
            title = @"Border";
        } else if (section == tvs2dComponent(barcode.has2dComponent)) {
            title = @"2D Component";
        }
    }
    
    return title;
}

- (void)didChangeBarcodeType:(MTBarcodeType)barcodeType {
    [self.delegate didChangeBarcodeType:barcodeType];
}

#pragma mark - MTTableViewControllerStaticSelectRowDelegate

- (NSInteger)initalRow {
    NSInteger result;
    MTBarcode *barcode = [self.delegate barcodeToDisplay];
    if (self.selecting2dComponentType) {
        result = barcode.option1;
    } else {
        switch (barcode.barcodeType) {
                
            case MTBarcodeTypeCodeOne:
                result = [(MTBarcodeCodeOne *)barcode size];
                break;
                
            case MTBarcodeTypeMsiPlessey:
                result = [(MTBarcodeMsiPlessey *)barcode checkpointDigit];
                break;
                
            case MTBarcodeTypeRssExpstack:
                result = [(MTBarcodeDatabarExpandedStacked *)barcode numberOfDataColumns];
                break;
                
            case MTBarcodeTypeMicroPdf417:
                result = [(MTBarcodeMicroPdf417Iso24728 *)barcode numberOfDataColumns];
                break;
            case MTBarcodeTypeChannel:
                result = [(MTBarcodeChannelCode *)barcode numberOfChannels];
                break;
                
            default:
                result = 0;
                break;
        }
    }
    return result;
}

- (void)didSelectTag:(NSInteger)tag {
    id <MTViewControllerBarcodeOptionsDelegate> delegate;
    delegate = self.delegate;
    MTBarcode *barcode = [delegate barcodeToDisplay];
    if (self.selecting2dComponentType) {
        barcode.has2dComponentType = tag;
        [delegate updateBarcode];
    } else {
        switch (barcode.barcodeType) {
                
            case MTBarcodeTypeCodeOne:
                [(MTBarcodeCodeOne *)barcode setSize:tag];
                [delegate updateBarcode];
                break;
                
            case MTBarcodeTypeMsiPlessey:
                [(MTBarcodeMsiPlessey *)barcode setCheckDigit:tag];
                [delegate updateBarcode];
                break;
                
            case MTBarcodeTypeRssExpstack:
                [(MTBarcodeDatabarExpandedStacked *)barcode setNumberOfDataColumns:tag];
                [delegate updateBarcode];
                break;
                
            case MTBarcodeTypeMicroPdf417:
                [(MTBarcodeMicroPdf417Iso24728 *)barcode setNumberOfDataColumns:tag];
                [delegate updateBarcode];
                break;
                
            case MTBarcodeTypeChannel:
                [(MTBarcodeChannelCode *)barcode setNumberOfChannels:tag];
                [delegate updateBarcode];
                break;
                
            default:
                break;
        }    }
}

#pragma mark - MTTableViewControllerBarcodeExtraDataMatrixDelegate

- (NSInteger)barcodeDataMatrixInitalSize {
    MTBarcodeDataMatrixIso16022 *barcode = (MTBarcodeDataMatrixIso16022 *)[self.delegate barcodeToDisplay];
    return [barcode symbolSize];
}
- (void)barcodeDataMatrixDidSelectSize:(NSInteger)size {
    id <MTViewControllerBarcodeOptionsDelegate> delegate;
    delegate = self.delegate;
    MTBarcodeDataMatrixIso16022 *barcode = (MTBarcodeDataMatrixIso16022 *)[delegate barcodeToDisplay];
    [barcode setSymbolSize:size];
    [delegate updateBarcode];
}
- (void)barcodeDataMatrixDidSuppressRectangularSymbols:(BOOL)suppress {
    id <MTViewControllerBarcodeOptionsDelegate> delegate;
    delegate = self.delegate;
    MTBarcodeDataMatrixIso16022 *barcode = (MTBarcodeDataMatrixIso16022 *)[delegate barcodeToDisplay];
    [barcode suppressRectangularSymbolsInAutomaticMode:suppress];
    [delegate updateBarcode];
}

- (BOOL)barcodeDataMatrixSuppressRectangularSymbols {
    MTBarcodeDataMatrixIso16022 *barcode = (MTBarcodeDataMatrixIso16022 *)[self.delegate barcodeToDisplay];
    return [barcode suppressRectangularSymbols];
}

#pragma mark - MADQueryChooseFieldProtocol

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
                                    withFieldID: (NSManagedObjectID *)fieldID {
    
    NSManagedObjectContext *context = self.document.managedObjectContext;
    RptqQueryField *field = [context objectWithID: fieldID];

    [self.navigationController popViewControllerAnimated:YES];
    
    id <MTViewControllerBarcodeOptionsDelegate> delegate = self.delegate;
    if  (self.selectingField1) {
        [delegate didSetField1ID:fieldID];
    } else if (self.selectingField2) {
        [delegate didSetField2ID:fieldID];
    }
    
    MADQuery <MADQueryDatabaseProtocol> *querySampleDataField;
    querySampleDataField = (MADQuery <MADQueryDatabaseProtocol> *)[[MADQuery alloc] initWithQueryType: MADQueryTypeSampleDataField
                                                                                             object: field.databaseSchemaField];
    NSError * __autoreleasing error = NULL;
    
    MADDatabaseConnection *dbConnection;
    dbConnection = [MADDatabaseConnection newDatabaseConnection:((NSObject <MADConnectionsPropertiesProtocol> *)field.databaseSchemaField.inTable.inDatabase.ownedByUser)];
    MADDatabase *database = [MADDatabase newDatabaseWithConnection:dbConnection];
    if ([querySampleDataField conformsToProtocol:@protocol(MADDatabaseResultsProtocol)]) {
        database.delegate = ((NSObject <MADDatabaseResultsProtocol> *)querySampleDataField);
    }
    BOOL success = [database executeQuery:querySampleDataField withError:&error];

    if (success) {
        MADDataTable * __weak dt = [querySampleDataField.database.delegate dataTableForQuery:querySampleDataField];
        self.sampleDataTable = dt;
        NSAssert((self.selectingField1 == NO && self.selectingField2 == NO) == NO, @"Must be setting one or the other.");
        NSAssert((self.selectingField1 && self.selectingField2) == NO, @"Can't be setting both at the same time, now can we?");
        if (self.selectingField1) {
            NSArray *allObjects = [self.sampleDataTable allObjects];
            self.sampleBarcodeData = allObjects;
        } else if (self.selectingField2) {
            NSArray *allObjects = [self.sampleDataTable allObjects];
            self.sampleBarcodeData2dComponent = allObjects;
        }
        [self.tableView reloadData];
        
    } else {
        MTViewControllerBarcodeOptions * __weak weakself = self;
        
        __kindof MADDatabaseConnection *connection = database.databaseConnection;
        NSString *connectionString = connection.connectionString.copy;
        
        [NSError presentError: error
             onViewController: self
                   completion:^(BOOL presentErrorSuccess) {
                   
                       MTViewControllerBarcodeOptions *strongself;
                       UIAlertController *alertController;
                       
                       strongself = weakself;
                       
                       alertController = [MADAlertController removeCredentials:^(UIAlertAction *action) {
                           [MADKeyChain deleteKey:connectionString];
                       } cancel:nil];
                       
                       [strongself presentViewController:alertController animated:YES
                                              completion:nil];
                       
                       
                   }];
        
    }
}

#pragma mark - MADDatabaseResultsProtocol

- (MADDataTable *)dataTableForQuery:(MADQuery *)query {
    return self.sampleDataTable;
}

#pragma mark - MTTableViewControllerBarcodeExtraAztecDelegate

- (void)barcodeAztecDidEnableAutomaticResizing {
    [self.delegate barcodeAztecDidEnableAutomaticResizing];
}

- (void)barcodeAztecDidSetSize:(NSInteger)size {
    [self.delegate barcodeAztecDidSetSize:size];
}

- (void)barcodeAztecDidSetErrorCorrection:(NSInteger)errorCorrection {
    [self.delegate barcodeAztecDidSetErrorCorrection:errorCorrection];
}

- (BOOL)barcodeAztecAutomaticResizing {
    BOOL result = NO;
    MTBarcodeAztec *aztec = (MTBarcodeAztec *)[self.delegate barcodeToDisplay];
    MTBarcodeAztecSizingMode sizingMode = [aztec sizingMode];
    result = sizingMode == MTBarcodeAztecSizingModeAutomaticResizing;
    return result;
}

- (NSInteger)barcodeAztecInitalSize {
    MTBarcodeAztec *aztec = (MTBarcodeAztec *)[self.delegate barcodeToDisplay];
    NSInteger size = [aztec size];
    return size;
}

- (NSInteger)barcodeAztecInitalErrorCorrection {
    MTBarcodeAztec *aztec = (MTBarcodeAztec *)[self.delegate barcodeToDisplay];
    NSInteger errorCorrection = [aztec errorCorrection];
    return errorCorrection;
}

#pragma mark - MTTableViewControllerBarcodeExtraMaxiCodeDelegate

- (void)barcodeMaxicodeDidSetEncodingMode:(NSInteger)encodingMode {
    [self.delegate barcodeMaxicodeDidSetEncodingMode:encodingMode];
}
- (void)barcodeMaxicodeDidSetPrimaryData:(NSString *)primaryData {
    [self.delegate barcodeMaxicodeDidSetPrimaryData:primaryData];
}

- (NSInteger)initalEncodingMode {
    MTBarcodeMaxicodeIso16023 *barcode = (MTBarcodeMaxicodeIso16023 *)[self.delegate barcodeToDisplay];
    return [barcode encodingMode];
}
- (NSString *)initalPrimaryData {
    MTBarcodeMaxicodeIso16023 *barcode = (MTBarcodeMaxicodeIso16023 *)[self.delegate barcodeToDisplay];
    return barcode.primaryData;
}

- (void)barcodeMaxicodeDidChooseSampleData:(NSArray *)sampleData {
    self.sampleBarcodeDataMaxicode = sampleData;
    id <MTViewControllerBarcodeOptionsDelegate> delegate = self.delegate;
    if (sampleData.count > 0) {
        id result = [sampleData[0] allObjects].lastObject;
        [delegate barcodeMaxicodeDidSetPrimaryData:result];
    } else {
        [delegate barcodeMaxicodeDidSetPrimaryData:nil];
    }
}


#pragma mark - MTTableViewControllerBarcodeExtraGridMatrixDelegate

- (void)barcodeGridMatrixDidEnableAutomaticResizing {
    [self.delegate barcodeGridMatrixDidEnableAutomaticResizing];
}

- (void)barcodeGridMatrixDidSetSize:(NSInteger)size {
    [self.delegate barcodeGridMatrixDidSetSize:size];
}

- (void)barcodeGridMatrixDidSetErrorCorrection:(NSInteger)errorCorrection {
    [self.delegate barcodeGridMatrixDidSetErrorCorrection:errorCorrection];
}

- (BOOL)barcodeGridMatrixAutomaticResizing {
    BOOL result = NO;
    MTBarcodeGridMatrix *gridMatrix = (MTBarcodeGridMatrix *)[self.delegate barcodeToDisplay];
    MTBarcodeSizingMode sizingMode = [gridMatrix sizingMode];
    result = sizingMode == MTBarcodeSizingModeAutomaticResizing;
    return result;
}

- (NSInteger)barcodeGridMatrixInitalSize {
    MTBarcodeGridMatrix *gridMatrix = (MTBarcodeGridMatrix *)[self.delegate barcodeToDisplay];
    NSInteger size = [gridMatrix size];
    return size;
}

- (NSInteger)barcodeGridMatrixInitalErrorCorrection {
    MTBarcodeGridMatrix *gridMatrix = (MTBarcodeGridMatrix *)[self.delegate barcodeToDisplay];
    NSInteger errorCorrection = [gridMatrix errorCorrection];
    return errorCorrection;
}

#pragma mark - MTTableViewControllerBarcodeExtraMicroQrCodeDelegate

- (void)barcodeMicroQrCodeDidEnableAutomaticResizing {
    [self.delegate barcodeMicroQrCodeDidEnableAutomaticResizing];
}

- (void)barcodeMicroQrCodeDidSetSize:(NSInteger)size {
    [self.delegate barcodeMicroQrCodeDidSetSize:size];
}

- (void)barcodeMicroQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection {
    [self.delegate barcodeMicroQrCodeDidSetErrorCorrection:errorCorrection];
}

- (BOOL)barcodeMicroQrCodeAutomaticResizing {
    BOOL result = NO;
    MTBarcodeMicroQrCode *microQrCode = (MTBarcodeMicroQrCode *)[self.delegate barcodeToDisplay];
    MTBarcodeSizingMode sizingMode = [microQrCode sizingMode];
    result = sizingMode == MTBarcodeSizingModeAutomaticResizing;
    return result;
}

- (NSInteger)barcodeMicroQrCodeInitalSize {
    MTBarcodeMicroQrCode *microQrCode = (MTBarcodeMicroQrCode *)[self.delegate barcodeToDisplay];
    NSInteger size = [microQrCode size];
    return size;
}

- (NSInteger)barcodeMicroQrCodeInitalErrorCorrection {
    MTBarcodeMicroQrCode *microQrCode = (MTBarcodeMicroQrCode *)[self.delegate barcodeToDisplay];
    NSInteger errorCorrection = [microQrCode errorCorrection];
    return errorCorrection;
}

#pragma mark - MTTableViewControllerBarcodeExtraQrCodeDelegate

- (void)barcodeQrCodeDidEnableAutomaticResizing {
    [self.delegate barcodeQrCodeDidEnableAutomaticResizing];
}

- (void)barcodeQrCodeDidSetSize:(NSInteger)size {
    [self.delegate barcodeQrCodeDidSetSize:size];
}

- (void)barcodeQrCodeDidSetErrorCorrection:(NSInteger)errorCorrection {
    [self.delegate barcodeQrCodeDidSetErrorCorrection:errorCorrection];
}

- (BOOL)barcodeQrCodeAutomaticResizing {
    BOOL result = NO;
    MTBarcodeQrCodeIso18004 *qrCode = (MTBarcodeQrCodeIso18004 *)[self.delegate barcodeToDisplay];
    MTBarcodeSizingMode sizingMode = [qrCode sizingMode];
    result = sizingMode == MTBarcodeSizingModeAutomaticResizing;
    return result;
}

- (NSInteger)barcodeQrCodeInitalSize {
    MTBarcodeQrCodeIso18004 *qrCode = (MTBarcodeQrCodeIso18004 *)[self.delegate barcodeToDisplay];
    NSInteger size = [qrCode size];
    return size;
}

- (NSInteger)barcodeQrCodeInitalErrorCorrection {
    MTBarcodeQrCodeIso18004 *qrCode = (MTBarcodeQrCodeIso18004 *)[self.delegate barcodeToDisplay];
    NSInteger errorCorrection = [qrCode errorCorrection];
    return errorCorrection;
}

#pragma mark - MTTableViewControllerBarcodeExtraPdf417Iso24728Delegate

- (void)barcodePDF417DidSetColumns:(NSInteger)columns {
    [self.delegate barcodePDF417DidSetColumns:columns];
}

- (void)barcodePDF417DidSetFormat:(NSInteger)format {
    [self.delegate barcodePDF417DidSetFormat:format];
}

- (void)barcodePDF417DidSetErrorCorrection:(NSInteger)errorCorrection {
    [self.delegate barcodePDF417DidSetErrorCorrection:errorCorrection];
}

- (NSInteger)barcodePDF417Columns {
    MTBarcodePdf417Iso15438 *barcode = (MTBarcodePdf417Iso15438 *)[self.delegate barcodeToDisplay];
    return [barcode numberOfColumns];
}

- (NSInteger)barcodePDF417Format {
    MTBarcodePdf417Iso15438 *barcode = (MTBarcodePdf417Iso15438 *)[self.delegate barcodeToDisplay];
    return [barcode format];
}

- (NSInteger)barcodePDF417ErrorCorrection {
    MTBarcodePdf417Iso15438 *barcode = (MTBarcodePdf417Iso15438 *)[self.delegate barcodeToDisplay];
    return [barcode errorCorrectionCapacity];
}

@end
