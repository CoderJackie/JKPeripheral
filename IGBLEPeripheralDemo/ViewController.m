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
@property (weak, nonatomic) IBOutlet UILabel *ShowLabel;
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
    makeCharacteristicToService(service1, Receive_Data_Status_Characteristic, @"rw", @"Receive_Data_Status_Characteristic");
    makeCharacteristicToService(service1, Receive_Data_Characteristic, @"rw", @"Receive_Data_Characteristic");
    makeCharacteristicToService(service1, Transmit_Data_Status_Characteristic, @"rw", @"Transmit_Data_Status_Characteristic");
    makeCharacteristicToService(service1, Transmit_Data_Characteristic, @"rw", @"Transmit_Data_Characteristic");

    CBMutableService *service2 = makeCBService(@"8a97f7c0-8506-11e3-baa7-0800200c9a11");
    
//    IGBLEStatus status;
//    status.main_firmware_version.value[0] = 0x01;
//    status.main_firmware_version.value[1] = 0x02;
//    status.main_firmware_version.value[2] = 0x03;
//    status.backup_firmware_version.value[0] = 0x06;
//    status.backup_firmware_version.value[1] = 0x07;
//    status.backup_firmware_version.value[2] = 0x08;
//    status.upgrade_rom_size = 0xf;
//    status.error_log_size = 0xf;
//
//    NSData *dataRes = [NSData dataWithBytes:&status length:sizeof(status)];
    
    makeCharacteristicToService(service2, BLE_Status_Characteristic, nil,@"BLE Status");
    makeCharacteristicToService(service2, Digital_Key_Status_Characteristic, nil, @"Digital Key Status");
    makeCharacteristicToService(service2, Main_MCU_Status_Characteristic, nil, @"Main MCU Status");
    
//    makeCharacteristicToService(service2, BLE_Status_Characteristic, @"rw", @"BLE Status");
//    makeCharacteristicToService(service2, Digital_Key_Status_Characteristic, @"rw", @"Digital Key Status");
//    makeCharacteristicToService(service2, Main_MCU_Status_Characteristic, @"rw", @"Main MCU Status");
    
    _services = [@[service1, service2] mutableCopy];
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
    
    [self.baby peripheralModelBlockOnDidSubscribeToCharacteristic:^(CBPeripheralManager *peripheral, CBCentral *central, CBCharacteristic *characteristic) {
        NSLog(@"%@", characteristic);
    }];
    
    __block NSTimer *timer;
    //设置添加service委托 | set didAddService block
    [self.baby peripheralModelBlockOnDidSubscribeToCharacteristic:^(CBPeripheralManager *peripheral, CBCentral *central, CBCharacteristic *characteristic) {
        NSLog(@"订阅了 %@的数据",characteristic.UUID);
        //每秒执行一次给主设备发送一个当前时间的秒数
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendData:) userInfo:characteristic  repeats:YES];
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
    } else if ([characteristic.UUID.UUIDString isEqualToString:Receive_Data_Characteristic]) {
        
        NSData *lengthData = [self.statusData subdataWithRange:NSMakeRange(0, 1)];
        int length = [BabyToy ConvertDataToInt:lengthData];
        
        if (self.totalData.length <= length) {
            [self.totalData appendData:data];
            
            if (self.totalData.length == length) {
                
                NSString *transmitString = [[NSString alloc] initWithData:self.totalData encoding:NSUTF8StringEncoding];
                [self clearAction:nil];
                self.ShowLabel.text = transmitString;
            }
        } else {
            [self clearAction:nil];
        }
    }
}

//发送数据，发送当前时间的秒数
-(BOOL)sendData:(NSTimer *)t {
    CBMutableCharacteristic *characteristic = t.userInfo;
    NSDateFormatter *dft = [[NSDateFormatter alloc]init];
    [dft setDateFormat:@"ss"];
    //    NSLog(@"%@",[dft stringFromDate:[NSDate date]]);
    //执行回应Central通知数据
    return  [self.baby.peripheralManager updateValue:[[dft stringFromDate:[NSDate date]] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:nil];
}
- (IBAction)clearAction:(id)sender {
    self.ShowLabel.text = nil;
    
    //NSMutableData 清空
    [self.totalData resetBytesInRange:NSMakeRange(0, [self.totalData length])];
    [self.totalData setLength:0];
}

//62-Find Car
//63-Unlock Car
//64-Lock Car
//65 - Open Window
//66 - Close Window
//67 - Car Status
- (void)showOperation:(NSString *)type{
    NSString *title = @"";
    switch ([type intValue]) {
        case 62:
            title = @"Find Car";
            break;
        case 63:
            title = @"Unlock Car";
            break;
        case 64:
            title = @"Lock Car";
            break;
        case 65:
            title = @"Window Turn On";
            break;
        case 66:
            title = @"Window Turn Off";
            break;
        case 67:
            title = @"Car Status";
            break;
        case 68:
            title = @"Fire";
            break;
        case 69:
            title = @"AirConditioner On";
            break;
        case 70:
            title = @"AirConditioner Off";
            break;
        case 71:
            title = @"Trunk Open";
            break;
        case 72:
            title = @"Air Purification";
            break;
        case 73:
            title = @"Sunroof Open";
            break;
        case 74:
            title = @"Sunroof Close";
            break;
        case 75:
            title = @"SeatHeating On";
            break;
        case 76:
            title = @"SeatHeating Off";
            break;
        default:
            break;
    }
    _ShowLabel.text = title;
    
}

- (NSMutableData *)totalData
{
    if (!_totalData) {
        _totalData = [NSMutableData data];
    }
    return _totalData;
}

@end
