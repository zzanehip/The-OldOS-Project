//
//  MCOMessageBuilder.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOMessageBuilder.h"

#include "MCRFC822.h"

#import "MCOUtils.h"
#import "MCOAbstractMessageRendererCallback.h"

@implementation MCOMessageBuilder

#define nativeType mailcore::MessageBuilder

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

- (instancetype) init
{
    mailcore::MessageBuilder * message = new mailcore::MessageBuilder();
    self = [super initWithMCMessage:message];
    MC_SAFE_RELEASE(message);
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    nativeType * nativeObject = (nativeType *) [self mco_mcObject]->copy();
    id result = [[self class] mco_objectWithMCObject:nativeObject];
    MC_SAFE_RELEASE(nativeObject);
    return [result retain];
}

+ (id) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::MessageBuilder * msg = (mailcore::MessageBuilder *) object;
    return [[[self alloc] initWithMCMessage:msg] autorelease];
}

MCO_OBJC_SYNTHESIZE_STRING(setHTMLBody, htmlBody)
MCO_OBJC_SYNTHESIZE_STRING(setTextBody, textBody)
MCO_OBJC_SYNTHESIZE_ARRAY(setAttachments, attachments)
MCO_OBJC_SYNTHESIZE_ARRAY(setRelatedAttachments, relatedAttachments)
MCO_OBJC_SYNTHESIZE_STRING(setBoundaryPrefix, boundaryPrefix)

- (void) addAttachment:(MCOAttachment *)attachment
{
    MCO_NATIVE_INSTANCE->addAttachment(MCO_FROM_OBJC(mailcore::Attachment, attachment));
}

- (void) addRelatedAttachment:(MCOAttachment *)attachment
{
    MCO_NATIVE_INSTANCE->addRelatedAttachment(MCO_FROM_OBJC(mailcore::Attachment, attachment));
}

- (NSData *) data
{
    return MCO_OBJC_BRIDGE_GET(data);
}

- (NSData *) dataForEncryption
{
    return MCO_OBJC_BRIDGE_GET(dataForEncryption);
}

- (BOOL) writeToFile:(NSString *)filename error:(NSError **)error
{
    mailcore::ErrorCode errorCode = MCO_NATIVE_INSTANCE->writeToFile(MCO_FROM_OBJC(mailcore::String, filename));
    if (error) {
        *error = [NSError mco_errorWithErrorCode:errorCode];
    }
    return errorCode == mailcore::ErrorNone;
}

- (NSString *) htmlRenderingWithDelegate:(id <MCOHTMLRendererDelegate>)delegate
{
    MCOAbstractMessageRendererCallback * htmlRenderCallback = new MCOAbstractMessageRendererCallback(self, delegate, NULL);
    NSString * result = MCO_TO_OBJC(MCO_NATIVE_INSTANCE->htmlRendering(htmlRenderCallback));
    htmlRenderCallback->release();
    
    return result;
}

- (NSString *) htmlBodyRendering
{
    return MCO_OBJC_BRIDGE_GET(htmlBodyRendering);
}

- (NSString *) plainTextRendering
{
    return MCO_OBJC_BRIDGE_GET(plainTextRendering);
}

- (NSString *) plainTextBodyRendering
{
    return [self plainTextBodyRenderingAndStripWhitespace:YES];
}

- (NSString *) plainTextBodyRenderingAndStripWhitespace:(BOOL)stripWhitespace
{
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->plainTextBodyRendering(stripWhitespace));
}

- (NSData *) openPGPSignedMessageDataWithSignatureData:(NSData *)signature
{
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->openPGPSignedMessageDataWithSignatureData(MCO_FROM_OBJC(mailcore::Data, signature)));
}

- (NSData *) openPGPEncryptedMessageDataWithEncryptedData:(NSData *)encryptedData
{
    return MCO_TO_OBJC(MCO_NATIVE_INSTANCE->openPGPEncryptedMessageDataWithEncryptedData(MCO_FROM_OBJC(mailcore::Data, encryptedData)));
}

- (void) _setBoundaries:(NSArray *)boundaries
{
    MCO_NATIVE_INSTANCE->setBoundaries(MCO_FROM_OBJC(mailcore::Array, boundaries));
}

@end
