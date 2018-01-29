//
//  ViewController.m
//  IGBLEPeripheralDemo
//
//  Created by xujiaqi on 2017/12/21.
//  Copyright © 2017年 geely. All rights reserved.
//

#import "ViewController.h"
#import <BabyBluetooth.h>
#import "SVProgressHUD.h"

#define Pass_Through_Service @"8A97F7C0-8506-11E3-bAA7-0800200C9A10"
//BLE发送给App
#define Transmit_Data_Status_Characteristic @"A010"
#define Transmit_Data_Characteristic @"A011"
//App发送给BLE
#define Receive_Data_Status_Characteristic @"B010"
#define Receive_Data_Characteristic @"B011"

#define Share_State_Synchronize_Service @"8A97F7C0-8506-11E3-bAA7-0800200C9A11"
#define BLE_Status_Characteristic @"C010"
#define Digital_Key_Status_Characteristic @"C011"
#define Main_MCU_Status_Characteristic @"C012"

struct NewType {
    Byte value[3];
};

typedef struct {
    struct NewType main_firmware_version;//主firmware版本
    struct NewType backup_firmware_version;//备firmware版本
    uint32_t upgrade_rom_size;  // 当前可用于FW升级的ROM大小
    uint16_t error_log_size;  // 未上报的Error log量
} __attribute__((packed)) IGBLEStatus;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *passThroughDataStatusLabel;
@property (weak, nonatomic) IBOutlet UITextView *passThroughDataTextView;

@property (strong, nonatomic) BabyBluetooth *baby;

@property (strong, nonatomic) NSMutableData *statusData;
@property (strong, nonatomic) NSMutableData *totalData;
@property (strong, nonatomic) NSMutableArray *services;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _baby = [BabyBluetooth shareBabyBluetooth];
    _baby.bePeripheralWithName(@"jackiexujiaqi");
    
    [self configServicesAndCharacteristics];
    //配置委托
    [self babyDelegate];
}

- (void)configServicesAndCharacteristics
{
    CBMutableService *service1 = makeCBService(Pass_Through_Service);
    makeCharacteristicToService(service1, Receive_Data_Status_Characteristic, @"rwn", @"Receive_Data_Status_Characteristic");
    makeCharacteristicToService(service1, Receive_Data_Characteristic, @"rwn", @"Receive_Data_Characteristic");
    makeCharacteristicToService(service1, Transmit_Data_Status_Characteristic, @"rwn", @"Transmit_Data_Status_Characteristic");
    makeCharacteristicToService(service1, Transmit_Data_Characteristic, @"rwn", @"Transmit_Data_Characteristic");

    CBMutableService *service2 = makeCBService(@"8a97f7c0-8506-11e3-baa7-0800200c9a11");
    
    makeCharacteristicToService(service2, BLE_Status_Characteristic, @"rwn",@"BLE Status");
    makeCharacteristicToService(service2, Digital_Key_Status_Characteristic, @"rwn", @"Digital Key Status");
    makeCharacteristicToService(service2, Main_MCU_Status_Characteristic, @"rwn", @"Main MCU Status");
    
    _services = [@[service1, service2] mutableCopy];
    
//    CBMutableCharacteristic *ble_status_charac = (CBMutableCharacteristic *)[BabyToy findCharacteristicFormServices:self.services UUIDString:BLE_Status_Characteristic] ;
//    ble_status_charac.value = [self ble_status_data];
    self.baby.bePeripheral().addServices(@[service1, service2]).startAdvertising();
}

