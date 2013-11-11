//
//  MTViewControllerBarcodeOptions.m
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerBarcodeOptions.h"

@interface MTViewControllerBarcodeOptions ()

@property (nonatomic, retain) NSArray *sampleBarcodeData;
@property (nonatomic, assign) NSUInteger sampleBarcodeIndex;

@property (nonatomic, retain) UIFont *mainFont;
@property (nonatomic, retain) UIFont *detailFont;

@property (nonatomic, assign) NSInteger borderWidth;

@end

@implementation MTViewControllerBarcodeOptions

- (IBAction)unwindToBarcodeOptions:(UIStoryboardSegue *)action {
    if ([[action identifier] isEqualToString:@"MTIdentifierSegueBarcodeFieldUnwind"]) {
        //[[self tableView] reloadData];
    } else if ([[action identifier] isEqualToString:@"MTIdentifierSegueBarcodeTypeUnwind"]) {
        //[[self tableView] reloadData];
    }
}

- (void)dealloc {
    //NSString *barcodeType = NSStringFromSelector(@selector(barcodeType));
    //NSString *showErrorMessages = NSStringFromSelector(@selector(showErrorMessages));
    //NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    //[self removeObserver:[self barcode] forKeyPath:barcodeType];
    //[self removeObserver:[self barcode] forKeyPath:showErrorMessages];
    //[self removeObserver:[self barcode] forKeyPath:humanReadable];
    [_sampleBarcodeData release];
    [_mainFont release];
    [_detailFont release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        [self customInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit {
    [self setBorderWidth:5];
    [self setSampleBarcodeIndex: 0];
    NSArray *sampleBarcodeData = @[@{@"Sample Data" : @"Sample Data"}];
    [sampleBarcodeData retain];
    [self setSampleBarcodeData:sampleBarcodeData];
    [sampleBarcodeData release];
    

}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *barcodeType = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessages = NSStringFromSelector(@selector(showErrorMessages));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    MTBarcode *barcode = [[self delegate] barcodeToDisplay];
    [self addObserver:barcode forKeyPath:barcodeType options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:barcode forKeyPath:showErrorMessages options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:barcode forKeyPath:humanReadable options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self tableView] reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"MTIdentifierSegueBarcodeField"]) {

        [[segue destinationViewController] setDelegate:self];

    } else if ([[segue identifier] isEqualToString:@"MTIdentifierSegueBarcodeType"]) {

        MTViewControllerBarcodeType *barcodeTypeViewController = [segue destinationViewController];
        MTBarcode *barcode = [[self delegate] barcodeToDisplay];
        [barcodeTypeViewController setInitalKey:[barcode barcodeType]];
        [barcodeTypeViewController setDelegate:self];

    }

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [[self tableView] reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    NSInteger numberOfSections = 3;
    MTBarcode *barcode = [[self delegate] barcodeToDisplay];

    //If barcode type has custom options, add a group for it.
    switch ([barcode barcodeType]) {
        case MTBarcodeTypeAztec:
        case MTBarcodeTypeChannel:
        case MTBarcodeTypeCODE128:
        case MTBarcodeTypeCODE16K:
        case MTBarcodeTypeCODE39:
        case MTBarcodeTypeEXCODE39:
        case MTBarcodeTypeCODE49:
        case MTBarcodeTypeCodeOne:
        case MTBarcodeTypeRssExpstack:
        case MTBarcodeTypeDataMatrix:
        case MTBarcodeTypeGridMatrix:
        case MTBarcodeTypeMaxicode:
        case MTBarcodeTypeMicroPdf417:
        case MTBarcodeTypeMicroqr:
        case MTBarcodeTypeMsiPlessey:
        case MTBarcodeTypePdf417:
        case MTBarcodeTypeQrcode:
            numberOfSections++;
            break;
            
        default:
            break;
    }
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger result = 0;

    switch (section) {
        case 0: {
            result = 2;
            MTBarcode *barcode = [[self delegate] barcodeToDisplay];
            if ([barcode has2dComponent]) {
                result++;
            }
            if ([barcode hasOptionalInput]) {
                result++;
            }
            break;
        }
        case 1:
            result = 3;
            break;
        case 2:
            result = 4;
            break;
        case 3:
            result = 0;
            break;
        default:
            break;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *MTIdentifierTvcBarcodeData                         = @"MTIdentifierTvcBarcodeData";
    static NSString *MTIdentifierTvcBarcodeType                         = @"MTIdentifierTvcBarcodeType";

    static NSString *MTIdentifierTvcBarcodeShowHumanReadableText        = @"MTIdentifierTvcBarcodeShowHumanReadableText";
    static NSString *MTIdentifierTvcBarcodeShowErrorMessages            = @"MTIdentifierTvcBarcodeShowErrorMessages";

    
    static NSString *MTIdentifierTvcBarcodeAppearanceBorder             = @"MTIdentifierTvcBarcodeAppearanceBorder";
    static NSString *MTIdentifierTvcBarcodeAppearanceForegroundColor    = @"MTIdentifierTvcBarcodeAppearanceForegroundColor";
    static NSString *MTIdentifierTvcBarcodeAppearanceBackgroundColor    = @"MTIdentifierTvcBarcodeAppearanceBackgroundColor";

    static NSString *MTIdentifierTvcBarcodeAppearanceBorderNone         = @"MTIdentifierTvcBarcodeAppearanceBorderNone";
    static NSString *MTIdentifierTvcBarcodeAppearanceBorderOption2      = @"MTIdentifierTvcBarcodeAppearanceBorderOption2";
    static NSString *MTIdentifierTvcBarcodeAppearanceBorderWidth        = @"MTIdentifierTvcBarcodeAppearanceBorderWidth";
    static NSString *MTIdentifierTvcBarcodeAppearanceSymbolHeight       = @"MTIdentifierTvcBarcodeAppearanceSymbolHeight";

    static NSString *MTIdentifierTvcBarcodeHas2dComponent               = @"MTIdentifierTvcBarcodeHas2dComponent";
    static NSString *MTIdentifierTvcBarcodeHasOptionalInput             = @"MTIdentifierTvcBarcodeHasOptionalInput";
    
    NSString *displayText = nil;
    UITableViewCell *cell = nil;
    MTBarcode *barcode = [[self delegate] barcodeToDisplay];
    
    switch ([indexPath section]) {
        case 0:
            
            switch ([indexPath row]) {
                case 0: {
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeData forIndexPath:indexPath] retain];
                    
                    NSInteger sampleBarcodeDataCount = [[self sampleBarcodeData] count];
                    
                    NSAssert(sampleBarcodeDataCount >= 1, @"Sample data is missing");

                    if ([self sampleBarcodeIndex] >= sampleBarcodeDataCount) {
                        [self setSampleBarcodeIndex:0];
                    }
                    
                    NSDictionary *sampleItem = [[self sampleBarcodeData] objectAtIndex:[self sampleBarcodeIndex]];
                    NSString *sampleText = [NSString stringWithFormat:@"%@", [[sampleItem allValues] lastObject]];
                    [self setSampleBarcodeIndex: [self sampleBarcodeIndex] + 1];
                    [[self delegate] setInput:sampleText];
                    [[cell detailTextLabel] setText:sampleText];
                    break;
                }
                case 1:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeType forIndexPath:indexPath] retain];
                    NSString *barcodeName = [MTBarcode barcodeNameForType:[barcode barcodeType]];
                    [[cell detailTextLabel] setText:barcodeName];
                    break;
                case 2:
                    if ([barcode has2dComponent]) {
                        cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeHas2dComponent forIndexPath:indexPath] retain];
                    } else if ([barcode hasOptionalInput]) {
                        cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeHasOptionalInput forIndexPath:indexPath] retain];
                        NSString *barcodeName = [MTBarcode barcodeNameForType:[barcode barcodeType]];
                        NSString *textLabel = [NSString stringWithFormat:@"%@ detail", barcodeName];
                        [[cell textLabel] setText:textLabel];
                    }
                    break;
                case 3:
                    if ([barcode hasOptionalInput]) {
                        cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeHasOptionalInput forIndexPath:indexPath] retain];
                        NSString *barcodeName = [MTBarcode barcodeNameForType:[barcode barcodeType]];
                        NSString *textLabel = [NSString stringWithFormat:@"%@ detail", barcodeName];
                        [[cell textLabel] setText:textLabel];
                    }
                    break;
                default:
                    break;
            }

            break;
        case 1:

            switch ([indexPath row]) {
                case 0: {
                    BOOL humanReadable = [barcode humanReadable];
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeShowHumanReadableText forIndexPath:indexPath] retain];
                    UITableViewCellAccessoryType accessory = humanReadable ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                    break;
                }
                case 1: {
                    BOOL showErrorMessages = [barcode showErrorMessages];
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeShowErrorMessages forIndexPath:indexPath] retain];
                    UITableViewCellAccessoryType accessory = showErrorMessages ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                    break;
                }
                case 2: {
                    
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceSymbolHeight forIndexPath:indexPath] retain];
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
                        [stepper release];
                        
                        [cell setTag: tagWithStepper];
                    }
                    NSString *detail = [NSString stringWithFormat:@"%d", symbolHeight];
                    NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Symbol height" withDetail:detail];
                    [[cell textLabel] setAttributedText:attributedString];
                    
                }
                default:
                    break;
            }
            
            break;
        case 2: {
            
            MTBarcodeBorderStyle borderStyle = [barcode borderStyle];
            
            switch ([indexPath row]) {
                case 0: {
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderNone forIndexPath:indexPath] retain];
                    UITableViewCellAccessoryType accessory = borderStyle == MTBarcodeBorderStyleNone ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                    break;
                }
                case 1: {
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorder forIndexPath:indexPath] retain];
                    UITableViewCellAccessoryType accessory = borderStyle == MTBarcodeBorderStyleBox ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                    break;
                }
                case 2: {
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderOption2 forIndexPath:indexPath] retain];
                    UITableViewCellAccessoryType accessory = borderStyle == MTBarcodeBorderStyleBind ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                    break;
                }
                case 3: {
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderWidth forIndexPath:indexPath] retain];
                    
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
                        [stepper release];

                        [cell setTag: tagWithStepper];
                    }
                    NSString *detail = [NSString stringWithFormat:@"%d", [self borderWidth]];
                    NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Border width" withDetail:detail];
                    [[cell textLabel] setAttributedText:attributedString];

                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 3:
            
            break;
            
        default:
            break;
    }
    
    return [cell autorelease];
}

