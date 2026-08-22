//
//  MCHTMLRendererCallback.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 2/2/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCHTMLRendererCallback.h"

#include "MCAddressDisplay.h"
#include "MCDateFormatter.h"
#include "MCSizeFormatter.h"
#include "MCAttachment.h"

using namespace mailcore;

HTMLRendererTemplateCallback::HTMLRendererTemplateCallback()
{
}

HTMLRendererTemplateCallback::~HTMLRendererTemplateCallback()
{
}

mailcore::HashMap * HTMLRendererTemplateCallback::templateValuesForHeader(mailcore::MessageHeader * header)
{
    mailcore::HashMap * result = mailcore::HashMap::hashMap();
    
    if (header->from() != NULL) {
        result->setObjectForKey(MCSTR("HASFROM"), mailcore::HashMap::hashMap());
        result->setObjectForKey(MCSTR("FROM"), mailcore::AddressDisplay::displayStringForAddress(header->from())->htmlEncodedString());
        result->setObjectForKey(MCSTR("SHORTFROM"), mailcore::AddressDisplay::shortDisplayStringForAddress(header->from())->htmlEncodedString());
        result->setObjectForKey(MCSTR("VERYSHORTFROM"), mailcore::AddressDisplay::veryShortDisplayStringForAddress(header->from())->htmlEncodedString());
    }
    else {
        result->setObjectForKey(MCSTR("NOFROM"), mailcore::HashMap::hashMap());
    }
    
    if ((header->to() != NULL) && (header->to()->count() > 0)) {
        result->setObjectForKey(MCSTR("HASTO"), mailcore::HashMap::hashMap());
        result->setObjectForKey(MCSTR("TO"), mailcore::AddressDisplay::displayStringForAddresses(header->to())->htmlEncodedString());
        result->setObjectForKey(MCSTR("SHORTTO"), mailcore::AddressDisplay::shortDisplayStringForAddresses(header->to())->htmlEncodedString());
        result->setObjectForKey(MCSTR("VERYSHORTTO"), mailcore::AddressDisplay::veryShortDisplayStringForAddresses(header->to())->htmlEncodedString());
    }
    else {
        result->setObjectForKey(MCSTR("NOTO"), mailcore::HashMap::hashMap());
    }
    
    if ((header->cc() != NULL) && (header->cc()->count() > 0)) {
        result->setObjectForKey(MCSTR("HASCC"), mailcore::HashMap::hashMap());
        result->setObjectForKey(MCSTR("CC"), mailcore::AddressDisplay::displayStringForAddresses(header->cc())->htmlEncodedString());
        result->setObjectForKey(MCSTR("SHORTCC"), mailcore::AddressDisplay::shortDisplayStringForAddresses(header->cc())->htmlEncodedString());
        result->setObjectForKey(MCSTR("VERYSHORTCC"), mailcore::AddressDisplay::veryShortDisplayStringForAddresses(header->cc())->htmlEncodedString());
    }
    else {
        result->setObjectForKey(MCSTR("NOCC"), mailcore::HashMap::hashMap());
    }
    
    if ((header->bcc() != NULL) && (header->bcc()->count() > 0)) {
        result->setObjectForKey(MCSTR("HASBCC"), mailcore::HashMap::hashMap());
        result->setObjectForKey(MCSTR("BCC"), mailcore::AddressDisplay::displayStringForAddresses(header->bcc())->htmlEncodedString());
        result->setObjectForKey(MCSTR("SHORTBCC"), mailcore::AddressDisplay::shortDisplayStringForAddresses(header->bcc())->htmlEncodedString());
        result->setObjectForKey(MCSTR("VERYSHORTBCC"), mailcore::AddressDisplay::veryShortDisplayStringForAddresses(header->bcc())->htmlEncodedString());
    }
    else {
        result->setObjectForKey(MCSTR("NOBCC"), mailcore::HashMap::hashMap());
    }
    
    mailcore::Array * recipient = new mailcore::Array();
    recipient->addObjectsFromArray(header->to());
    recipient->addObjectsFromArray(header->cc());
    recipient->addObjectsFromArray(header->bcc());
    
    if (recipient->count() > 0) {
        result->setObjectForKey(MCSTR("HASRECIPIENT"), mailcore::HashMap::hashMap());
        result->setObjectForKey(MCSTR("RECIPIENT"), mailcore::AddressDisplay::displayStringForAddresses(recipient)->htmlEncodedString());
        result->setObjectForKey(MCSTR("SHORTRECIPIENT"), mailcore::AddressDisplay::shortDisplayStringForAddresses(recipient)->htmlEncodedString());
        result->setObjectForKey(MCSTR("VERYSHORTRECIPIENT"), mailcore::AddressDisplay::veryShortDisplayStringForAddresses(recipient)->htmlEncodedString());
    }
    else {
        result->setObjectForKey(MCSTR("NORECIPIENT"), mailcore::HashMap::hashMap());
    }
    recipient->release();
    
    if ((header->replyTo() != NULL) && (header->replyTo()->count() > 0)) {
        result->setObjectForKey(MCSTR("HASREPLYTO"), mailcore::HashMap::hashMap());
        result->setObjectForKey(MCSTR("REPLYTO"), mailcore::AddressDisplay::displayStringForAddresses(header->replyTo())->htmlEncodedString());
        result->setObjectForKey(MCSTR("SHORTREPLYTO"), mailcore::AddressDisplay::shortDisplayStringForAddresses(header->replyTo())->htmlEncodedString());
        result->setObjectForKey(MCSTR("VERYSHORTREPLYTO"), mailcore::AddressDisplay::veryShortDisplayStringForAddresses(header->replyTo())->htmlEncodedString());
    }
    else {
        result->setObjectForKey(MCSTR("NOREPLYTO"), mailcore::HashMap::hashMap());
    }
    
    if ((header->subject() != NULL) && (header->subject()->length() > 0)) {
        result->setObjectForKey(MCSTR("EXTRACTEDSUBJECT"), header->partialExtractedSubject()->htmlEncodedString());
        result->setObjectForKey(MCSTR("SUBJECT"), header->subject()->htmlEncodedString());
        result->setObjectForKey(MCSTR("HASSUBJECT"), mailcore::HashMap::hashMap());
    }
    else {
        result->setObjectForKey(MCSTR("NOSUBJECT"), mailcore::HashMap::hashMap());
    }
    
    mailcore::String * dateString;
    static mailcore::DateFormatter * fullFormatter = NULL;
    static pthread_mutex_t formatterLock = PTHREAD_MUTEX_INITIALIZER;
    pthread_mutex_lock(&formatterLock);
    if (fullFormatter == NULL) {
        fullFormatter = new mailcore::DateFormatter();
        fullFormatter->setDateStyle(mailcore::DateFormatStyleFull);
        fullFormatter->setTimeStyle(mailcore::DateFormatStyleFull);
    }
    pthread_mutex_unlock(&formatterLock);
    dateString = fullFormatter->stringFromDate(header->date());
    if (dateString != NULL) {
        result->setObjectForKey(MCSTR("FULLDATE"), dateString->htmlEncodedString());
    }
    static mailcore::DateFormatter * longFormatter = NULL;
    pthread_mutex_lock(&formatterLock);
    if (longFormatter == NULL) {
        longFormatter = new mailcore::DateFormatter();
        longFormatter->setDateStyle(mailcore::DateFormatStyleLong);
        longFormatter->setTimeStyle(mailcore::DateFormatStyleLong);
    }
    pthread_mutex_unlock(&formatterLock);
    dateString = longFormatter->stringFromDate(header->date());
    if (dateString != NULL) {
        result->setObjectForKey(MCSTR("LONGDATE"), dateString->htmlEncodedString());
    }
    static mailcore::DateFormatter * mediumFormatter = NULL;
    pthread_mutex_lock(&formatterLock);
    if (mediumFormatter == NULL) {
        mediumFormatter = new mailcore::DateFormatter();
        mediumFormatter->setDateStyle(mailcore::DateFormatStyleMedium);
        mediumFormatter->setTimeStyle(mailcore::DateFormatStyleMedium);
    }
    pthread_mutex_unlock(&formatterLock);
    dateString = mediumFormatter->stringFromDate(header->date());
    if (dateString != NULL) {
        result->setObjectForKey(MCSTR("MEDIUMDATE"), dateString->htmlEncodedString());
    }
    static mailcore::DateFormatter * shortFormatter = NULL;
    pthread_mutex_lock(&formatterLock);
    if (shortFormatter == NULL) {
        shortFormatter = new mailcore::DateFormatter();
        shortFormatter->setDateStyle(mailcore::DateFormatStyleShort);
        shortFormatter->setTimeStyle(mailcore::DateFormatStyleShort);
    }
    pthread_mutex_unlock(&formatterLock);
    dateString = shortFormatter->stringFromDate(header->date());
    if (dateString != NULL) {
        result->setObjectForKey(MCSTR("SHORTDATE"), dateString->htmlEncodedString());
    }
    
    return result;
}

