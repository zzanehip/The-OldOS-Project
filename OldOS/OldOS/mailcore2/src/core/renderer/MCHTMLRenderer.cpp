//
//  MCHTMLRenderer.cpp
//  testUI
//
//  Created by DINH Viêt Hoà on 1/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCHTMLRenderer.h"

#include <ctemplate/template.h>
#include "MCAddressDisplay.h"
#include "MCDateFormatter.h"
#include "MCSizeFormatter.h"
#include "MCHTMLRendererCallback.h"

using namespace mailcore;

class HTMLRendererIMAPDummyCallback : public HTMLRendererIMAPCallback, public HTMLRendererRFC822Callback {
private:
    Array *mRequiredParts;
    
public:
    HTMLRendererIMAPDummyCallback()
    {
        mRequiredParts = Array::array();
        mRequiredParts->retain();
    }
    
    virtual ~HTMLRendererIMAPDummyCallback()
    {
        MC_SAFE_RELEASE(mRequiredParts);
    }
    
    
    virtual Data * dataForIMAPPart(String * folder, IMAPPart * part)
    {
        mRequiredParts->addObject(part);
        return Data::data();
    }
    
    Array * requiredParts()
    {
        return mRequiredParts;
    }

    virtual Data * dataForRFC822Part(String * folder, Attachment * part)
    {
        mRequiredParts->addObject(part);
        return Data::data();
    }

};

enum {
    RENDER_STATE_NONE,
    RENDER_STATE_HAD_ATTACHMENT,
    RENDER_STATE_HAD_ATTACHMENT_THEN_TEXT,
};

struct htmlRendererContext {
    HTMLRendererIMAPCallback * imapDataCallback;
    HTMLRendererRFC822Callback * rfc822DataCallback;
    HTMLRendererTemplateCallback * htmlCallback;
    int firstRendered;
    String * folder;
    int state;
    // pass == 0 -> render only text parts,
    // pass == 1 -> render only attachments.
    int pass;
    bool hasMixedTextAndAttachments;
    bool firstAttachment;
    bool hasTextPart;
    Array * relatedAttachments;
    Array * attachments;
};

class DefaultTemplateCallback : public Object, public HTMLRendererTemplateCallback {
};

static bool partContainsMimeType(AbstractPart * part, String * mimeType);
static bool singlePartContainsMimeType(AbstractPart * part, String * mimeType);
static bool multipartContainsMimeType(AbstractMultipart * part, String * mimeType);
static bool messagePartContainsMimeType(AbstractMessagePart * part, String * mimeType);

static String * htmlForAbstractPart(AbstractPart * part, htmlRendererContext * context);

static String * renderTemplate(String * templateContent, HashMap * values);

static String * htmlForAbstractMessage(String * folder, AbstractMessage * message,
                                       HTMLRendererIMAPCallback * dataCallback,
                                       HTMLRendererRFC822Callback * rfc822DataCallback,
                                       HTMLRendererTemplateCallback * htmlCallback,
                                       Array * attachments,
                                       Array * relatedAttachments);

static bool isTextPart(AbstractPart * part, htmlRendererContext * context)
{
    String * mimeType = part->mimeType()->lowercaseString();
    MCAssert(mimeType != NULL);
    
    if (!part->isInlineAttachment()) {
        if (part->isAttachment() || ((part->filename() != NULL) && context->firstRendered)) {
            return false;
        }
    }
    
    if (mimeType->isEqual(MCSTR("text/plain"))) {
        return true;
    }
    else if (mimeType->isEqual(MCSTR("text/html"))) {
        return true;
    }
    else {
        return false;
    }
}


static AbstractPart * preferredPartInMultipartAlternative(AbstractMultipart * part)
{
    int htmlPart = -1;
    int textPart = -1;
    
    for(unsigned int i = 0 ; i < part->parts()->count() ; i ++) {
        AbstractPart * subpart = (AbstractPart *) part->parts()->objectAtIndex(i);
        if (partContainsMimeType(subpart, MCSTR("text/html"))) {
            htmlPart = i;
        }
        else if (partContainsMimeType(subpart, MCSTR("text/plain"))) {
            textPart = i;
        }
    }
    if (htmlPart != -1) {
        return (AbstractPart *) part->parts()->objectAtIndex(htmlPart);
    }
    else if (textPart != -1) {
        return (AbstractPart *) part->parts()->objectAtIndex(textPart);
    }
    else if (part->parts()->count() > 0) {
        return (AbstractPart *) part->parts()->objectAtIndex(0);
    }
    else {
        return NULL;
    }
}

