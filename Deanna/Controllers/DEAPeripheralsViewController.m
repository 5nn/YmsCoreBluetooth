// 
// Copyright 2013 Yummy Melon Software LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Author: Charles Y. Choi <charles.choi@yummymelon.com>
//

#import "DEAPeripheralsViewController.h"
#import "DEASensorTag.h"
#import "DEASensorTagViewController.h"
#import "DEAPeripheralTableViewCell.h"
#import "DEAStyleSheet.h"

@interface DEAPeripheralsViewController ()
- (void)editButtonAction:(id)sender;
@end

@implementation DEAPeripheralsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Deanna";
    
    /*
     First time DEACentralManager singleton is instantiated.
     All subsequent references will use [DEACentralManager sharedService].
     */
    DEACentralManager *centralManager = [DEACentralManager initSharedServiceWithDelegate:self];
    

    [self.navigationController setToolbarHidden:NO];


    self.scanButton = [[UIBarButtonItem alloc] initWithTitle:@"Start Scanning" style:UIBarButtonItemStyleBordered target:self action:@selector(scanButtonAction:)];
    
    self.toolbarItems = @[self.scanButton];
    
    [self.peripheralsTableView reloadData];
    
    [centralManager addObserver:self
                  forKeyPath:@"isScanning"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
    
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonAction:)];
    
    self.navigationItem.rightBarButtonItem = editButton;
    
    
    self.peripheralsTableView.backgroundColor = kDEA_STYLE_BACKGROUNDCOLOR;
    self.peripheralsTableView.separatorColor = kDEA_STYLE_TABLEVIEW_SEPARATORCOLOR;
    
}

- (void)viewWillAppear:(BOOL)animated {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    centralManager.delegate = self;
    
    for (UITableViewCell *cell in [self.peripheralsTableView visibleCells]) {
        if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
            DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)cell;
            pcell.sensorTag.delegate = self;
        }
    }

}

- (void)viewDidDisappear:(BOOL)animated {
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    if (object == centralManager) {
        if ([keyPath isEqualToString:@"isScanning"]) {
            if (centralManager.isScanning) {
                self.scanButton.title = @"Stop Scanning";
            } else {
                self.scanButton.title = @"Start Scan";
            }
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)scanButtonAction:(id)sender {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    if (centralManager.isScanning == NO) {
        [centralManager startScan];
    }
    else {
        [centralManager stopScan];
    }
}


- (void)editButtonAction:(id)sender {
    UIBarButtonItem *button = nil;
    
    [self.peripheralsTableView setEditing:(!self.peripheralsTableView.editing) animated:YES];
    
    if (self.peripheralsTableView.editing) {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editButtonAction:)];
    } else {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonAction:)];
        
    }
    self.navigationItem.rightBarButtonItem = button;
        
}

#pragma mark - CBCentralManagerDelegate Methods


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    YMSCBPeripheral *yp = [centralManager findPeripheral:peripheral];
    yp.delegate = self;
    
    [yp.cbPeripheral readRSSI];
    
    for (UITableViewCell *cell in [self.peripheralsTableView visibleCells]) {
        if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
            DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)cell;
            if (pcell.sensorTag == yp) {
                [pcell updateDisplay:peripheral];
                break;
            }
        }
    }
}



- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
   
    for (UITableViewCell *cell in [self.peripheralsTableView visibleCells]) {
        if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
            DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)cell;
            [pcell updateDisplay:peripheral];
        }
    }
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    BOOL test = YES;
    
    for (UITableViewCell *cell in [self.peripheralsTableView visibleCells]) {
        if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
            DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)cell;
            if (pcell.sensorTag.cbPeripheral == peripheral) {
                test = NO;
                break;
            }
        }
    }
    
    if (test) {
        [self.peripheralsTableView reloadData];
    }
    
    
    
}


- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    for (CBPeripheral *peripheral in peripherals) {
        YMSCBPeripheral *yp = [centralManager findPeripheral:peripheral];
        if (yp) {
            yp.delegate = self;
        }
    }
    
    [self.peripheralsTableView reloadData];

}


- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    for (CBPeripheral *peripheral in peripherals) {
        YMSCBPeripheral *yp = [centralManager findPeripheral:peripheral];
        if (yp) {
            yp.delegate = self;
        }
    }
    
    [self.peripheralsTableView reloadData];
}

#pragma mark - CBPeripheralDelegate Methods

- (void)performUpdateRSSI:(NSArray *)args {
    CBPeripheral *peripheral = args[0];
    
    [peripheral readRSSI];

}


- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {

    if (error) {
        NSLog(@"ERROR: readRSSI failed, retrying. %@", error.description);
        
        if (peripheral.isConnected) {
            NSArray *args = @[peripheral];
            [self performSelector:@selector(performUpdateRSSI:) withObject:args afterDelay:2.0];
        }

        return;
    }
    
    for (UITableViewCell *cell in [self.peripheralsTableView visibleCells]) {
        if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
            DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)cell;
            if (pcell.sensorTag.cbPeripheral == peripheral) {
                pcell.rssiLabel.text = [NSString stringWithFormat:@"%@", peripheral.RSSI];
                break;
            }
        }
    }
    
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    YMSCBPeripheral *yp = [centralManager findPeripheral:peripheral];
    
    NSArray *args = @[peripheral];
    [self performSelector:@selector(performUpdateRSSI:) withObject:args afterDelay:yp.rssiPingPeriod];
}

#pragma mark - UITableViewDelegate and UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result;
    result = 172.0;
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *SensorTagCellIdentifier = @"SensorTagCell";
    //static NSString *UnknownPeripheralCellIdentifier = @"UnknownPeripheralCell";

    DEACentralManager *centralManager = [DEACentralManager sharedService];
    YMSCBPeripheral *yp = [centralManager peripheralAtIndex:indexPath.row];
    
    UITableViewCell *cell = nil;
    
    DEAPeripheralTableViewCell *pcell = (DEAPeripheralTableViewCell *)[tableView dequeueReusableCellWithIdentifier:SensorTagCellIdentifier];
    
    if (pcell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"DEAPeripheralTableViewCell" owner:self options:nil];
        pcell = self.tvCell;
        self.tvCell = nil;
    }
    if ([centralManager isKnownPeripheral:yp.cbPeripheral]) {
        [pcell configureWithPeripheral:(DEASensorTag *)yp];
    }
    else {
        [pcell configureWithPeripheral:nil];
    }
    
    if (yp.cbPeripheral.name == nil) {
        pcell.nameLabel.text = @"Undisclosed Name";
    } else {
        pcell.nameLabel.text = yp.cbPeripheral.name;
    }
    cell = pcell;

    return cell;

}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell isKindOfClass:[DEAPeripheralTableViewCell class]]) {
        [(DEAPeripheralTableViewCell *)cell applyStyle];
    }

    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    

    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete: {
            DEACentralManager *centralManager = [DEACentralManager sharedService];
            YMSCBPeripheral *yp = [centralManager peripheralAtIndex:indexPath.row];
            if ([yp isKindOfClass:[DEASensorTag class]]) {
                if (yp.cbPeripheral.isConnected) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"Disconnect the peripheral before deleting."
                                                                   delegate:nil cancelButtonTitle:@"Dismiss"
                                                          otherButtonTitles:nil];
                    
                    [alert show];
                    
                    break;
                }
            }
            [centralManager removePeripheral:yp];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
            
        case UITableViewCellEditingStyleInsert:
        case UITableViewCellEditingStyleNone:
            break;
            
        default:
            break;
    }
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    NSInteger result;
    result = centralManager.count;
    return result;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    DEACentralManager *centralManager = [DEACentralManager sharedService];
    
    DEASensorTag *sensorTag = (DEASensorTag *)[centralManager.ymsPeripherals objectAtIndex:indexPath.row];
    
    DEASensorTagViewController *stvc = [[DEASensorTagViewController alloc] initWithNibName:@"DEASensorTagViewController" bundle:nil];
    stvc.sensorTag = sensorTag;

    
    [self.navigationController pushViewController:stvc animated:YES];
    
    
}


- (void)viewDidUnload {
    [self setTvCell:nil];
    [super viewDidUnload];
}
@end