mailcore::HashMap * HTMLRendererTemplateCallback::templateValuesForPart(mailcore::AbstractPart * part)
{
    mailcore::HashMap * result = mailcore::HashMap::hashMap();
    mailcore::String * filename = NULL;
    
    if (part->filename() != NULL) {
        filename = part->filename()->lastPathComponent();
    }
    
    if (filename != NULL) {
        result->setObjectForKey(MCSTR("FILENAME"), filename->htmlEncodedString());
        result->setObjectForKey(MCSTR("HASFILENAME"), mailcore::HashMap::hashMap());
    }
    else {
        result->setObjectForKey(MCSTR("NOFILENAME"), mailcore::HashMap::hashMap());
    }
    
    if (part->className()->isEqual(MCSTR("mailcore::IMAPPart"))) {
        mailcore::IMAPPart * imapPart = (mailcore::IMAPPart *) part;
        mailcore::String * value = mailcore::SizeFormatter::stringWithSize(imapPart->decodedSize());
        result->setObjectForKey(MCSTR("SIZE"), value);
        result->setObjectForKey(MCSTR("HASSIZE"), mailcore::HashMap::hashMap());
    }
    else if (part->className()->isEqual(MCSTR("mailcore::Attachment"))) {
        mailcore::Attachment * attachment = (mailcore::Attachment *) part;
        if (attachment->data() != NULL) {
            mailcore::String * value = mailcore::SizeFormatter::stringWithSize(attachment->data()->length());
            result->setObjectForKey(MCSTR("SIZE"), value);
            result->setObjectForKey(MCSTR("HASSIZE"), mailcore::HashMap::hashMap());
        }
    }
    else {
        result->setObjectForKey(MCSTR("NOSIZE"), mailcore::HashMap::hashMap());
    }
    
    if (part->contentID() != NULL) {
        result->setObjectForKey(MCSTR("CONTENTID"), part->contentID());
    }
    if (part->uniqueID() != NULL) {
        result->setObjectForKey(MCSTR("UNIQUEID"), part->uniqueID());
    }
    
    return result;
}