static bool partContainsMimeType(AbstractPart * part, String * mimeType)
{
    switch (part->partType()) {
        case PartTypeSingle:
            return singlePartContainsMimeType(part, mimeType);
        case PartTypeMessage:
            return messagePartContainsMimeType((AbstractMessagePart *) part, mimeType);
        case PartTypeMultipartMixed:
        case PartTypeMultipartRelated:
        case PartTypeMultipartAlternative:
        case PartTypeMultipartSigned:
            return multipartContainsMimeType((AbstractMultipart *) part, mimeType);
        default:
            return false;
    }
}

static bool singlePartContainsMimeType(AbstractPart * part, String * mimeType)
{
    return part->mimeType()->lowercaseString()->isEqual(mimeType);
}

static bool multipartContainsMimeType(AbstractMultipart * part, String * mimeType)
{
    for(unsigned int i = 0 ; i < part->parts()->count() ; i ++) {
        AbstractPart * subpart = (AbstractPart *) part->parts()->objectAtIndex(i);
        if (partContainsMimeType(subpart, mimeType)) {
            return true;
        }
    }
    return false;
}

static bool messagePartContainsMimeType(AbstractMessagePart * part, String * mimeType)
{
    return partContainsMimeType(part->mainPart(), mimeType);
}

static String * htmlForAbstractMessage(String * folder, AbstractMessage * message,
                                       HTMLRendererIMAPCallback * imapDataCallback,
                                       HTMLRendererRFC822Callback * rfc822DataCallback,
                                       HTMLRendererTemplateCallback * htmlCallback,
                                       Array * attachments,
                                       Array * relatedAttachments)
{
    AbstractPart * mainPart = NULL;
    
    if (htmlCallback == NULL) {
        htmlCallback = new DefaultTemplateCallback();
        ((DefaultTemplateCallback *) htmlCallback)->autorelease();
    }
    
    if (message->className()->isEqual(MCSTR("mailcore::IMAPMessage"))) {
        mainPart = ((IMAPMessage *) message)->mainPart();
    }
    else if (message->className()->isEqual(MCSTR("mailcore::MessageParser"))) {
        mainPart = ((MessageParser *) message)->mainPart();
    }
    if (mainPart == NULL) {
        // needs a mainPart.
        return NULL;
    }

    MCAssert(mainPart != NULL);
    
    htmlRendererContext context;
    context.imapDataCallback = imapDataCallback;
    context.rfc822DataCallback = rfc822DataCallback;
    context.htmlCallback = htmlCallback;
    context.relatedAttachments = NULL;
    context.attachments = NULL;
    context.firstRendered = 0;
    context.folder = folder;
    context.state = RENDER_STATE_NONE;

    context.hasMixedTextAndAttachments = false;
    context.pass = 0;
    context.firstAttachment = false;
    context.hasTextPart = false;

    htmlForAbstractPart(mainPart, &context);
    
    context.relatedAttachments = relatedAttachments;
    context.attachments = attachments;
    context.hasMixedTextAndAttachments = (context.state == RENDER_STATE_HAD_ATTACHMENT_THEN_TEXT);
    context.pass = 1;
    context.firstAttachment = false;
    context.hasTextPart = false;

    htmlCallback->setMixedTextAndAttachmentsModeEnabled(context.hasMixedTextAndAttachments);

    String * content = htmlForAbstractPart(mainPart, &context);
    if (content == NULL)
        return NULL;
    
    content = htmlCallback->filterHTMLForMessage(content);
    
    HashMap * values = htmlCallback->templateValuesForHeader(message->header());
    String * headerString = renderTemplate(htmlCallback->templateForMainHeader(message->header()), values);
    
    HashMap * msgValues = new HashMap();
    msgValues->setObjectForKey(MCSTR("HEADER"), headerString);
    msgValues->setObjectForKey(MCSTR("BODY"), content);
    String * result = renderTemplate(htmlCallback->templateForMessage(message), msgValues);
    msgValues->release();
    
    return result;
}

static String * htmlForAbstractSinglePart(AbstractPart * part, htmlRendererContext * context);
static String * htmlForAbstractMessagePart(AbstractMessagePart * part, htmlRendererContext * context);
static String * htmlForAbstractMultipartRelated(AbstractMultipart * part, htmlRendererContext * context);
static String * htmlForAbstractMultipartMixed(AbstractMultipart * part, htmlRendererContext * context);
static String * htmlForAbstractMultipartAlternative(AbstractMultipart * part, htmlRendererContext * context);

