//
//  SPModelTable.h
//  PersistedModel
//
//  Created by Metin Güler on 23/07/2017.
//  Copyright © 2017 Metin Güler. All rights reserved.
//

#import "SPModel.h"
#import <Foundation/Foundation.h>

@interface SPModelTable : SPModel

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *createSql;

@end
