#include "MCMessageParser.h"

#include <libetpan/libetpan.h>
#if __APPLE__
#include <CoreFoundation/CoreFoundation.h>
#endif

#include "MCDefines.h"
#include "MCAttachment.h"
#include "MCMessageHeader.h"
#include "MCHTMLRenderer.h"
#include "MCHTMLBodyRendererTemplateCallback.h"

using namespace mailcore;

MessageParser * MessageParser::messageParserWithData(Data * data)
{
    MessageParser * parser = new MessageParser(data);
    return (MessageParser *) parser->autorelease();
}

MessageParser * MessageParser::messageParserWithContentsOfFile(String * filename)
{
    Data * data = Data::dataWithContentsOfFile(filename);
    if (data == NULL) {
        data = Data::data();
    }
    return messageParserWithData(data);
}

void MessageParser::init()
{
    mData = NULL;
    mMainPart = NULL;
#if __APPLE__
    mNSData = NULL;
#endif
}

void MessageParser::setBytes(char * dataBytes, unsigned int dataLength)
{
    const char * start = NULL;
    unsigned int length = 0;
    if (dataLength > 5) {
        if (strncmp(dataBytes, "From ", 5) == 0) {
            start = dataBytes;
            for(unsigned int i = 0 ; i < dataLength ; i ++) {
                if (start[i] == '\n') {
                    start = start + i + 1;
                    length = dataLength - (i + 1);
                    break;
                }
            }
        }
    }
    if (start != NULL) {
        dataBytes = (char *) start;
        dataLength = length;
    }
    
    mailmessage * msg;
    struct mailmime * mime;
    
    msg = data_message_init(dataBytes, dataLength);
    mailmessage_get_bodystructure(msg, &mime);
    mMainPart = (AbstractPart *) Attachment::attachmentsWithMIME(msg->msg_mime)->retain();
    mMainPart->applyUniquePartID();
    
    size_t cur_token = 0;
    struct mailimf_fields * fields;
    int r = mailimf_envelope_and_optional_fields_parse(dataBytes, dataLength, &cur_token, &fields);
    if (r == MAILIMAP_NO_ERROR) {
        header()->importIMFFields(fields);
        mailimf_fields_free(fields);
    }
    mailmessage_free(msg);

    setupPartID();
}

MessageParser::MessageParser()
{
    init();
}

MessageParser::MessageParser(Data * data)
{
    init();
    
    setBytes(data->bytes(), data->length());
    mData = (Data *) data->retain();
}

MessageParser::MessageParser(MessageParser * other) : AbstractMessage(other)
{
    init();
    MC_SAFE_REPLACE_RETAIN(Data, mData, other->mData);
    MC_SAFE_REPLACE_RETAIN(AbstractPart, mMainPart, other->mMainPart);
    setupPartID();
}

MessageParser::~MessageParser()
{
    MC_SAFE_RELEASE(mMainPart);
    MC_SAFE_RELEASE(mData);
#if __APPLE__
    if (mNSData != NULL) {
        CFRelease(mNSData);
    }
#endif
}

AbstractPart * MessageParser::mainPart()
{
    return mMainPart;
}

Data * MessageParser::data()
{
#if __APPLE__
    if (mNSData != NULL) {
        return dataFromNSData();
    }
#endif
    return mData;
}

String * MessageParser::description()
{
    String * result = String::string();
    result->appendUTF8Format("<%s:%p ", MCUTF8(className()), this);
    result->appendUTF8Format("<%p>", mMainPart);
    if (mMainPart != NULL) {
        result->appendString(mMainPart->description());
    }
    result->appendUTF8Characters(">");
    
    return result;
}

HashMap * MessageParser::serializable()
{
    HashMap * result = AbstractMessage::serializable();
    if (mMainPart != NULL) {
        result->setObjectForKey(MCSTR("mainPart"), mMainPart->serializable());
    }
    return result;
}

void MessageParser::importSerializable(HashMap * serializable)
{
    AbstractMessage::importSerializable(serializable);
    MC_SAFE_REPLACE_RETAIN(AbstractPart, mMainPart, Object::objectWithSerializable((HashMap *) serializable->objectForKey(MCSTR("mainPart"))));
    if (mMainPart != NULL) {
        mMainPart->applyUniquePartID();
    }
    setupPartID();
}

Object * MessageParser::copy()
{
    return new MessageParser(this);
}