static String * htmlForAbstractPart(AbstractPart * part, htmlRendererContext * context)
{
    switch (part->partType()) {
        case PartTypeSingle:
            return htmlForAbstractSinglePart((AbstractPart *) part, context);
        case PartTypeMessage:
            return htmlForAbstractMessagePart((AbstractMessagePart *) part, context);
        case PartTypeMultipartMixed:
            return htmlForAbstractMultipartMixed((AbstractMultipart *) part, context);
        case PartTypeMultipartRelated:
            return htmlForAbstractMultipartRelated((AbstractMultipart *) part, context);
        case PartTypeMultipartAlternative:
            return htmlForAbstractMultipartAlternative((AbstractMultipart *) part, context);
        case PartTypeMultipartSigned:
            return htmlForAbstractMultipartMixed((AbstractMultipart *) part, context);
        default:
            MCAssert(0);
    }
    return NULL;
}

static String * htmlForAbstractSinglePart(AbstractPart * part, htmlRendererContext * context)
{
    String * mimeType = NULL;
    if (part->mimeType() != NULL) {
        mimeType = part->mimeType()->lowercaseString();
    }
    MCAssert(mimeType != NULL);
    
    if (isTextPart(part, context)) {
        if (context->pass == 0) {
            if (context->state == RENDER_STATE_HAD_ATTACHMENT) {
#if 0
                if (part->className()->isEqual(MCSTR("mailcore::IMAPPart"))) {
                    if (mimeType->isEqual(MCSTR("text/plain"))) {
                        Data * data = context->dataCallback->dataForIMAPPart(context->folder, (IMAPPart *) part);
                        if (data != NULL) {
                            if (data->length() == 0) {
                                return NULL;
                            }
                            else if (data->length() == 2) {
                                if (strncmp(data->bytes(), "\r\n", 2) == 0) {
                                    return NULL;
                                }
                            }
                            else if (data->length() == 1) {
                                if (strncmp(data->bytes(), "\n", 1) == 0) {
                                    return NULL;
                                }
                            }
                        }
                    }
                }
#endif
                context->state = RENDER_STATE_HAD_ATTACHMENT_THEN_TEXT;
            }
            return NULL;
        }
        
        context->hasTextPart = true;
        
        if (mimeType->isEqual(MCSTR("text/plain"))) {
            String * charset = part->charset();
            Data * data = NULL;
            if (part->className()->isEqual(MCSTR("mailcore::IMAPPart"))) {
                data = context->imapDataCallback->dataForIMAPPart(context->folder, (IMAPPart *) part);
            }
            else if (part->className()->isEqual(MCSTR("mailcore::Attachment"))) {
                data = ((Attachment *) part)->data();
                if (data == NULL) {
                    // It may be NULL when mailcore::MessageParser::attachments() is invoked when
                    // when mailcore::MessageParser has been serialized/unserialized.
                    data = context->rfc822DataCallback->dataForRFC822Part(context->folder, (Attachment *) part);
                }
                MCAssert(data != NULL);
            }
            if (data == NULL)
                return NULL;
            
            String * str = data->stringWithDetectedCharset(charset, false);
            str = str->htmlMessageContent();
            str = context->htmlCallback->filterHTMLForPart(str);
            context->firstRendered = true;
            return str;
        }
        else if (mimeType->isEqual(MCSTR("text/html"))) {
            String * charset = part->charset();
            Data * data = NULL;
            if (part->className()->isEqual(MCSTR("mailcore::IMAPPart"))) {
                data = context->imapDataCallback->dataForIMAPPart(context->folder, (IMAPPart *) part);
            }
            else if (part->className()->isEqual(MCSTR("mailcore::Attachment"))) {
                data = ((Attachment *) part)->data();
                if (data == NULL) {
                    // It may be NULL when mailcore::MessageParser::attachments() is invoked when
                    // when mailcore::MessageParser has been serialized/unserialized.
                    data = context->rfc822DataCallback->dataForRFC822Part(context->folder, (Attachment *) part);
                }
            }
            if (data == NULL)
                return NULL;
            
            String * str = data->stringWithDetectedCharset(charset, true);
            str = context->htmlCallback->cleanHTMLForPart(str);
            str = context->htmlCallback->filterHTMLForPart(str);
            context->firstRendered = true;
            return str;
        }
        else {
            MCAssert(0);
            return NULL;
        }
    }
    else {
		
		if (!context->htmlCallback->shouldShowPart(part))
            return MCSTR("");
		
        if (context->pass == 0) {
            if (context->state == RENDER_STATE_NONE) {
                context->state = RENDER_STATE_HAD_ATTACHMENT;
            }
            return NULL;
        }
        
        if (part->uniqueID() == NULL) {
            part->setUniqueID(String::uuidString());
        }
        
        String * result = String::string();
        String * separatorString;
        String * content;
        
        if (!context->firstAttachment && context->hasTextPart) {
            separatorString = context->htmlCallback->templateForAttachmentSeparator();
        }
        else {
            separatorString = MCSTR("");
        }
        
        context->firstAttachment = true;
        
        if (context->htmlCallback->canPreviewPart(part)) {
            if (part->className()->isEqual(MCSTR("mailcore::IMAPPart"))) {
                context->imapDataCallback->prefetchImageIMAPPart(context->folder, (IMAPPart *) part);
            }
            String * url = String::stringWithUTF8Format("x-mailcore-image:%s",
                                                                            part->uniqueID()->UTF8Characters());
            HashMap * values = context->htmlCallback->templateValuesForPart(part);
            values->setObjectForKey(MCSTR("URL"), url);
            content = renderTemplate(context->htmlCallback->templateForImage(part), values);
        }
        else {
            if (part->className()->isEqual(MCSTR("mailcore::IMAPPart"))) {
                context->imapDataCallback->prefetchAttachmentIMAPPart(context->folder, (IMAPPart *) part);
            }
            HashMap * values = context->htmlCallback->templateValuesForPart(part);
            content = renderTemplate(context->htmlCallback->templateForAttachment(part), values);
        }
        
        result->appendString(separatorString);
        result->appendString(content);
        
        if (context->attachments != NULL) {
            context->attachments->addObject(part);
        }
        
        return result;
    }
}

