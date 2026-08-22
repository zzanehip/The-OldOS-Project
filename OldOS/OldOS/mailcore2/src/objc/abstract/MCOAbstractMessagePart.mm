//
//  MCOAbstractMessagePart.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/10/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOAbstractMessagePart.h"

#import "NSObject+MCO.h"
#import "MCOMessageHeader.h"

#include "MCAbstractMessagePart.h"
#include "MCMessageHeader.h"

@implementation MCOAbstractMessagePart

#define nativeType mailcore::AbstractMessagePart

MCO_OBJC_SYNTHESIZE(MessageHeader, setHeader, header)
MCO_OBJC_SYNTHESIZE(AbstractMessagePart, setMainPart, mainPart)

@end