//配置委托
- (void)babyDelegate{
    
    //设置添加service委托 | set didAddService block
    [self.baby peripheralModelBlockOnDidStartAdvertising:^(CBPeripheralManager *peripheral, NSError *error) {
        NSLog(@"didStartAdvertising !!!");
    }];
    
    //收到读取请求
    [self.baby peripheralModelBlockOnDidReceiveReadRequest:^(CBPeripheralManager *peripheral, CBATTRequest *request) {
        CBCharacteristic *chara = request.characteristic;
        NSLog(@"\n---------\n");
        NSLog(@"DidReceiveReadRequest\n----\n%@\n----\n%@\n----", chara,chara.value);
        if (request.characteristic.properties & CBCharacteristicPropertyRead) {
            
            if ([chara.UUID.UUIDString isEqualToString:BLE_Status_Characteristic]) {
                
//                mutableChara.value = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
            } else if ([chara.UUID.UUIDString isEqualToString:Digital_Key_Status_Characteristic]) {
//                mutableChara.value = [@"2" dataUsingEncoding:NSUTF8StringEncoding];
            } else if ([chara.UUID.UUIDString isEqualToString:Main_MCU_Status_Characteristic]) {
//                mutableChara.value = [@"3" dataUsingEncoding:NSUTF8StringEncoding];
            }
            [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        } else {
            [peripheral respondToRequest:request withResult:CBATTErrorReadNotPermitted];
        }
    }];
    
    //收到写入请求
    [self.baby peripheralModelBlockOnDidReceiveWriteRequests:^(CBPeripheralManager *peripheral,NSArray *requests) {
        CBATTRequest *request = requests[0];
        NSLog(@"\n---------\n");
        NSLog(@"DidReceiveWriteRequests\n----\n%@\n----\n%@\n----", request.characteristic,request.characteristic.value);
        //判断是否有写数据的权限
        if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
            [self didReadReceiveData:request.value characteristic:request.characteristic];
            [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
            
        }else{
            [peripheral respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
        }
    }];
    
    __block NSTimer *timer;
    //设置添加service委托 | set didAddService block
    [self.baby peripheralModelBlockOnDidSubscribeToCharacteristic:^(CBPeripheralManager *peripheral, CBCentral *central, CBCharacteristic *characteristic) {
        NSLog(@"订阅了 %@的数据",characteristic.UUID);
//        if ([characteristic.UUID.UUIDString isEqualToString:BLE_Status_Characteristic]) {
//            [self didSubscribeBLEStatus:characteristic];
//        } else if ([characteristic.UUID.UUIDString isEqualToString:Digital_Key_Status_Characteristic]) {
//            [self didSubscribeDigitalKeyStatus:characteristic];
//        } else if ([characteristic.UUID.UUIDString isEqualToString:Main_MCU_Status_Characteristic]) {
//            [self didSubscribeMainMCUStatus:characteristic];
//        }
    }];
    
    //设置添加service委托 | set didAddService block
    [self.baby peripheralModelBlockOnDidUnSubscribeToCharacteristic:^(CBPeripheralManager *peripheral, CBCentral *central, CBCharacteristic *characteristic) {
        NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
        [timer fireDate];
    }];
}

- (void)didReadReceiveData:(NSData *)data characteristic:(CBCharacteristic *)characteristic
{
    if ([characteristic.UUID.UUIDString isEqualToString:Receive_Data_Status_Characteristic]) {
        self.statusData = [NSMutableData data];
        [self.statusData appendData:data];
        self.passThroughDataStatusLabel.text = [NSString stringWithFormat:@"%@", self.statusData];
        
        CBMutableCharacteristic *data_Status_Characteristic = (CBMutableCharacteristic *)[BabyToy findCharacteristicFormServices:self.services UUIDString:Transmit_Data_Status_Characteristic] ;
        [self.baby.peripheralManager updateValue:self.statusData forCharacteristic:data_Status_Characteristic onSubscribedCentrals:nil];
        
    } else if ([characteristic.UUID.UUIDString isEqualToString:Receive_Data_Characteristic]) {
        
        NSData *lengthData = [self.statusData subdataWithRange:NSMakeRange(0, 1)];
        int length = [BabyToy ConvertDataToInt:lengthData];
        
        [self writeToTramsmitCharacter:data];
        
        if (self.totalData.length <= length) {
            [self.totalData appendData:data];
//            self.passThroughDataTextView.text = [NSString stringWithFormat:@"%@", self.totalData];
            if (self.totalData.length == length) {
                
                NSString *transmitString = [[NSString alloc] initWithData:self.totalData encoding:NSUTF8StringEncoding];
                [self clearAction:nil];
                self.passThroughDataTextView.text = transmitString;
            }
        } else {
            [self clearAction:nil];
        }
    }
}

- (void)writeToTramsmitCharacter:(NSData *)data
{
    CBMutableCharacteristic *data_Characteristic = (CBMutableCharacteristic *)[BabyToy findCharacteristicFormServices:self.services UUIDString:Transmit_Data_Characteristic] ;

    [self.baby.peripheralManager updateValue:data forCharacteristic:data_Characteristic onSubscribedCentrals:nil];
}

- (IBAction)BLEStatusChangeAction:(id)sender {
    CBMutableCharacteristic *mutableC  = (CBMutableCharacteristic *)[BabyToy findCharacteristicFormServices:self.services UUIDString:BLE_Status_Characteristic];
    [self.baby.peripheralManager updateValue:[self ble_status_data] forCharacteristic:mutableC onSubscribedCentrals:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.baby.peripheralManager updateValue:[self ble_status_data_NEW] forCharacteristic:mutableC onSubscribedCentrals:nil];
    });
}

