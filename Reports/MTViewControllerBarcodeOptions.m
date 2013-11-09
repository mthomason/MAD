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
    NSString *barcodeType = NSStringFromSelector(@selector(barcodeType));
    NSString *showErrorMessages = NSStringFromSelector(@selector(showErrorMessages));
    NSString *humanReadable = NSStringFromSelector(@selector(humanReadable));
    [self removeObserver:[self barcode] forKeyPath:barcodeType];
    [self removeObserver:[self barcode] forKeyPath:showErrorMessages];
    [self removeObserver:[self barcode] forKeyPath:humanReadable];
    [_sampleBarcodeData release];
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
    [self addObserver:[self barcode] forKeyPath:barcodeType options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:[self barcode] forKeyPath:showErrorMessages options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:[self barcode] forKeyPath:humanReadable options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self tableView] reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"MTIdentifierSegueBarcodeField"] ||
        [[segue identifier] isEqualToString:@"MTIdentifierSegueBarcodeType"]) {
        [[segue destinationViewController] setDelegate:self];
    }

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [[self tableView] reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    NSInteger numberOfSections = 3;
    
    //If barcode type has custom options, add a group for it.
    switch ([[self barcode] barcodeType]) {
        case MTBarcodeAztec:
        case MTBarcodeChannel:
        case MTBarcodeCODE128:
        case MTBarcodeCODE16K:
        case MTBarcodeCODE39:
        case MTBarcodeEXCODE39:
        case MTBarcodeCODE49:
        case MTBarcodeCodeOne:
        case MTBarcodeRssExpstack:
        case MTBarcodeDataMatrix:
        case MTBarcodeGridMatrix:
        case MTBarcodeMaxicode:
        case MTBarcodeMicroPdf417:
        case MTBarcodeMicroqr:
        case MTBarcodeMsiPlessey:
        case MTBarcodePdf417:
        case MTBarcodeQrcode:
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
        case 0:
            result = 2;
            break;
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
    static NSString *MTIdentifierTvcBarcodeType = @"MTIdentifierTvcBarcodeType";

    static NSString *MTIdentifierTvcBarcodeShowHumanReadableText        = @"MTIdentifierTvcBarcodeShowHumanReadableText";
    static NSString *MTIdentifierTvcBarcodeShowErrorMessages        = @"MTIdentifierTvcBarcodeShowErrorMessages";

    
    static NSString *MTIdentifierTvcBarcodeAppearanceBorder             = @"MTIdentifierTvcBarcodeAppearanceBorder";
    static NSString *MTIdentifierTvcBarcodeAppearanceForegroundColor    = @"MTIdentifierTvcBarcodeAppearanceForegroundColor";
    static NSString *MTIdentifierTvcBarcodeAppearanceBackgroundColor    = @"MTIdentifierTvcBarcodeAppearanceBackgroundColor";

    static NSString *MTIdentifierTvcBarcodeAppearanceBorderNone = @"MTIdentifierTvcBarcodeAppearanceBorderNone";
    static NSString *MTIdentifierTvcBarcodeAppearanceBorderOption2 = @"MTIdentifierTvcBarcodeAppearanceBorderOption2";
    static NSString *MTIdentifierTvcBarcodeAppearanceBorderWidth = @"MTIdentifierTvcBarcodeAppearanceBorderWidth";
    static NSString *MTIdentifierTvcBarcodeAppearanceSymbolHeight = @"MTIdentifierTvcBarcodeAppearanceSymbolHeight";

    NSString *displayText = nil;
    UITableViewCell *cell = nil;
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
                    NSString *barcodeName = [MTBarcode barcodeNameForType:[[self barcode] barcodeType]];
                    [[cell detailTextLabel] setText:barcodeName];
                    break;
                default:
                    break;
            }

            break;
        case 1:

            switch ([indexPath row]) {
                case 0: {
                    BOOL humanReadable = [[self barcode] humanReadable];
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeShowHumanReadableText forIndexPath:indexPath] retain];
                    UITableViewCellAccessoryType accessory = humanReadable ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                    break;
                }
                case 1: {
                    BOOL showErrorMessages = [[self barcode] showErrorMessages];
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeShowErrorMessages forIndexPath:indexPath] retain];
                    UITableViewCellAccessoryType accessory = showErrorMessages ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                    break;
                }
                case 2: {
                    
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceSymbolHeight forIndexPath:indexPath] retain];
                    NSInteger symbolHeight = [[self barcode] height];
                    
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
                    
                    
                }
                default:
                    break;
            }
            
            break;
        case 2:
            
            switch ([indexPath row]) {
                case 0:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderNone forIndexPath:indexPath] retain];
                    break;
                case 1:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorder forIndexPath:indexPath] retain];
                    break;
                case 2:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderOption2 forIndexPath:indexPath] retain];
                    break;
                case 3:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderWidth forIndexPath:indexPath] retain];
                    UIStepper *stepper = [[UIStepper alloc] init];
                    [stepper setWraps:NO];
                    [stepper setValue:1.0000f];
                    CGFloat centerY = CGRectGetMidY([[cell contentView] bounds]);
                    CGFloat correctX = CGPointZero.x + [[cell contentView] bounds].size.width - ([stepper bounds].size.width / 2.0000f) - 20.0000f;
                    [stepper addTarget:self action:@selector(didChangeBorderWidth:) forControlEvents:UIControlEventValueChanged];
                    [[cell contentView] addSubview:stepper];
                    CGPoint newCenter = CGPointMake(correctX, centerY);
                    [stepper setCenter:newCenter];
                    [stepper release];
                    
                    break;
                default:
                    break;
            }
            
            break;
        case 3:
            
            break;
            
        default:
            break;
    }
    
    return [cell autorelease];
}

- (void)didChangeBorderWidth:(UIStepper *)sender {
    [[self delegate] setBorderWidth:[sender value]];
}

- (void)didChangeSymbolHeight:(UIStepper *)sender {
    [[self delegate] didChangeSymbolHeight:[sender value]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([indexPath section]) {
        case 1:
            
            switch ([indexPath row]) {

                case 0: {
                    BOOL humanReadable = [[self delegate] didToggleHumanReadable];
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    UITableViewCellAccessoryType accessory = humanReadable ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    [cell setAccessoryType:accessory];
                    break;
                }
                    
                case 1: {
                    BOOL showErrorMessages = [[self delegate] didToggleShowErrorMessages];
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
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
                case 0:

                    [[self delegate] setBorderType:MTBarcodeBorderStyleNone];
                    
                    break;
                    
                case 1:
                    
                    [[self delegate] setBorderType:MTBarcodeBorderStyleBox];

                    break;
                case 2:
                    
                    [[self delegate] setBorderType:MTBarcodeBorderStyleBind];

                    break;

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
