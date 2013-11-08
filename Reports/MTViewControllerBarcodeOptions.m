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

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"MTIdentifierSegueBarcodeField"]) {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([indexPath section] == 1 && [indexPath row] == 0) {

    }
}

#pragma mark - MTQueryBuilderChooseFieldDelegate

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqQueryField *)field {
    [[self delegate] setSampleData:@[@"1234567890"]];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation

 */

@end