static String * htmlForAbstractMessagePart(AbstractMessagePart * part, htmlRendererContext * context)
{
    if (context->pass == 0) {
        return NULL;
    }
    String * substring = htmlForAbstractPart(part->mainPart(), context);
    if (substring == NULL)
        return NULL;
    
    HashMap * values = context->htmlCallback->templateValuesForHeader(part->header());
    String * headerString = renderTemplate(context->htmlCallback->templateForEmbeddedMessageHeader(part->header()), values);
	
	HashMap * msgValues = new HashMap();
    msgValues->setObjectForKey(MCSTR("HEADER"), headerString);
    msgValues->setObjectForKey(MCSTR("BODY"), substring);
    String * result = renderTemplate(context->htmlCallback->templateForEmbeddedMessage(part), msgValues);
    msgValues->release();

    return result;
}

String * htmlForAbstractMultipartAlternative(AbstractMultipart * part, htmlRendererContext * context)
{
    AbstractPart * preferredAlternative = preferredPartInMultipartAlternative(part);
    if (preferredAlternative == NULL)
        return MCSTR("");

    // Exchange sends calendar invitation as alternative part. We need to extract it.
    AbstractPart * calendar = NULL;
    for(unsigned int i = 0 ; i < part->parts()->count() ; i ++) {
        AbstractPart * subpart = (AbstractPart *) part->parts()->objectAtIndex(i);
        if (partContainsMimeType(subpart, MCSTR("text/calendar"))) {
            calendar = subpart;
        }
    }

    String * html = htmlForAbstractPart(preferredAlternative, context);
    if (html == NULL) {
        return NULL;
    }
    
    String * result = String::string();
    result->appendString(html);
    if (calendar != NULL && calendar != preferredAlternative) {
        result->appendString(htmlForAbstractPart(calendar, context));
    }
    return result;
}

static String * htmlForAbstractMultipartMixed(AbstractMultipart * part, htmlRendererContext * context)
{
    String * result = String::string();
    for(unsigned int i = 0 ; i < part->parts()->count() ; i ++) {
        AbstractPart * subpart = (AbstractPart *) part->parts()->objectAtIndex(i);
        String * substring = htmlForAbstractPart(subpart, context);
        if (context->pass != 0) {
            if (substring == NULL)
                return NULL;
            
            result->appendString(substring);
        }
    }
    return  result;
}

static String * htmlForAbstractMultipartRelated(AbstractMultipart * part, htmlRendererContext * context)
{
    if (part->parts()->count() == 0) {
        if (context->pass == 0) {
            return NULL;
        }
        else {
            return MCSTR("");
        }
    }
    
    // root of the multipart/related.
    AbstractPart * subpart = (AbstractPart *) part->parts()->objectAtIndex(0);
    if (context->relatedAttachments != NULL) {
        for(unsigned int i = 1 ; i < part->parts()->count() ; i ++) {
            AbstractPart * otherSubpart = (AbstractPart *) part->parts()->objectAtIndex(i);
            if (context->relatedAttachments != NULL) {
                context->relatedAttachments->addObject(otherSubpart);
            }
        }
    }
    return htmlForAbstractPart(subpart, context);
}

