# SPModel
> This repo is under development and experimenting new ways. Not production ready, yet.

SPModel will save you time by creating database and generating basic sql's automatically. 

Usage is very simple:

1- Inherit your models from SPModel

```Obj-c
#import "SPModel.h"

@interface Car : SPModel

@property (nonatomic, strong) NSString *brand;
@property (nonatomic, strong) NSString *model;
@property (nonatomic) int hp;
@property (nonatomic) double engine;

@end

```

2- Save it when you need

```Obj-c
Car *c = [Car new];
c.brand = Volkswagen;
c.model = Golf;
c.hp = 110;
c.engine = 1.6;

[c save];
```

3- Get objects when you need

```Obj-c
NSArray *cars = [Car getAllWithQuery:@"hp > ?"
                              values:@[@100]
                          withOffset:10
                           withLimit:20];
for (Car *item in cars) {
		...
}
```

## What Happened in Sqlite Side?

1. When save method called there was no db. So SPModel created 'spmodel.db' in documents.
2. Also there is no Sql Table to save Car object. Then SPModel created o proper table for Car class. Table name is class name (Car), and column names are property names.
3. Insert sql generated and model saved to db.
4. In the 'getAllWithQuery' method query is sql where query.

## There is More

If you will create Person class that have Car class as property, SPModel will handle connection between tables automatically.

```Obj-c
#import "SPModel.h"
#import "Car.h"

@interface Person : SPModel
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *surname;

@property (nonatomic) Car *car;
@end
```

 * When you create a person object and save it, the car and person object will saved to their table and a foreign key will be setted up.

 * When you get Person objects car property will automatically retrived inside Person object.

 ### Other Things
 * All methods are thread safe.
 * SPModel uses FMDB for sqlite managment
 * Because Sqlite scheme naming based on class names and properties, you already know the scheme. Direct SQL access will be very easy when you need.

## Road Map
 
 * More solid codebase (In Progress...)
 * Automatically handling new properties
 * Implementing proper way to migration
 * SPState class that stores only one object
 * Event Manager, publishing and listening to events, generally changes.
