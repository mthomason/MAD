//
//  MTViewControllerBarcodeOptions.m
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTViewControllerBarcodeOptions.h"
#import "MTQueryBuilderChooseFieldViewController.h"

#import "MTTableViewControllerBarcodeExtraAztec.h"
#import "MTTableViewControllerStaticSelectRow.h"
#import "MTTableViewControllerBarcodeExtraGridMatrix.h"
#import "MTTableViewControllerBarcodeExtraQrCode.h"
#import "MTTableViewControllerBarcodeExtraPdf417Iso24728.h"


@interface MTViewControllerBarcodeOptions ()
    <MTDatabaseProtocol, MTTableViewControllerStaticSelectRowDelegate>

@property (nonatomic, assign) NSUInteger sampleBarcodeIndex;
@property (nonatomic, assign) NSUInteger sampleBarcodeDataMaxicodeIndex;
@property (nonatomic, assign) NSUInteger sampleBarcodeData2dComponentIndex;

@property (nonatomic, strong) UIFont *mainFont;
@property (nonatomic, strong) UIFont *detailFont;

@property (nonatomic, assign) NSInteger borderWidth;

@property (nonatomic, assign) BOOL selectingField1;
@property (nonatomic, assign) BOOL selectingField2;

@property (nonatomic, assign) BOOL selecting2dComponentType;

@property (nonatomic, strong) MTDataTable *sampleDataTable;

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
    [self setSampleBarcodeIndex: 0];
    NSArray *sampleBarcodeData = @[@{@"Set Datasource" : @"Set Datasource"}];
    NSArray *sampleBarcodeDataMaxicode = @[@{@"" : @""}];
    NSArray *sampleBarcodeData2dComponent = @[@{@"" : @""}];
    [self setSampleBarcodeData:sampleBarcodeData];
    [self setSampleBarcodeDataMaxicode:sampleBarcodeDataMaxicode];
    [self setSampleBarcodeData2dComponent:sampleBarcodeData2dComponent];
    [self setSelectingField1:NO];
    [self setSelectingField2:NO];
    [self setSelecting2dComponentType:NO];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *barcodeType = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessages = NSStringFromSelector(@selector(showErrorMessages));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    MTBarcode *barcode = [self.delegate barcodeToDisplay];
    [self addObserver:barcode forKeyPath:barcodeType options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:barcode forKeyPath:showErrorMessages options:NSKeyValueObservingOptionNew context:NULL];
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

    [self setSelectingField1:NO];
    [self setSelectingField2:NO];
    [self setSelecting2dComponentType:NO];

    if ([segue.identifier isEqualToString:@"MTIdentifierSegueBarcodeField"]) {

        [self setSelectingField1:YES];
        [(MTQueryBuilderChooseFieldViewController *)segue.destinationViewController setDelegate:self];
        [(MTQueryBuilderChooseFieldViewController *)segue.destinationViewController setDocument:self.document];

    } else if ([segue.identifier isEqualToString:@"MTIdentifierSegueBarcodeField2"]) {
        
        [self setSelectingField2:YES];
        [(MTQueryBuilderChooseFieldViewController *)segue.destinationViewController setDelegate:self];
        [(MTQueryBuilderChooseFieldViewController *)segue.destinationViewController setDocument:self.document];
        
    } else if ([segue.identifier isEqualToString:@"MTIdentifierSegueBarcode2dComponentType"]) {
        
        // FIXME: Set inital component
        [self setSelecting2dComponentType:YES];
        [(MTQueryBuilderChooseFieldViewController *)segue.destinationViewController setDelegate:self];
        
    } else if ([segue.identifier isEqualToString:@"MTIdentifierSegueBarcodeType"]) {

        MTViewControllerBarcodeType *barcodeTypeViewController = segue.destinationViewController;
        MTBarcode *barcode = [self.delegate barcodeToDisplay];
        [barcodeTypeViewController setInitalKey:[barcode barcodeType]];
        [barcodeTypeViewController setDelegate:self];

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
        
        ((MTTableViewControllerBarcodeExtraMaxicode *)segue.destinationViewController).delegate = self;
        ((MTTableViewControllerBarcodeExtraMaxicode *)segue.destinationViewController).document = self.document;
        
    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasDataMatrix"]) {
        
        ((MTTableViewControllerBarcodeExtraDataMatrix *)segue.destinationViewController).delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"MTIdentiferSegueBarcodeExtrasDataBarExpandedStacked"]) {
        
        ((MTTableViewControllerStaticSelectRow *)segue.destinationViewController).delegate = self;
        
    }

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    NSInteger numberOfSections = 3;
    MTBarcode *barcode = [self.delegate barcodeToDisplay];

    //There's an optional section section for 2d component.
    if ([barcode has2dComponent]) {
        numberOfSections++;
    }
    return numberOfSections;
}

