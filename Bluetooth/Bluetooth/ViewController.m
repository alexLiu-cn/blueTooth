//
//  ViewController.m
//  Bluetooth
//
//  Created by apple on 8/30/16.
//  Copyright © 2016 bingo. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BGUUID.h"

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
//发现管理蓝牙的管理类
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *UUID;
@property (weak, nonatomic) IBOutlet UILabel *charact;
@property (weak, nonatomic) IBOutlet UILabel *charectCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // nil 表示主队列
    // 实例化后触发 centralManagerDidUpdateState , 检查蓝牙硬件
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    
}

//蓝牙硬件状态改变时触发
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"蓝牙没有打开");
        return;
    }
    NSLog(@"蓝牙打开成功");
    //扫描外部设备
    /*================= 扫描外部设备 =================*/
    //    CBUUID *readServiceID = [CBUUID UUIDWithString:HandleUUIDService];
    //发现设备后会触发代理
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    
}
//发现外部设备后触发
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    //必须强引用设备
    self.peripheral = peripheral;
    NSLog(@"%@",peripheral.name);
    
    if ([peripheral.name isEqualToString:@"MI"]) {
        
        self.peripheral.delegate = self;
        // 连接外部设备, 如果成功会触发didConnectPeripheral
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
    
    
}
//链接设备成功调用
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"链接成功");
    //找到服务
    NSLog(@"%@",peripheral.services);
    //需要发现服务才能使用
    //    CBUUID *serviceID = [CBUUID UUIDWithString:HandleUUIDService];
    [peripheral discoverServices:nil];
}
//连接失败时调用
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"连接失败");
    
}
#pragma mark ---- 外设代理
//发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    if (error) {
        NSLog(@"发现服务失败%@",error);
    }
    NSLog(@"发现服务%@",peripheral.services);
    
    //    CBUUID *serviceID = [CBUUID UUIDWithString:HandleUUIDService];
    //    CBUUID *charID = [CBUUID UUIDWithString:HandleUUIDReadChar];
    for (CBService *service in peripheral.services) {
        ////        if ([service.UUID isEqual:serviceID]) {
        //            //需发现特征(获得步数服务)发现特征
        //            [peripheral discoverCharacteristics:@[charID] forService:service];
        //            return;
        ////        }
        CBUUID *notifyUUID = [CBUUID UUIDWithString:HandleUUIDReadChar];
        [peripheral discoverCharacteristics:@[notifyUUID] forService:service];
    }
    
}
//跟新通知数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (error) {
        NSLog(@"订阅特征值出错%@",error);
        return;
    }
    NSLog(@"%@",characteristic);
    
    [peripheral discoverDescriptorsForCharacteristic:characteristic];   //结果在代理里面
    
    [peripheral readValueForCharacteristic:characteristic];   //结果在代理里面
    
    
    
}


// 从服务当中找到特征时触发
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    self.UUID.text = [NSString stringWithFormat:@"%@",service.UUID];
    //打印特征
    NSLog(@"找到特征%@",service.characteristics);
    //打印数量
    NSLog(@"%zd",service.characteristics.count);
    self.charectCount.text = [NSString stringWithFormat:@"%zd",service.characteristics.count];
    CBUUID *charID = [CBUUID UUIDWithString:HandleUUIDReadChar];
    for (CBCharacteristic *charac in service.characteristics) {
        if ([charac.UUID isEqual:charID]) {
            //读取特征数据
            //            [peripheral readValueForCharacteristic:charac];
            [peripheral setNotifyValue:YES forCharacteristic:charac];
            self.charact.text = [NSString stringWithFormat:@"%@",charID];
        }
    }
}
//更新了特征的值获得
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error{
    if (error) {
        NSLog(@"读取特征出错了");
        return;
    }
    
    NSData *data = characteristic.value;
    //接受的内容
    //    NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //
    int i;
    [data getBytes:&i length:sizeof(i)];
    NSString *str = [NSString stringWithFormat:@"%d",i];
    _label.text = str;
    NSLog(@"读取到特征的值 : %@", str);
    
}


@end
