//
//  MTViewControllerBarcodeOptions.m
//  MAD
//
//  Created by Michael Thomason on 11/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerBarcodeOptions.h"

@interface MTViewControllerBarcodeOptions ()

@property (nonatomic, assign) MTBarcodeType barcodeType;

@end

@implementation MTViewControllerBarcodeOptions

- (IBAction)unwindToBarcodeOptions:(UIStoryboardSegue *)action {
    
}

- (void)dealloc {
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

- (void)customInit { }

- (void)viewDidLoad {
    [super viewDidLoad];
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

- (void)setBarcodeType:(MTBarcodeType)barcodeType {
    _barcodeType = barcodeType;
    [[self tableView] reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    NSInteger numberOfSections = 3;
    
    //If barcode type has custom options, add a group for it.
    switch ([self barcodeType]) {
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
            result = 2;
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

    NSString *displayText = nil;
    UITableViewCell *cell = nil;
    switch ([indexPath section]) {
        case 0:
            
            switch ([indexPath row]) {
                case 0:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeData forIndexPath:indexPath] retain];
                    break;
                case 1:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeType forIndexPath:indexPath] retain];
                    NSString *barcodeName = [MTBarcode barcodeNameForType:[self barcodeType]];
                    [[cell detailTextLabel] setText:barcodeName];
                    break;
                default:
                    break;
            }

            break;
        case 1:

            switch ([indexPath row]) {
                case 0:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeShowHumanReadableText forIndexPath:indexPath] retain];
                    break;
                case 1:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeShowErrorMessages forIndexPath:indexPath] retain];
                    break;
                default:
                    break;
            }
            
            break;
        case 2:
            
            switch ([indexPath row]) {
                case 0:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderNone forIndexPath:indexPath] retain];
                    break;
                case 2:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorder forIndexPath:indexPath] retain];
                    break;
                case 3:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderOption2 forIndexPath:indexPath] retain];
                    break;
                case 1:
                    cell = [[tableView dequeueReusableCellWithIdentifier:MTIdentifierTvcBarcodeAppearanceBorderWidth forIndexPath:indexPath] retain];
                    UIStepper *stepper = [[UIStepper alloc] init];
                    [stepper setWraps:NO];
                    [stepper setValue:1.0000f];
                    [[cell contentView] addSubview:stepper];
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

- (void)didChangeBarcodeType:(MTBarcodeType)barcodeType {
    [[self delegate] didChangeBarcodeType:barcodeType];
}

#pragma mark - MTQueryBuilderChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqQueryField *)field {
    [[self delegate] setSampleData:@[@"1234567890"]];
}

@end