+ (NSAttributedString *)subject:(NSString *)subjectPart withDetail:(NSString *)detailPart {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIFont *boldFont = [[appDelegate mainFont] retain];
    UIFont *systemFont = [[appDelegate detailFont] retain];
    NSDictionary *boldAttributes = @{NSFontAttributeName : boldFont, NSForegroundColorAttributeName : [UIColor blackColor]};
    NSDictionary *normalAttributes = @{NSFontAttributeName : systemFont, NSForegroundColorAttributeName : [UIColor lightGrayColor]};
    
    NSMutableAttributedString *localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString:subjectPart
                                                                                                   attributes:boldAttributes];
    NSString *pointsString = [@" " stringByAppendingString:detailPart];
    NSAttributedString *messageSuffix = [[NSAttributedString alloc] initWithString:pointsString attributes:normalAttributes];
    [localizedAttributedMessage appendAttributedString:messageSuffix];
    [messageSuffix release];
    [boldFont release]; [systemFont release];
    return [localizedAttributedMessage autorelease];
}


- (void)didChangeBorderWidth:(UIStepper *)sender {
    [self setBorderWidth:(NSInteger) [sender value]];
    NSString *detail = [NSString stringWithFormat:@"%d", (NSInteger)[sender value]];
    NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Border width" withDetail:detail];
    UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:2]];
    [[cell textLabel] setAttributedText:attributedString];
    [[self delegate] setBorderWidth:[sender value]];
}