AbstractPart * MessageParser::partForContentID(String * contentID)
{
    if (mainPart() == NULL) {
        return NULL;
    }
    return mainPart()->partForContentID(contentID);
}

AbstractPart * MessageParser::partForUniqueID(String * uniqueID)
{
    if (mainPart() == NULL) {
        return NULL;
    }
    return mainPart()->partForUniqueID(uniqueID);
}

String * MessageParser::htmlRendering(HTMLRendererTemplateCallback * htmlCallback)
{
    return HTMLRenderer::htmlForRFC822Message(this, NULL, htmlCallback);
}

String * MessageParser::htmlRenderingWithDataCallback(HTMLRendererTemplateCallback * htmlCallback,
                                                      HTMLRendererRFC822Callback * dataCallback)
{
    return HTMLRenderer::htmlForRFC822Message(this, dataCallback, htmlCallback);
}

String * MessageParser::htmlBodyRendering()
{
    HTMLBodyRendererTemplateCallback * callback = new HTMLBodyRendererTemplateCallback();
    String * result = htmlRendering(callback);
    MC_SAFE_RELEASE(callback);
    return result;
}

String * MessageParser::plainTextRendering()
{
    String * html = htmlRendering(NULL);
    return html->flattenHTML();
}

String * MessageParser::plainTextBodyRendering(bool stripWhitespace)
{
    String * html = htmlBodyRendering();
    String * plainTextBodyString = html->flattenHTML();
    
    if (stripWhitespace) {
        plainTextBodyString = plainTextBodyString->stripWhitespace();
    }
    return plainTextBodyString;
}

void MessageParser::setupPartID()
{
    if (mMainPart == NULL) {
        return;
    }
    recursiveSetupPartIDWithPart(mMainPart, MCSTR(""));
}

void MessageParser::recursiveSetupPartIDWithPart(mailcore::AbstractPart * part,
                                                 mailcore::String * partIDPrefix)
{
    switch (part->partType()) {
        case PartTypeSingle:
        {
            String * partID = NULL;
            if (partIDPrefix->length() == 0) {
                partID = MCSTR("1");
            }
            else {
                partID = partIDPrefix;
            }
            return recursiveSetupPartIDWithSinglePart((Attachment *) part, partID);
        }
        case PartTypeMessage:
        {
            String * partID = NULL;
            if (partIDPrefix->length() == 0) {
                partID = MCSTR("1");
            }
            else {
                partID = partIDPrefix;
            }
            return recursiveSetupPartIDWithMessagePart((MessagePart *) part, partID);
        }
        case PartTypeMultipartMixed:
        case PartTypeMultipartRelated:
        case PartTypeMultipartAlternative:
        case PartTypeMultipartSigned:
            return recursiveSetupPartIDWithMultipart((Multipart *) part, partIDPrefix);
        default:
            MCAssert(0);
    }
}

void MessageParser::recursiveSetupPartIDWithSinglePart(mailcore::Attachment * part,
                                                       mailcore::String * partIDPrefix)
{
    part->setPartID(partIDPrefix);
}

void MessageParser::recursiveSetupPartIDWithMessagePart(mailcore::MessagePart * part,
                                                        mailcore::String * partIDPrefix)
{
    part->setPartID(partIDPrefix);
    String * partID = NULL;
    switch (part->mainPart()->partType()) {
        case PartTypeSingle:
        case PartTypeMessage:
        {
            if (partIDPrefix->length() == 0) {
                partID = MCSTR("1");
            }
            else {
                partID = partIDPrefix->stringByAppendingUTF8Characters(".1");
            }
            break;
        }
        default:
            partID = partIDPrefix;
            break;
    }
    recursiveSetupPartIDWithPart(part->mainPart(), partID);
}

void MessageParser::recursiveSetupPartIDWithMultipart(mailcore::Multipart * part,
                                                      mailcore::String * partIDPrefix)
{
    part->setPartID(partIDPrefix);
    mc_foreacharrayIndex(idx, AbstractPart, subpart, part->parts()) {
        String * partID = NULL;
        if (partIDPrefix->length() == 0) {
            partID = String::stringWithUTF8Format("%u", idx + 1);
        }
        else {
            partID = partIDPrefix->stringByAppendingUTF8Format(".%u", idx + 1);
        }
        recursiveSetupPartIDWithPart(subpart, partID);
    }
}

static void * createObject()
{
    return new MessageParser();
}

INITIALIZE(MessageParser)
{
    Object::registerObjectConstructor("mailcore::MessageParser", &createObject);
}