static void fillTemplateDictionaryFromMCHashMap(ctemplate::TemplateDictionary * dict, HashMap * mcHashMap)
{
    Array * keys = mcHashMap->allKeys();
    
    for(unsigned int i = 0 ; i < keys->count() ; i ++) {
        String * key = (String *) keys->objectAtIndex(i);
        Object * value;
        
        value = mcHashMap->objectForKey(key);
        if (value->className()->isEqual(MCSTR("mailcore::String"))) {
            String * str;
            
            str = (String *) value;
            dict->SetValue(key->UTF8Characters(), str->UTF8Characters());
        }
        else if (value->className()->isEqual(MCSTR("mailcore::Array"))) {
            Array * array;
            
            array = (Array *) value;
            for(unsigned int k = 0 ; k < array->count() ; k ++) {
                HashMap * item = (HashMap *) array->objectAtIndex(k);
                ctemplate::TemplateDictionary * subDict = dict->AddSectionDictionary(key->UTF8Characters());
                fillTemplateDictionaryFromMCHashMap(subDict, item);
            }
        }
        else if (value->className()->isEqual(MCSTR("mailcore::HashMap"))) {
            ctemplate::TemplateDictionary * subDict;
            HashMap * item;
            
            item = (HashMap *) value;
            subDict = dict->AddSectionDictionary(key->UTF8Characters());
            fillTemplateDictionaryFromMCHashMap(subDict, item);
        }
    }
}

static String * renderTemplate(String * templateContent, HashMap * values)
{
    ctemplate::TemplateDictionary dict("template dict");
    std::string output;
    Data * data;
    
    fillTemplateDictionaryFromMCHashMap(&dict, values);
    data = templateContent->dataUsingEncoding("utf-8");
    ctemplate::Template * tpl = ctemplate::Template::StringToTemplate(data->bytes(), data->length(), ctemplate::DO_NOT_STRIP);
    if (tpl == NULL)
        return NULL;
    if (!tpl->Expand(&output, &dict))
        return NULL;
    delete tpl;
    
    return String::stringWithUTF8Characters(output.c_str());
}

String * HTMLRenderer::htmlForRFC822Message(MessageParser * message,
                                            HTMLRendererRFC822Callback * dataCallback,
                                            HTMLRendererTemplateCallback * htmlCallback)
{
    return htmlForAbstractMessage(NULL, message, NULL, dataCallback, htmlCallback, NULL, NULL);
}

String * HTMLRenderer::htmlForIMAPMessage(String * folder,
                                          IMAPMessage * message,
                                          HTMLRendererIMAPCallback * dataCallback,
                                          HTMLRendererTemplateCallback * htmlCallback)
{
    return htmlForAbstractMessage(folder, message, dataCallback, NULL, htmlCallback, NULL, NULL);
}

Array * HTMLRenderer::attachmentsForMessage(AbstractMessage * message)
{
    Array * attachments = Array::array();
    HTMLRendererIMAPDummyCallback * dataCallback = new HTMLRendererIMAPDummyCallback();
    String * ignoredResult = htmlForAbstractMessage(NULL, message, dataCallback, dataCallback, NULL, attachments, NULL);
    delete dataCallback;
    dataCallback = NULL;
    (void) ignoredResult; // remove unused variable warning.
    return attachments;
}

Array * HTMLRenderer::htmlInlineAttachmentsForMessage(AbstractMessage * message)
{
    Array * htmlInlineAttachments = Array::array();
    HTMLRendererIMAPDummyCallback * dataCallback = new HTMLRendererIMAPDummyCallback();
    String * ignoredResult = htmlForAbstractMessage(NULL, message, dataCallback, dataCallback, NULL, NULL, htmlInlineAttachments);
    delete dataCallback;
    dataCallback = NULL;
    (void) ignoredResult; // remove unused variable warning.
    return htmlInlineAttachments;
}

Array * HTMLRenderer::requiredPartsForRendering(AbstractMessage * message)
{
    HTMLRendererIMAPDummyCallback * dataCallback = new HTMLRendererIMAPDummyCallback();
    String * ignoredResult = htmlForAbstractMessage(NULL, message, dataCallback, dataCallback, NULL, NULL, NULL);
    
    Array *requiredParts = dataCallback->requiredParts();
    
    delete dataCallback;
    dataCallback = NULL;
    (void) ignoredResult; // remove unused variable warning.
    return requiredParts;
}
