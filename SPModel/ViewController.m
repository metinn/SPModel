//
//  ViewController.m
//  SPModel
//
//  Created by Metin Güler on 23/07/2017.
//  Copyright © 2017 com.metinguler. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "Car.h"
#import "Hash.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    Person *p = [Person new];
//    p.name = @"Mehmet";
//    p.surname = @"Baklaci";
//    p.number = @"5331133217";
//    p.age = 29;
//    p.money = 3000;
//    
//    Car *a = [Car new];
//    a.marka = @"Volkswagen";
//    a.model = @"Polo";
//    a.yil = 2001;
//    a.tuketim = 5.2;
//    a.km = [NSNumber numberWithInt:148000];
//    
//    p.car = a;
//    
//    [p save];
//    
//    NSArray *persons = [Person getAll];
//    for (Person *item in persons) {
//        NSLog(@"Person -> %li %@ %@ %lld %li %@", item.spid, item.name, item.surname, item.money, item.age, item.number);
//        NSLog(@"Car -> %li %@ %@ %lf %i %@", item.car.spid, item.car.marka, item.car.model, item.car.tuketim, item.car.yil, item.car.km);
//    }
//    
//    
//    Class c = NSClassFromString(@"Car");
//    Class su = [c superclass];
//    Class su2 = [su superclass];
//    
//    NSLog(@"%@ %@ %@", NSStringFromClass(c), NSStringFromClass(su), NSStringFromClass(su2));
//    
//    
//    a = [Car new];
//    a.marka = @"BMW";
//    a.model = @"320d";
//    a.yil = 2009;
//    a.tuketim = 7.2;
//    a.km = [NSNumber numberWithInt:133600];
//    
//    [a save];
//    
//    a = [Car new];
//    a.marka = @"Tesla";
//    a.model = @"Model X";
//    a.yil = 2017;
//    a.tuketim = 0.0;
//    a.km = [NSNumber numberWithInt:600];
//    
//    [a save];
//    
//    a = [Car new];
//    a.marka = @"Skoda";
//    a.model = @"Fabia";
//    a.yil = 2009;
//    a.tuketim = 5.7;
//    a.km = [NSNumber numberWithInt:92100];
//    
//    [a save];
//    
//    
//    NSArray *cars = [Car getAll];
//    for (Car *item in cars) {
//        NSLog(@"%li %@ %@ %lf %i %@", item.spid, item.marka, item.model, item.tuketim, item.yil, item.km);
//    }
//    NSLog(@"---------");
//    cars = [Car getAllWithOffset:1
//                       withLimit:2];
//    for (Car *item in cars) {
//        NSLog(@"%@ %@ %lf %i %@", item.marka, item.model, item.tuketim, item.yil, item.km);
//    }
//    NSLog(@"---------");
//    cars = [Car getAllWithQuery:@"yil > 2009"
//                         values:@[]];
//    for (Car *item in cars) {
//        NSLog(@"%@ %@ %lf %i %@", item.marka, item.model, item.tuketim, item.yil, item.km);
//    }
//    NSLog(@"---------");
//    cars = [Car getAllWithQuery:@"yil > 2009"
//                         values:@[]
//                     withOffset:1
//                      withLimit:2];
//    for (Car *item in cars) {
//        NSLog(@"%@ %@ %lf %i %@", item.marka, item.model, item.tuketim, item.yil, item.km);
//        
//        [item deleteObject];
//        
//        item.marka = @"TESLA";
//        item.km = [NSNumber numberWithInt:[item.km intValue] +1];
//        [item update];
//    }
//    
//    Hash *h = [Hash new];
//    h.hashString = @"asjdbajshndjasd";;
//    [h save];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
