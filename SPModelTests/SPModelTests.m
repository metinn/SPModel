//
//  SPModelTests.m
//  SPModelTests
//
//  Created by Metin Guler on 31/07/2017.
//  Copyright © 2017 com.metinguler. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SPModel.h"
#import "SPModelDB.h"
#import "FMDB.h"

#import "Car.h"
#import "Person.h"

@interface SPModelTests : XCTestCase

@end

@implementation SPModelTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    //    NSString *dbpath = [SPModelDB getSPModelDBPath];
    //    [[NSFileManager defaultManager] removeItemAtPath:dbpath error:nil];
    
    [SPModelDB.shared.fmdbq inDatabase:^(FMDatabase * _Nonnull db) {
        [db executeUpdate:@"delete from Car"];
        [db executeUpdate:@"delete from Person"];
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSaveAndGet {
    srand48(time(0));
    
    Car *a = [Car new];
    a.marka = [self createRandomStringWithLength:8];
    a.model = [self createRandomStringWithLength:10];
    a.yil = arc4random() % 2020;
    a.tuketim = drand48() * 20;
    a.km = [NSNumber numberWithInt:arc4random() % 800000];
    
    [a save];
    
    Car *a2 = (Car*)[Car getObjectWithID:a.spid];
    XCTAssert([a2.marka isEqualToString:a.marka]);
    XCTAssert([a2.model isEqualToString:a.model]);
    XCTAssert(a2.yil == a.yil);
    XCTAssert(a2.tuketim == a.tuketim);
    XCTAssert([a2.km compare:a.km]);
}

- (void)testUpdate {
    Car *a = [Car new];
    a.marka = [self createRandomStringWithLength:8];
    a.model = [self createRandomStringWithLength:10];
    a.yil = arc4random() % 2020;
    a.tuketim = drand48() * 20;
    a.km = [NSNumber numberWithInt:arc4random() % 800000];
    
    [a save];
    
    Car *a2 = (Car*)[Car getObjectWithID:a.spid];
    a2.marka = [self createRandomStringWithLength:10];
    [a2 update];
    
    Car *a3 = (Car*)[Car getObjectWithID:a.spid];
    XCTAssert([a2.marka isEqualToString:a3.marka]);
}

- (void)testRelationalObject {
    srand48(time(0));
    
    Person *p = [Person new];
    p.name = [self createRandomStringWithLength:8];
    p.surname = [self createRandomStringWithLength:10];
    p.number = [self createRandomStringWithLength:11];
    p.age = arc4random() % 100;
    p.money = arc4random() % 20000;
    
    Car *a = [Car new];
    a.marka = [self createRandomStringWithLength:8];
    a.model = [self createRandomStringWithLength:10];
    a.yil = arc4random() % 2020;
    a.tuketim = drand48() * 20;
    a.km = [NSNumber numberWithInt:arc4random() % 800000];
    
    p.car = a;
    
    [p save];
    
    XCTAssertNotEqual(p.spid, 0, @"id not set");
    
    Person *p2 = (Person*)[Person getObjectWithID:p.spid];
    XCTAssert([p2.name isEqualToString:p.name]);
    XCTAssert([p2.surname isEqualToString:p.surname]);
    XCTAssert([p2.number isEqualToString:p.number]);
    XCTAssert(p2.age == p2.age);
    XCTAssert(p2.money = 3000);
    
    XCTAssert([p2.car.marka isEqualToString:p.car.marka]);
    XCTAssert([p2.car.model isEqualToString:p.car.model]);
    XCTAssert(p2.car.yil == p.car.yil);
    XCTAssert(p2.car.tuketim == p.car.tuketim);
    XCTAssert([p2.car.km compare:p.car.km]);
}

- (void)testRelationalObjectUpdate {
    srand48(time(0));
    
    Person *p = [Person new];
    p.name = [self createRandomStringWithLength:8];
    p.surname = [self createRandomStringWithLength:10];
    p.number = [self createRandomStringWithLength:11];
    p.age = arc4random() % 100;
    p.money = arc4random() % 20000;
    
    Car *a = [Car new];
    a.marka = [self createRandomStringWithLength:8];
    a.model = [self createRandomStringWithLength:10];
    a.yil = arc4random() % 2020;
    a.tuketim = drand48() * 20;
    a.km = [NSNumber numberWithInt:arc4random() % 800000];
    
    p.car = a;
    [p save];
    
    XCTAssertNotEqual(p.spid, 0, @"id not set");
    
    Person *p2 = (Person*)[Person getObjectWithID:p.spid];
    p2.car.marka = [self createRandomStringWithLength:8];
    [p2 update];
    
    Person *p3 = (Person*)[Person getObjectWithID:p.spid];
    XCTAssert([p3.car.marka isEqualToString:p2.car.marka]);
}

- (NSString *)createRandomStringWithLength:(int)len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i = 0; i < len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}

- (void)testBulkInsert {
    NSMutableArray *cars = [NSMutableArray new];
    
    Car *a = [Car new];
    a.marka = @"BMW";
    a.model = @"320d";
    a.yil = 2009;
    a.tuketim = 7.2;
    a.km = [NSNumber numberWithInt:133600];
    
    [cars addObject:a];
    
    a = [Car new];
    a.marka = @"Tesla";
    a.model = @"Model X";
    a.yil = 2017;
    a.tuketim = 0.0;
    a.km = [NSNumber numberWithInt:600];
    
    [cars addObject:a];
    
    a = [Car new];
    a.marka = @"Skoda";
    a.model = @"Fabia";
    a.yil = 2009;
    a.tuketim = 5.7;
    a.km = [NSNumber numberWithInt:92100];
    
    [cars addObject:a];
    
    [self measureBlock:^{
        [Car bulkInsert:cars];
    }];
}


@end
