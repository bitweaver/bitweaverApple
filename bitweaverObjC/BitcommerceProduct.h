//
//  BitcommerceProduct.h
//  PBPro API Demo
//
//  Created by Christian Fowler on 6/27/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

#import "BitweaverRestObject.h"

@interface BitcommerceProduct : BitweaverRestObject

// REST properties
@property (nonatomic,strong) NSNumber *productId;
@property (nonatomic,strong) NSString *productType;
@property (nonatomic) BOOL *enabled;

+ (BitcommerceProduct *)productFromHash:(NSDictionary *)hash;

@end