//0是无效，1是有效，2是待校验
- (IBAction)DigitalKeytatusChangeAction:(id)sender {
    CBMutableCharacteristic *mutableC = (CBMutableCharacteristic *)[BabyToy findCharacteristicFormServices:self.services UUIDString:Digital_Key_Status_Characteristic];
    
    [self.baby.peripheralManager updateValue:[BabyToy ConvertIntToData:1] forCharacteristic:mutableC onSubscribedCentrals:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.baby.peripheralManager updateValue:[BabyToy ConvertIntToData:0] forCharacteristic:mutableC onSubscribedCentrals:nil];
    });
}

//0：工作态 1：standby 2：sleep
- (IBAction)MainMCUStatusChangeAction:(id)sender {
    CBMutableCharacteristic *mutableC = (CBMutableCharacteristic *)[BabyToy findCharacteristicFormServices:self.services UUIDString:Main_MCU_Status_Characteristic];;
    [self.baby.peripheralManager updateValue:[BabyToy ConvertIntToData:0] forCharacteristic:mutableC onSubscribedCentrals:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.baby.peripheralManager updateValue:[BabyToy ConvertIntToData:1] forCharacteristic:mutableC onSubscribedCentrals:nil];
    });
}

- (NSData *)ble_status_data
{
    IGBLEStatus status;
    status.main_firmware_version.value[0] = 0x01;
    status.main_firmware_version.value[1] = 0x02;
    status.main_firmware_version.value[2] = 0x03;
    status.backup_firmware_version.value[0] = 0x06;
    status.backup_firmware_version.value[1] = 0x07;
    status.backup_firmware_version.value[2] = 0x08;
    status.upgrade_rom_size = 0xf;
    status.error_log_size = 0xf;
    
    NSData *dataRes = [NSData dataWithBytes:&status length:sizeof(status)];
    return dataRes;
}

- (NSData *)ble_status_data_NEW
{
    IGBLEStatus status;
    status.main_firmware_version.value[0] = 0x03;
    status.main_firmware_version.value[1] = 0x02;
    status.main_firmware_version.value[2] = 0x01;
    status.backup_firmware_version.value[0] = 0x08;
    status.backup_firmware_version.value[1] = 0x07;
    status.backup_firmware_version.value[2] = 0x06;
    status.upgrade_rom_size = 0xe;
    status.error_log_size = 0xd;
    
    NSData *dataRes = [NSData dataWithBytes:&status length:sizeof(status)];
    return dataRes;
}

- (void)clearAction:(id)sender {
//    self.passThroughDataStatusLabel.text = nil;
    
    //NSMutableData 清空
    [self.totalData resetBytesInRange:NSMakeRange(0, [self.totalData length])];
    [self.totalData setLength:0];
}

- (NSMutableData *)totalData
{
    if (!_totalData) {
        _totalData = [NSMutableData data];
    }
    return _totalData;
}

@end