- (void)didChangeSymbolHeight:(UIStepper *)sender {
    NSString *detail = [NSString stringWithFormat:@"%d", (NSInteger)[sender value]];
    NSAttributedString *attributedString = [MTViewControllerBarcodeOptions subject:@"Symbol height" withDetail:detail];
    UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
    [[cell textLabel] setAttributedText:attributedString];
    [[self delegate] didChangeSymbolHeight:[sender value]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    switch ([indexPath section]) {
        case 1:
            
            switch ([indexPath row]) {

                case 0: {
                    BOOL humanReadable = [[self delegate] didToggleHumanReadable];
                    UITableViewCellAccessoryType accessory = humanReadable ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                    break;
                }
                    
                case 1: {
                    BOOL showErrorMessages = [[self delegate] didToggleShowErrorMessages];
                    UITableViewCellAccessoryType accessory = showErrorMessages ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                    break;
                }
                    
                default:
                    break;
            }
            
            break;
            
            case 2:
            
            switch ([indexPath row]) {
                case 0: {

                    [[self delegate] setBorderType:MTBarcodeBorderStyleNone];
                    UITableViewCell *cellBox = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
                    UITableViewCell *cellBind = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2]];
                    [cell setAccessoryType: UITableViewCellAccessoryCheckmark];
                    [cellBox setAccessoryType:UITableViewCellAccessoryNone];
                    [cellBind setAccessoryType:UITableViewCellAccessoryNone];
                    break;
                }
                case 1: {
                    
                    [[self delegate] setBorderType:MTBarcodeBorderStyleBox];
                    UITableViewCell *cellNone = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
                    UITableViewCell *cellBind = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2]];
                    [cell setAccessoryType: UITableViewCellAccessoryCheckmark];
                    [cellNone setAccessoryType:UITableViewCellAccessoryNone];
                    [cellBind setAccessoryType:UITableViewCellAccessoryNone];
                    break;
                }
                    
                case 2: {
                    
                    [[self delegate] setBorderType:MTBarcodeBorderStyleBind];
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
            
            break;
            
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    switch (section) {
        case 0:
            title = @"Definition";
            break;
        case 1:
            title = @"Rendering";
            break;
        case 2:
            title = @"Border";
            break;
        case 3:
            break;
            
        default:
            break;
    }
    return title;
}

- (void)didChangeBarcodeType:(MTBarcodeType)barcodeType {
    [[self delegate] didChangeBarcodeType:barcodeType];
}

#pragma mark - MTQueryBuilderChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqQueryField *)field {

    [[self navigationController] popViewControllerAnimated:YES];
    
    RptqDocument *document = [RptqDocument activeDocument];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
    [mnsDatabase sampleDataForSchemaField:[field databaseSchemaField] completion:^(BOOL success, NSError *error, NSArray *resultStrings) {
        if (success) {
            [resultStrings retain];
            [self setSampleBarcodeData:resultStrings];
            [resultStrings release];
            [[self tableView] reloadData];
        }
    }];
}

@end