- (NSInteger)tableViewSectionDefination {
    return 0;
}
- (NSInteger)tableViewSectionRendering {
    MTBarcode *barcode = [self.delegate barcodeToDisplay];
    return [barcode has2dComponent] ? 2 : 1;
}
- (NSInteger)tableViewSectionBorder {
    MTBarcode *barcode = [self.delegate barcodeToDisplay];
    return [barcode has2dComponent] ? 3 : 2;
}
- (NSInteger)tableViewSection2dComponent {
    MTBarcode *barcode = [self.delegate barcodeToDisplay];
    return [barcode has2dComponent] ? 1 : -1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger result = 0;

    if (section == [self tableViewSectionDefination]) {
        result = 2;
        MTBarcode *barcode = [self.delegate barcodeToDisplay];
        if ([barcode hasOptionalInput]) {
            result++;
        }
    } else if (section == [self tableViewSectionRendering]) {
        result = 3;
    } else if (section == [self tableViewSectionBorder]) {
        result = 4;
    } else if (section == [self tableViewSection2dComponent]) {
        result = 3;
    }
    return result;
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
    MTBarcode *barcode = [self.delegate barcodeToDisplay];
    NSInteger section = indexPath.section;
    if (section == [self tableViewSectionDefination]) {
        switch (indexPath.row) {
            case 0: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeData forIndexPath:indexPath];
                
                NSInteger sampleBarcodeDataCount = [[self sampleBarcodeData] count];
                
                NSAssert(sampleBarcodeDataCount >= 1, @"Sample data is missing");
                
                if ([self sampleBarcodeIndex] >= sampleBarcodeDataCount) {
                    [self setSampleBarcodeIndex:0];
                }
                
                NSDictionary *sampleItem = [self sampleBarcodeData][[self sampleBarcodeIndex]];
                NSString *sampleText = [NSString stringWithFormat:@"%@", [[sampleItem allValues] lastObject]];
                [self.delegate setInput:sampleText];
                
                NSString *fieldOneName = [[self.delegate barcodeQueryField1] toStringHumanReadable];
                [[cell detailTextLabel] setText:fieldOneName];
                
                break;
            }
            case 1: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeType forIndexPath:indexPath];
                NSString *barcodeName = [MTBarcode barcodeNameForType:[barcode barcodeType]];
                [[cell detailTextLabel] setText:barcodeName];
                break;
            }
            case 2: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeHasOptionalInput forIndexPath:indexPath];
                if ([barcode isKindOfClass:[MTBarcodeCode39Iso16388 class]] ||
                    [barcode isKindOfClass:[MTBarcodeCode39Extended class]]) {
                    NSString *mod43CheckDigit = @"Mod-43 Check Digit";
                    [[cell textLabel] setText:mod43CheckDigit];
                    BOOL enabled = [(MTBarcodeCode39Iso16388 *)barcode mod43CheckDigitEnabled];
                    UITableViewCellAccessoryType accessory = enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                } else {
                    if ([barcode hasOptionalInput]) {
                        NSString *barcodeName = [MTBarcode barcodeNameForType:[barcode barcodeType]];
                        NSString *textLabel = [NSString stringWithFormat:@"%@ detail", barcodeName];
                        [[cell textLabel] setText:textLabel];
                        UITableViewCellAccessoryType accessory = UITableViewCellAccessoryDisclosureIndicator;
                        [cell setAccessoryType:accessory];
                    }
                }
                break;
            }
            default:
                break;
        }
    } else if (section == [self tableViewSectionRendering]) {
        switch (indexPath.row) {
            case 0: {
                BOOL humanReadable = [barcode humanReadable];
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeShowHumanReadableText forIndexPath:indexPath];
                UITableViewCellAccessoryType accessory = humanReadable ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                [cell setAccessoryType:accessory];
                break;
            }
            case 1: {
                BOOL showErrorMessages = [barcode showErrorMessages];
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeShowErrorMessages forIndexPath:indexPath];
                UITableViewCellAccessoryType accessory = showErrorMessages ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                [cell setAccessoryType:accessory];
                break;
            }
            case 2: {
                
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceSymbolHeight forIndexPath:indexPath];
                NSInteger symbolHeight = [barcode height];
                
                static NSInteger tagWithStepper = 48584;
                if ([cell tag] != tagWithStepper) {
                    
                    UIStepper *stepper = [[UIStepper alloc] init];
                    [stepper setWraps:NO];
                    [stepper setValue:symbolHeight];
                    CGFloat centerY = CGRectGetMidY([[cell contentView] bounds]);
                    CGFloat correctX = CGPointZero.x + [[cell contentView] bounds].size.width - ([stepper bounds].size.width / 2.0000f) - 20.0000f;
                    [stepper addTarget:self action:@selector(didChangeSymbolHeight:) forControlEvents:UIControlEventValueChanged];
                    [[cell contentView] addSubview:stepper];
                    CGPoint newCenter = CGPointMake(correctX, centerY);
                    [stepper setCenter:newCenter];
                    [cell setTag: tagWithStepper];
                }
                NSString *detail = [NSString stringWithFormat:@"%ld", (long)symbolHeight];
                NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Symbol height" withDetail:detail];
                [[cell textLabel] setAttributedText:attributedString];
            }
            default:
                break;
        }

    } else if (section == [self tableViewSectionBorder]) {
        MTBarcodeBorderStyle borderStyle = [barcode borderStyle];
        
        switch (indexPath.row) {
            case 0: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderNone forIndexPath:indexPath];
                UITableViewCellAccessoryType accessory = borderStyle == MTBarcodeBorderStyleNone ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                [cell setAccessoryType:accessory];
                if (accessory == UITableViewCellAccessoryCheckmark) {
                    NSIndexPath *row1 = [NSIndexPath indexPathForRow:1 inSection:indexPath.section];
                    NSIndexPath *row2 = [NSIndexPath indexPathForRow:2 inSection:indexPath.section];
                    [[tableView cellForRowAtIndexPath:row1] setAccessoryType:UITableViewCellAccessoryNone];
                    [[tableView cellForRowAtIndexPath:row2] setAccessoryType:UITableViewCellAccessoryNone];
                }
                break;
            }
            case 1: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorder forIndexPath:indexPath];
                UITableViewCellAccessoryType accessory = borderStyle == MTBarcodeBorderStyleBox ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                [cell setAccessoryType:accessory];
                if (accessory == UITableViewCellAccessoryCheckmark) {
                    NSIndexPath *row0 = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
                    NSIndexPath *row2 = [NSIndexPath indexPathForRow:2 inSection:indexPath.section];
                    [[tableView cellForRowAtIndexPath:row0] setAccessoryType:UITableViewCellAccessoryNone];
                    [[tableView cellForRowAtIndexPath:row2] setAccessoryType:UITableViewCellAccessoryNone];
                }
                break;
            }
            case 2: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderOption2 forIndexPath:indexPath];
                UITableViewCellAccessoryType accessory = borderStyle == MTBarcodeBorderStyleBind ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                [cell setAccessoryType:accessory];
                if (accessory == UITableViewCellAccessoryCheckmark) {
                    NSIndexPath *row0 = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
                    NSIndexPath *row1 = [NSIndexPath indexPathForRow:1 inSection:indexPath.section];
                    [[tableView cellForRowAtIndexPath:row0] setAccessoryType:UITableViewCellAccessoryNone];
                    [[tableView cellForRowAtIndexPath:row1] setAccessoryType:UITableViewCellAccessoryNone];
                }
                break;
            }
            case 3: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderWidth forIndexPath:indexPath];
                
                static NSInteger tagWithStepper = 34314;
                if ([cell tag] != tagWithStepper) {
                    
                    UIStepper *stepper = [[UIStepper alloc] init];
                    [stepper setWraps:NO];
                    [stepper setValue:[self borderWidth]];
                    CGFloat centerY = CGRectGetMidY([[cell contentView] bounds]);
                    CGFloat correctX = CGPointZero.x + [[cell contentView] bounds].size.width - ([stepper bounds].size.width / 2.0000f) - 20.0000f;
                    [stepper addTarget:self action:@selector(didChangeBorderWidth:) forControlEvents:UIControlEventValueChanged];
                    [[cell contentView] addSubview:stepper];
                    CGPoint newCenter = CGPointMake(correctX, centerY);
                    [stepper setCenter:newCenter];
                    
                    [cell setTag: tagWithStepper];
                }
                NSString *detail = [NSString stringWithFormat:@"%ld", (long)[self borderWidth]];
                NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Border width" withDetail:detail];
                [[cell textLabel] setAttributedText:attributedString];
                
                break;
            }
            default:
                break;
        }
    } else if (section == [self tableViewSection2dComponent]) {
        switch (indexPath.row) {
            case 0: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcode2dComponentEnabled forIndexPath:indexPath];
                UITableViewCellAccessoryType accessory = [barcode has2dComponentEnabled] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                [cell setAccessoryType:accessory];
                break;
            }
            case 1: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcode2dComponentType forIndexPath:indexPath];
                NSInteger type = [barcode has2dComponentType];
                NSString *detailText = [NSString stringWithFormat:@"%ld", (long)type];
                [[cell detailTextLabel] setText:detailText];
                BOOL enabled = [barcode has2dComponentEnabled];
                UITableViewCellSelectionStyle style = enabled ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
                [cell setSelectionStyle:style];
                UIColor *labelColor = enabled ? [UIColor darkTextColor] : [UIColor lightGrayColor];
                [[cell textLabel] setTextColor:labelColor];
                break;
            }
            case 2: {
                cell = [tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcode2dComponentDatasource forIndexPath:indexPath];
                NSDictionary *sampleItem = [self sampleBarcodeData2dComponent][[self sampleBarcodeData2dComponentIndex]];
                NSString *sampleText = [NSString stringWithFormat:@"%@", [[sampleItem allValues] lastObject]];
                [self.delegate barcode2dComponentsetSampleData:@[sampleText]];

                NSString *fieldTwoName = [[self.delegate barcodeQueryField2] toStringHumanReadable];
                [[cell detailTextLabel] setText:fieldTwoName];
                break;
            }
            default:
                break;
        }
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
    self.borderWidth = (NSInteger) [sender value];
    NSString *detail = [NSString stringWithFormat:@"%ld", (long)[sender value]];
    NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Border width" withDetail:detail];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:2]];
    [[cell textLabel] setAttributedText:attributedString];
    [self.delegate setBorderWidth: [sender value]];
}

