//
//  MCOAbstractMessageRendererCallback.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCOAbstractMessageRendererCallback.h"

#import "MCOHTMLRendererDelegate.h"
#import "MCOHTMLRendererIMAPDelegate.h"
#import "MCOUtils.h"

using namespace mailcore;

MCOAbstractMessageRendererCallback::MCOAbstractMessageRendererCallback(MCOAbstractMessage * message, id <MCOHTMLRendererDelegate> rendererDelegate,
                                   id <MCOHTMLRendererIMAPDelegate> rendererIMAPDelegate)
{
    mMessage = message;
    mRendererDelegate = rendererDelegate;
    mIMAPDelegate = rendererIMAPDelegate;
}

bool MCOAbstractMessageRendererCallback::canPreviewPart(AbstractPart * part)
{
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:canPreviewPart:)]) {
        return [mRendererDelegate abstractMessage:mMessage canPreviewPart:MCO_TO_OBJC(part)];
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:canPreviewPart:)]) {
        return [mRendererDelegate MCOAbstractMessage:mMessage canPreviewPart:MCO_TO_OBJC(part)];
    }
    return HTMLRendererTemplateCallback::canPreviewPart(part);
}

bool MCOAbstractMessageRendererCallback::shouldShowPart(AbstractPart * part)
{
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:shouldShowPart:)]) {
        return [mRendererDelegate abstractMessage:mMessage shouldShowPart:MCO_TO_OBJC(part)];
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:shouldShowPart:)]) {
        return [mRendererDelegate MCOAbstractMessage:mMessage shouldShowPart:MCO_TO_OBJC(part)];
    }
    return HTMLRendererTemplateCallback::shouldShowPart(part);
}

HashMap * MCOAbstractMessageRendererCallback::templateValuesForHeader(MessageHeader * header)
{
    HashMap * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:templateValuesForHeader:)]) {
        result = MCO_FROM_OBJC(HashMap, [mRendererDelegate abstractMessage:mMessage templateValuesForHeader:MCO_TO_OBJC(header)]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:templateValuesForHeader:)]) {
        result = MCO_FROM_OBJC(HashMap, [mRendererDelegate MCOAbstractMessage:mMessage templateValuesForHeader:MCO_TO_OBJC(header)]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::templateValuesForHeader(header);
    }
    return result;
}

HashMap * MCOAbstractMessageRendererCallback::templateValuesForPart(AbstractPart * part)
{
    HashMap * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:templateValuesForPart:)]) {
        result = MCO_FROM_OBJC(HashMap, [mRendererDelegate abstractMessage:mMessage templateValuesForPart:MCO_TO_OBJC(part)]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:templateValuesForPart:)]) {
        result = MCO_FROM_OBJC(HashMap, [mRendererDelegate MCOAbstractMessage:mMessage templateValuesForPart:MCO_TO_OBJC(part)]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::templateValuesForPart(part);
    }
    return result;
}

String * MCOAbstractMessageRendererCallback::templateForMainHeader(MessageHeader * header)
{
    String * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:templateForMainHeader:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate abstractMessage:mMessage templateForMainHeader:MCO_TO_OBJC(header)]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:templateForMainHeader:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate MCOAbstractMessage:mMessage templateForMainHeader:MCO_TO_OBJC(header)]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::templateForMainHeader(header);
    }
    return result;
}

String * MCOAbstractMessageRendererCallback::templateForImage(AbstractPart * part)
{
    String * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:templateForImage:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate abstractMessage:mMessage templateForImage:MCO_TO_OBJC(part)]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:templateForImage:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate MCOAbstractMessage:mMessage templateForImage:MCO_TO_OBJC(part)]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::templateForImage(part);
    }
    return result;
}

String * MCOAbstractMessageRendererCallback::templateForAttachment(AbstractPart * part)
{
    String * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:templateForAttachment:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate abstractMessage:mMessage templateForAttachment:MCO_TO_OBJC(part)]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:templateForAttachment:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate MCOAbstractMessage:mMessage templateForAttachment:MCO_TO_OBJC(part)]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::templateForAttachment(part);
    }
    return result;
}

String * MCOAbstractMessageRendererCallback::templateForMessage(AbstractMessage * message)
{
    String * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage_templateForMessage:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate abstractMessage_templateForMessage:mMessage]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage_templateForMessage:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate MCOAbstractMessage_templateForMessage:mMessage]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::templateForMessage(message);
    }
    return result;
}

String * MCOAbstractMessageRendererCallback::templateForEmbeddedMessage(AbstractMessagePart * part)
{
    String * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:templateForEmbeddedMessage:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate abstractMessage:mMessage templateForEmbeddedMessage:MCO_TO_OBJC(part)]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:templateForEmbeddedMessage:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate MCOAbstractMessage:mMessage templateForEmbeddedMessage:MCO_TO_OBJC(part)]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::templateForEmbeddedMessage(part);
    }
    return result;
}

