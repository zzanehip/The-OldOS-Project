//
//  MCOAbstractPart.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/10/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOAbstractPart.h"

#include "MCAbstractPart.h"
#include "MCAbstractMessage.h"

#import "NSString+MCO.h"
#import "NSObject+MCO.h"
#import "NSData+MCO.h"

@implementation MCOAbstractPart {
    mailcore::AbstractPart * _part;
}

#define nativeType mailcore::AbstractPart

- (mailcore::Object *) mco_mcObject
{
    return _part;
}

- (instancetype) init
{
    self = [self initWithMCPart:NULL];
    MCAssert(0);
    return nil;
}

- (instancetype) initWithMCPart:(mailcore::AbstractPart *)part
{
    self = [super init];
    
    MC_SAFE_RETAIN(part);
    _part = part;
    
    return self;
}

- (void) dealloc
{
    MC_SAFE_RELEASE(_part);
    [super dealloc];
}

- (id) copyWithZone:(NSZone *)zone
{
    nativeType * nativeObject = (nativeType *) [self mco_mcObject]->copy();
    id result = [[self class] mco_objectWithMCObject:nativeObject];
    MC_SAFE_RELEASE(nativeObject);
    return [result retain];
}

- (NSString *) description
{
    return MCO_OBJC_BRIDGE_GET(description);
}

MCO_OBJC_SYNTHESIZE_SCALAR(MCOPartType, mailcore::PartType, setPartType, partType)

MCO_OBJC_SYNTHESIZE_STRING(setFilename, filename)
MCO_OBJC_SYNTHESIZE_STRING(setMimeType, mimeType)
MCO_OBJC_SYNTHESIZE_STRING(setCharset, charset)
MCO_OBJC_SYNTHESIZE_STRING(setUniqueID, uniqueID)
MCO_OBJC_SYNTHESIZE_STRING(setContentID, contentID)
MCO_OBJC_SYNTHESIZE_STRING(setContentLocation, contentLocation)
MCO_OBJC_SYNTHESIZE_STRING(setContentDescription, contentDescription)
MCO_OBJC_SYNTHESIZE_BOOL(setInlineAttachment, isInlineAttachment)
MCO_OBJC_SYNTHESIZE_BOOL(setAttachment, isAttachment)

- (MCOAbstractPart *) partForContentID:(NSString *)contentID
{
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->partForContentID([contentID mco_mcString]));
}

- (MCOAbstractPart *) partForUniqueID:(NSString *)uniqueID
{
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->partForUniqueID([uniqueID mco_mcString]));
}

- (NSString *) decodedStringForData:(NSData *)data
{
    return [NSString mco_stringWithMCString:MCO_NATIVE_INSTANCE->decodedStringForData([data mco_mcData])];
}

- (void) setContentTypeParameterValue:(NSString *)value forName:(NSString *)name
{
    MCO_NATIVE_INSTANCE->setContentTypeParameter(MCO_FROM_OBJC(mailcore::String, name), MCO_FROM_OBJC(mailcore::String, value));
}

- (NSString *) contentTypeParameterValueForName:(NSString *)name
{
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->contentTypeParameterValueForName((MCO_FROM_OBJC(mailcore::String, name))));
}
- (void) removeContentTypeParameterForName:(NSString *)name
{
    MCO_NATIVE_INSTANCE->removeContentTypeParameter(MCO_FROM_OBJC(mailcore::String, name));
}

- (NSArray<NSString *> *) allContentTypeParametersNames
{
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->allContentTypeParametersNames());
}

@end