- (void)didChangeSymbolHeight:(UIStepper *)sender {
    NSString *detail = [NSString stringWithFormat:@"%ld", (long)[sender value]];
    NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Symbol height" withDetail:detail];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
    [[cell textLabel] setAttributedText:attributedString];
    [self.delegate didChangeSymbolHeight:[sender value]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    if (section == [self tableViewSectionDefination]) {
        switch (row) {
            case 2: {
                MTBarcode *barcode = [self.delegate barcodeToDisplay];
                if ([barcode isKindOfClass:[MTBarcodeCode39Iso16388 class]] ||
                    [barcode isKindOfClass:[MTBarcodeCode39Extended class]]) {

                    BOOL enabled = [(MTBarcodeCode39Iso16388 *)barcode mod43CheckDigitEnabled] == NO;
                    UITableViewCellAccessoryType accessory = enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                    [(MTBarcodeCode39Iso16388 *)barcode setMod43CheckDigitEnabled:enabled];
                    

                } else {
                    if ([barcode hasOptionalInput]) {
                        [self performSegueWithIdentifier:[barcode detailsSegueIdentifer] sender:self];
                    }
                }
                
                break;
            }
            default:
                break;
        }
    } else if (section == [self tableViewSectionRendering]) {
        switch (row) {
                
            case 0: {
                BOOL humanReadable = [self.delegate didToggleHumanReadable];
                UITableViewCellAccessoryType accessory = humanReadable ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                [cell setAccessoryType:accessory];
                break;
            }
                
            case 1: {
                BOOL showErrorMessages = [self.delegate didToggleShowErrorMessages];
                UITableViewCellAccessoryType accessory = showErrorMessages ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                [cell setAccessoryType:accessory];
                break;
            }
                
            default:
                break;
        }

    } else if (section == [self tableViewSectionBorder]) {
        
        switch (row) {
            case 0: {
                
                [self.delegate setBorderType:MTBarcodeBorderStyleNone];
                UITableViewCell *cellBox = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
                UITableViewCell *cellBind = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2]];
                [cell setAccessoryType: UITableViewCellAccessoryCheckmark];
                [cellBox setAccessoryType:UITableViewCellAccessoryNone];
                [cellBind setAccessoryType:UITableViewCellAccessoryNone];
                break;
            }
            case 1: {
                
                [self.delegate setBorderType:MTBarcodeBorderStyleBox];
                UITableViewCell *cellNone = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
                UITableViewCell *cellBind = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2]];
                [cell setAccessoryType: UITableViewCellAccessoryCheckmark];
                [cellNone setAccessoryType:UITableViewCellAccessoryNone];
                [cellBind setAccessoryType:UITableViewCellAccessoryNone];
                break;
            }
                
            case 2: {
                
                [self.delegate setBorderType:MTBarcodeBorderStyleBind];
                UITableViewCell *cellNone = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
                UITableViewCell *cellBox = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
                [cell setAccessoryType: UITableViewCellAccessoryCheckmark];
                [cellNone setAccessoryType:UITableViewCellAccessoryNone];
                [cellBox setAccessoryType:UITableViewCellAccessoryNone];
                break;
            }
                
            default:
                break;
        }
        
    } else if (section == [self tableViewSection2dComponent]) {

        // FIXME: Not implemented

        switch (row) {
            case 0: {
                BOOL wasEnabled = [[self.delegate barcodeToDisplay] has2dComponentEnabled];
                UITableViewCellAccessoryType accessory = wasEnabled ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
                [cell setAccessoryType: accessory];
                [self.delegate barcode2dComponentSetEnabled: !wasEnabled ];
                break;
            }
            default:
                break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    
    if (section == [self tableViewSectionDefination]) {
        title = @"Definition";
    } else if (section == [self tableViewSectionRendering]) {
        title = @"Rendering";
    } else if (section == [self tableViewSectionBorder]) {
        title = @"Border";
    } else if (section == [self tableViewSection2dComponent]) {
        title = @"2D Component";
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
    if ([self selecting2dComponentType]) {
        result = [barcode option1];
    } else {
        switch ([barcode barcodeType]) {
                
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
    MTBarcode *barcode = [self.delegate barcodeToDisplay];
    if ([self selecting2dComponentType]) {
        [barcode setHas2dComponentType:tag];
        [self.delegate updateBarcode];
    } else {
        switch ([barcode barcodeType]) {
                
            case MTBarcodeTypeCodeOne:
                [(MTBarcodeCodeOne *)barcode setSize:tag];
                [self.delegate updateBarcode];
                break;
                
            case MTBarcodeTypeMsiPlessey:
                [(MTBarcodeMsiPlessey *)barcode setCheckDigit:tag];
                [self.delegate updateBarcode];
                break;
                
            case MTBarcodeTypeRssExpstack:
                [(MTBarcodeDatabarExpandedStacked *)barcode setNumberOfDataColumns:tag];
                [self.delegate updateBarcode];
                break;
                
            case MTBarcodeTypeMicroPdf417:
                [(MTBarcodeMicroPdf417Iso24728 *)barcode setNumberOfDataColumns:tag];
                [self.delegate updateBarcode];
                break;
                
            case MTBarcodeTypeChannel:
                [(MTBarcodeChannelCode *)barcode setNumberOfChannels:tag];
                [self.delegate updateBarcode];
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
    MTBarcodeDataMatrixIso16022 *barcode = (MTBarcodeDataMatrixIso16022 *)[self.delegate barcodeToDisplay];
    [barcode setSymbolSize:size];
    [self.delegate updateBarcode];
}
- (void)barcodeDataMatrixDidSuppressRectangularSymbols:(BOOL)suppress {
    MTBarcodeDataMatrixIso16022 *barcode = (MTBarcodeDataMatrixIso16022 *)[self.delegate barcodeToDisplay];
    [barcode suppressRectangularSymbolsInAutomaticMode:suppress];
    [self.delegate updateBarcode];
}

- (BOOL)barcodeDataMatrixSuppressRectangularSymbols {
    MTBarcodeDataMatrixIso16022 *barcode = (MTBarcodeDataMatrixIso16022 *)[self.delegate barcodeToDisplay];
    return [barcode suppressRectangularSymbols];
}

#pragma mark - MTQueryBuilderChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller
                                      withField:(RptqQueryField *)field {

    [[self navigationController] popViewControllerAnimated:YES];
    if  ([self selectingField1]) {
        [self.delegate didSetField1:field];
    } else if ([self selectingField2]) {
        [self.delegate didSetField2:field];
    }
    
    MTQuery *querySampleDataField = [[MTQuery alloc] initWithQueryType: MTQueryTypeSampleDataField
                                                                object: field.databaseSchemaField];
    __weak MTViewControllerBarcodeOptions *weakself = self;
    [querySampleDataField performQuery:^(BOOL success, NSError *error) {
        
        __strong MTViewControllerBarcodeOptions *strongself = weakself;
        
        if (success) {
            MTDataTable *dt = [querySampleDataField.database.delegate dataTableForQuery:querySampleDataField];
            [strongself setSampleDataTable:dt];
            NSAssert((strongself.selectingField1 == NO && strongself.selectingField2 == NO) == NO, @"Must be setting one or the other.");
            NSAssert((strongself.selectingField1 && strongself.selectingField2) == NO, @"Can't be setting both at the same time, now can we?");
            if (strongself.selectingField1) {
                NSArray *allObjects = [strongself.sampleDataTable allObjects];
                [strongself setSampleBarcodeData:allObjects];
            } else if (strongself.selectingField2) {
                NSArray *allObjects = [strongself.sampleDataTable allObjects];
                [strongself setSampleBarcodeData2dComponent:allObjects];
            }
            [strongself.tableView reloadData];

        } else {
            __weak MTViewControllerBarcodeOptions *weakself2 = strongself;
            [NSError presentError: error
                 onViewController: self
                       completion:^(BOOL success) {
                           __strong MTViewControllerBarcodeOptions *strongself2 = weakself2;
                           NSString *key = [NSString stringWithString:querySampleDataField.database.databaseConnection.connectionString];
                           [[MTKeyChain sharedObject] deleteKey:key usingViewController:strongself2];
                       }];
            
        }
    }];
}

#pragma mark - MTDatabaseProtocol

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return [self sampleDataTable];
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
    return [barcode primaryData];
}

- (void)barcodeMaxicodeDidChooseSampleData:(NSArray *)sampleData {
    [self setSampleBarcodeDataMaxicode:sampleData];
    if ([sampleData count] > 0) {
        id result = [[sampleData[0] allObjects] lastObject];
        [self.delegate barcodeMaxicodeDidSetPrimaryData:result];
    } else {
        [self.delegate barcodeMaxicodeDidSetPrimaryData:nil];
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