String * MCOAbstractMessageRendererCallback::templateForEmbeddedMessageHeader(MessageHeader * header)
{
    String * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:templateForEmbeddedMessageHeader:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate abstractMessage:mMessage templateForEmbeddedMessageHeader:MCO_TO_OBJC(header)]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:templateForEmbeddedMessageHeader:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate MCOAbstractMessage:mMessage templateForEmbeddedMessageHeader:MCO_TO_OBJC(header)]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::templateForEmbeddedMessageHeader(header);
    }
    return result;
}

String * MCOAbstractMessageRendererCallback::templateForAttachmentSeparator()
{
    String * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage_templateForAttachmentSeparator:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate abstractMessage_templateForAttachmentSeparator:mMessage]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage_templateForAttachmentSeparator:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate MCOAbstractMessage_templateForAttachmentSeparator:mMessage]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::templateForAttachmentSeparator();
    }
    return result;
}

String * MCOAbstractMessageRendererCallback::cleanHTMLForPart(String * html)
{
    String * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:cleanHTMLForPart:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate abstractMessage:mMessage cleanHTMLForPart:MCO_TO_OBJC(html)]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:cleanHTMLForPart:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate MCOAbstractMessage:mMessage cleanHTMLForPart:MCO_TO_OBJC(html)]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::cleanHTMLForPart(html);
    }
    return result;
}

String * MCOAbstractMessageRendererCallback::filterHTMLForPart(String * html)
{
    String * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:filterHTMLForPart:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate abstractMessage:mMessage filterHTMLForPart:MCO_TO_OBJC(html)]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:filterHTMLForPart:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate MCOAbstractMessage:mMessage filterHTMLForPart:MCO_TO_OBJC(html)]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::filterHTMLForPart(html);
    }
    return result;
}

String * MCOAbstractMessageRendererCallback::filterHTMLForMessage(String * html)
{
    String * result = NULL;
    if ([mRendererDelegate respondsToSelector:@selector(abstractMessage:filterHTMLForMessage:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate abstractMessage:mMessage filterHTMLForMessage:MCO_TO_OBJC(html)]);
    }
    else if ([mRendererDelegate respondsToSelector:@selector(MCOAbstractMessage:filterHTMLForMessage:)]) {
        result = MCO_FROM_OBJC(String, [mRendererDelegate MCOAbstractMessage:mMessage filterHTMLForMessage:MCO_TO_OBJC(html)]);
    }
    if (result == NULL) {
        result = HTMLRendererTemplateCallback::filterHTMLForMessage(html);
    }
    return result;
}

Data * MCOAbstractMessageRendererCallback::dataForIMAPPart(String * folder, IMAPPart * part)
{
    Data * result = NULL;
    if ([mIMAPDelegate respondsToSelector:@selector(abstractMessage:dataForIMAPPart:folder:)]) {
        result = [[mIMAPDelegate abstractMessage:mMessage dataForIMAPPart:MCO_TO_OBJC(part) folder:MCO_TO_OBJC(folder)] mco_mcData];
    }
    else if ([mIMAPDelegate respondsToSelector:@selector(MCOAbstractMessage:dataForIMAPPart:folder:)]) {
        result = [[mIMAPDelegate MCOAbstractMessage:mMessage dataForIMAPPart:MCO_TO_OBJC(part) folder:MCO_TO_OBJC(folder)] mco_mcData];
    }
    return result;
}

void MCOAbstractMessageRendererCallback::prefetchAttachmentIMAPPart(String * folder, IMAPPart * part)
{
    if ([mIMAPDelegate respondsToSelector:@selector(abstractMessage:prefetchAttachmentIMAPPart:folder:)]) {
        [mIMAPDelegate abstractMessage:mMessage prefetchAttachmentIMAPPart:MCO_TO_OBJC(part) folder:MCO_TO_OBJC(folder)];
    }
    else if ([mIMAPDelegate respondsToSelector:@selector(MCOAbstractMessage:prefetchAttachmentIMAPPart:folder:)]) {
        [mIMAPDelegate MCOAbstractMessage:mMessage prefetchAttachmentIMAPPart:MCO_TO_OBJC(part) folder:MCO_TO_OBJC(folder)];
    }
}

void MCOAbstractMessageRendererCallback::prefetchImageIMAPPart(String * folder, IMAPPart * part)
{
    if ([mIMAPDelegate respondsToSelector:@selector(abstractMessage:prefetchImageIMAPPart:folder:)]) {
        [mIMAPDelegate abstractMessage:mMessage prefetchImageIMAPPart:MCO_TO_OBJC(part) folder:MCO_TO_OBJC(folder)];
    }
    else if ([mIMAPDelegate respondsToSelector:@selector(MCOAbstractMessage:prefetchImageIMAPPart:folder:)]) {
        [mIMAPDelegate MCOAbstractMessage:mMessage prefetchImageIMAPPart:MCO_TO_OBJC(part) folder:MCO_TO_OBJC(folder)];
    }
}
