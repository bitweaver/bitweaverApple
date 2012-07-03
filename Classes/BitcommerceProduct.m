//
//  BitcommerceProduct.m
//  PBPro API Demo
//
//  Created by Christian Fowler on 6/27/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

#import "BitcommerceProduct.h"

@implementation BitcommerceProduct

@synthesize productId;
@synthesize ratioId;
@synthesize typeClass;

+ (BitcommerceProduct *)productFromHash:(NSDictionary *)hash {
    
    BitcommerceProduct *newProduct = [[BitcommerceProduct alloc] init];
    [newProduct loadFromRemoteProperties:hash];
    
    return newProduct;
}

- (NSDictionary*)getAllPropertyMappings {  
    NSMutableDictionary *mappings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        @"productId",@"products_id",
        @"languageId",@"language_id",
        @"productsDescription",@"products_description",
        @"productsUrl",@"products_url",
        @"productsViewed",@"products_viewed",
        @"productsType",@"products_type",
        @"productsQuantity",@"products_quantity",
        @"productsModel",@"products_model",
        @"productsManufacturersModel",@"products_manufacturers_model",
        @"productsImage",@"products_image",
        @"productsPrice",@"products_price",
        @"productsCommission",@"products_commission",
        @"productsCogs",@"products_cogs",
        @"productsVirtual",@"products_virtual",
        @"productsDateAdded",@"products_date_added",
        @"productsLastModified",@"products_last_modified",
        @"productsDateAvailable",@"products_date_available",
        @"productsWeight",@"products_weight",
        @"productsStatus",@"products_status",
        @"productsTaxClassId",@"products_tax_class_id",
        @"manufacturersId",@"manufacturers_id",
        @"suppliersId",@"suppliers_id",
        @"productsBarcode",@"products_barcode",
        @"productsOrdered",@"products_ordered",
        @"productsQuantityOrderMin",@"products_quantity_order_min",
        @"productsQuantityOrderUnits",@"products_quantity_order_units",
        @"productsPricedByAttribute",@"products_priced_by_attribute",
        @"productIsFree",@"product_is_free",
        @"productIsCall",@"product_is_call",
        @"productsQuantityMixed",@"products_quantity_mixed",
        @"productIsAlwaysFreeShip",@"product_is_always_free_ship",
        @"productsQtyBoxStatus",@"products_qty_box_status",
        @"productsQuantityOrderMax",@"products_quantity_order_max",
        @"productsSortOrder",@"products_sort_order",
        @"productsDiscountType",@"products_discount_type",
        @"productsDiscountTypeFrom",@"products_discount_type_from",
        @"lowestPurchasePrice",@"lowest_purchase_price",
        @"masterCategoriesId",@"master_categories_id",
        @"productsMixedDiscountQty",@"products_mixed_discount_qty",
        @"metatagsTitleStatus",@"metatags_title_status",
        @"metatagsProductsNameStatus",@"metatags_products_name_status",
        @"metatagsModelStatus",@"metatags_model_status",
        @"metatagsPriceStatus",@"metatags_price_status",
        @"metatagsTitleTaglineStatus",@"metatags_title_tagline_status",
        @"relatedContentId",@"related_content_id",
        @"purchaseGroupId",@"purchase_group_id",
        @"reordersInterval",@"reorders_interval",
        @"reordersPending",@"reorders_pending",
        @"typeMasterType",@"type_master_type",
        @"allowAddToCart",@"allow_add_to_cart",
        @"defaultImage",@"default_image",
        @"infoPage",@"info_page",
        @"displayUrl",@"display_url",
        @"productsImageUrl",@"products_image_url",
        @"productsWeightKg",@"products_weight_kg",
        @"regularPrice",@"regular_price",
        @"displayPrice",@"display_price",
        @"typeClass",@"type_class",
        nil
        ];
    
    [mappings addEntriesFromDictionary:[super getAllPropertyMappings]];
    return mappings;
}

- (NSDictionary*)getSendablePropertyMappings {  
    NSMutableDictionary *mappings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     nil];  
    [mappings addEntriesFromDictionary:[super getSendablePropertyMappings]];
    return mappings;
}  

- (BOOL)isValid {
    return productId != nil;
}


@end
