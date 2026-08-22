//
//  MCOAbstractMultipart.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/10/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOAbstractMultipart.h"

#include "MCAbstractMultipart.h"

#import "NSObject+MCO.h"

@implementation MCOAbstractMultipart

#define nativeType mailcore::AbstractMultipart

MCO_OBJC_SYNTHESIZE_ARRAY(setParts, parts)

@end