mailcore::String * HTMLRendererTemplateCallback::templateForMainHeader(MessageHeader * header)
{
    return MCSTR("<div style=\"background-color:#eee\">\
                 {{#HASFROM}}\
                 <div><b>From:</b> {{FROM}}</div>\
                 {{/HASFROM}}\
                 {{#HASTO}}\
                 <div><b>To:</b> {{TO}}</div>\
                 {{/HASTO}}\
                 {{#HASCC}}\
                 <div><b>Cc:</b> {{CC}}</div>\
                 {{/HASCC}}\
                 {{#HASBCC}}\
                 <div><b>Bcc:</b> {{BCC}}</div>\
                 {{/HASBCC}}\
                 {{#NORECIPIENT}}\
                 <div><b>To:</b> <i>Undisclosed recipient</i></div>\
                 {{/NORECIPIENT}}\
                 {{#HASSUBJECT}}\
                 <div><b>Subject:</b> {{EXTRACTEDSUBJECT}}</div>\
                 {{/HASSUBJECT}}\
                 {{#NOSUBJECT}}\
                 <div><b>Subject:</b> <i>No Subject</i></div>\
                 {{/NOSUBJECT}}\
                 <div><b>Date:</b> {{LONGDATE}}</div>\
                 </div>");
}

mailcore::String * HTMLRendererTemplateCallback::templateForEmbeddedMessageHeader(MessageHeader * header)
{
    return templateForMainHeader(header);
}

mailcore::String * HTMLRendererTemplateCallback::templateForImage(AbstractPart * part)
{
    return MCSTR("");
}

mailcore::String * HTMLRendererTemplateCallback::templateForAttachment(AbstractPart * part)
{
    return MCSTR("{{#HASSIZE}}\
                 {{#HASFILENAME}}\
                 <div>- {{FILENAME}}, {{SIZE}}</div>\
                 {{/HASFILENAME}}\
                 {{#NOFILENAME}}\
                 <div>- Untitled, {{SIZE}}</div>\
                 {{/NOFILENAME}}\
                 {{/HASSIZE}}\
                 {{#NOSIZE}}\
                 {{#HASFILENAME}}\
                 <div>- {{FILENAME}}</div>\
                 {{/HASFILENAME}}\
                 {{#NOFILENAME}}\
                 <div>- Untitled</div>\
                 {{/NOFILENAME}}\
                 {{/NOSIZE}}\
                 ");
}

mailcore::String * HTMLRendererTemplateCallback::templateForMessage(AbstractMessage * message)
{
    return MCSTR("<div style=\"padding-bottom: 20px;\">{{HEADER}}</div><div>{{BODY}}</div>");
}


mailcore::String * HTMLRendererTemplateCallback::templateForEmbeddedMessage(AbstractMessagePart * part)
{
    return MCSTR("<div style=\"padding-bottom: 20px;\">{{HEADER}}</div><div>{{BODY}}</div>");
}

mailcore::String * HTMLRendererTemplateCallback::templateForAttachmentSeparator()
{
    return MCSTR("<hr/>");
}

mailcore::String * HTMLRendererTemplateCallback::filterHTMLForMessage(mailcore::String * html)
{
    return html;
}

mailcore::String * HTMLRendererTemplateCallback::cleanHTMLForPart(mailcore::String * html)
{
    return html->cleanedHTMLString();
}

mailcore::String * HTMLRendererTemplateCallback::filterHTMLForPart(mailcore::String * html)
{
    return html;
}

bool HTMLRendererTemplateCallback::canPreviewPart(AbstractPart * part)
{
    return false;
}

bool HTMLRendererTemplateCallback::shouldShowPart(AbstractPart * part)
{
    return true;
}

void HTMLRendererTemplateCallback::setMixedTextAndAttachmentsModeEnabled(bool enabled)
{
}
