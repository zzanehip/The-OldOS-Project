#include "MCIMAPMessage.h"

#include "MCDefines.h"
#include "MCMessageHeader.h"
#include "MCIMAPPart.h"
#include "MCIMAPMessagePart.h"
#include "MCIMAPMultipart.h"
#include "MCHTMLRenderer.h"
#include "MCHTMLRendererCallback.h"

using namespace mailcore;

static AbstractPart * partForPartIDInPart(AbstractPart * part, String * partID);
static AbstractPart * partForPartIDInMultipart(AbstractMultipart * part, String * partID);
static AbstractPart * partForPartIDInMessagePart(AbstractMessagePart * part, String * partID);

void IMAPMessage::init()
{
    mUid = 0;
    mSequenceNumber = 0;
    mFlags = MessageFlagNone;
    mOriginalFlags = MessageFlagNone;
    mCustomFlags = NULL;
    mMainPart = NULL;
    mGmailLabels = NULL;
    mModSeqValue = 0;
    mGmailThreadID = 0;
    mGmailMessageID = 0;
    mSize = 0;
}

IMAPMessage::IMAPMessage()
{
    init();
}

IMAPMessage::IMAPMessage(IMAPMessage * other) : AbstractMessage(other)
{
    init();
    setUid(other->uid());
    setSequenceNumber(other->sequenceNumber());
    setFlags(other->flags());
    setOriginalFlags(other->originalFlags());
    setCustomFlags(other->customFlags());
    if (other->mainPart() != NULL) {
        setMainPart((AbstractPart *) other->mainPart()->copy()->autorelease());
    }
    else {
        setMainPart(NULL);
    }
    setGmailLabels(other->gmailLabels());
    setGmailThreadID(other->gmailThreadID());
    setGmailMessageID(other->gmailMessageID());
}

IMAPMessage::~IMAPMessage()
{
    MC_SAFE_RELEASE(mMainPart);
    MC_SAFE_RELEASE(mGmailLabels);
    MC_SAFE_RELEASE(mCustomFlags);
}

Object * IMAPMessage::copy()
{
    return new IMAPMessage(this);
}

String * IMAPMessage::description()
{
    String * result = String::string();
    result->appendUTF8Format("<%s:%p %u %u\n", className()->UTF8Characters(), this, (unsigned int) uid(), (unsigned int) sequenceNumber());
    result->appendString(header()->description());
    if (mainPart() != NULL) {
        result->appendString(mainPart()->description());
        result->appendUTF8Characters("\n");
    }
    result->appendUTF8Characters(">");
    return result;
}

uint32_t IMAPMessage::uid()
{
    return mUid;
}

void IMAPMessage::setUid(uint32_t uid)
{
    mUid = uid;
}

uint32_t IMAPMessage::sequenceNumber()
{
    return mSequenceNumber;
}

void IMAPMessage::setSequenceNumber(uint32_t value)
{
    mSequenceNumber = value;
}

uint32_t IMAPMessage::size()
{
    return mSize;
}

void IMAPMessage::setSize(uint32_t size)
{
    mSize = size;
}

void IMAPMessage::setFlags(MessageFlag flags)
{
    mFlags = flags;
}

MessageFlag IMAPMessage::flags()
{
    return mFlags;
}

void IMAPMessage::setOriginalFlags(MessageFlag flags)
{
    mOriginalFlags = flags;
}

MessageFlag IMAPMessage::originalFlags()
{
    return mOriginalFlags;
}

void IMAPMessage::setCustomFlags(Array * customFlags)
{
   MC_SAFE_REPLACE_COPY(Array, mCustomFlags, customFlags);
}

Array * IMAPMessage::customFlags()
{
    return mCustomFlags;
}

void IMAPMessage::setModSeqValue(uint64_t uid)
{
    mModSeqValue = uid;
}

uint64_t IMAPMessage::modSeqValue()
{
    return mModSeqValue;
}

void IMAPMessage::setMainPart(AbstractPart * mainPart)
{
    MC_SAFE_REPLACE_RETAIN(AbstractPart, mMainPart, mainPart);
}

AbstractPart * IMAPMessage::mainPart()
{
    return mMainPart;
}

void IMAPMessage::setGmailLabels(Array * labels)
{
    MC_SAFE_REPLACE_COPY(Array, mGmailLabels, labels);
}

Array * IMAPMessage::gmailLabels()
{
    return mGmailLabels;
}

void IMAPMessage::setGmailMessageID(uint64_t msgID)
{
    mGmailMessageID = msgID;
}

uint64_t IMAPMessage::gmailMessageID()
{
    return mGmailMessageID;
}

void IMAPMessage::setGmailThreadID(uint64_t threadID)
{
    mGmailThreadID = threadID;
}

uint64_t IMAPMessage::gmailThreadID()
{
    return mGmailThreadID;
}

AbstractPart * IMAPMessage::partForPartID(String * partID)
{
    return partForPartIDInPart(mainPart(), partID);
}

static AbstractPart * partForPartIDInPart(AbstractPart * part, String * partID)
{
    switch (part->partType()) {
        case PartTypeSingle:
            if (partID->isEqual(((IMAPPart *) part)->partID())) {
                return part;
            }
            return NULL;
        case mailcore::PartTypeMultipartMixed:
        case mailcore::PartTypeMultipartRelated:
        case mailcore::PartTypeMultipartAlternative:
        case mailcore::PartTypeMultipartSigned:
            if (partID->isEqual(((IMAPMultipart *) part)->partID())) {
                return part;
            }
            return partForPartIDInMultipart((AbstractMultipart *) part, partID);
        case mailcore::PartTypeMessage:
            if (partID->isEqual(((IMAPMessagePart *) part)->partID())) {
                return part;
            }
            return partForPartIDInMessagePart((AbstractMessagePart *) part, partID);
        default:
            return NULL;
    }
}

static AbstractPart * partForPartIDInMessagePart(AbstractMessagePart * part, String * partID)
{
    return partForPartIDInPart(part->mainPart(), partID);
}

static AbstractPart * partForPartIDInMultipart(AbstractMultipart * part, String * partID)
{
    for(unsigned int i = 0 ; i < part->parts()->count() ; i ++) {
        mailcore::AbstractPart * subpart = (mailcore::AbstractPart *) part->parts()->objectAtIndex(i);
        mailcore::AbstractPart * result = partForPartIDInPart(subpart, partID);
        if (result != NULL)
            return result;
    }
    return NULL;
}

AbstractPart * IMAPMessage::partForContentID(String * contentID)
{
    return mainPart()->partForContentID(contentID);
}

AbstractPart * IMAPMessage::partForUniqueID(String * uniqueID)
{
    return mainPart()->partForUniqueID(uniqueID);
}

String * IMAPMessage::htmlRendering(String * folder,
                                    HTMLRendererIMAPCallback * dataCallback,
                                    HTMLRendererTemplateCallback * htmlCallback)
{
    return HTMLRenderer::htmlForIMAPMessage(folder, this, dataCallback, htmlCallback);
}

HashMap * IMAPMessage::serializable()
{
    // sequenceNumber is not serialized.
    HashMap * result = AbstractMessage::serializable();
    result->setObjectForKey(MCSTR("modSeqValue"), String::stringWithUTF8Format("%llu", (long long unsigned) modSeqValue()));
    result->setObjectForKey(MCSTR("uid"), String::stringWithUTF8Format("%lu", (long unsigned) uid()));
    result->setObjectForKey(MCSTR("size"), String::stringWithUTF8Format("%lu", (long unsigned) size()));
    result->setObjectForKey(MCSTR("flags"), String::stringWithUTF8Format("%u", (unsigned) flags()));
    result->setObjectForKey(MCSTR("originalFlags"), String::stringWithUTF8Format("%u", (unsigned) originalFlags()));
    if (customFlags() != NULL) {
        result->setObjectForKey(MCSTR("customFlags"), customFlags());
    }
    if (mMainPart != NULL) {
        result->setObjectForKey(MCSTR("mainPart"), mMainPart->serializable());
    }
    if (gmailLabels() != NULL) {
        result->setObjectForKey(MCSTR("gmailLabels"), gmailLabels());
    }
    if (gmailMessageID() != 0) {
        result->setObjectForKey(MCSTR("gmailMessageID"), String::stringWithUTF8Format("%llu", (long long unsigned) gmailMessageID()));
    }
    if (gmailThreadID() != 0) {
        result->setObjectForKey(MCSTR("gmailThreadID"), String::stringWithUTF8Format("%llu", (long long unsigned) gmailThreadID()));
    }
    return result;
}

void IMAPMessage::importSerializable(HashMap * serializable)
{
    // sequenceNumber is not serialized.
    AbstractMessage::importSerializable(serializable);
    String * modSeq = (String *) serializable->objectForKey(MCSTR("modSeqValue"));
    if (modSeq != NULL) {
        setModSeqValue(modSeq->unsignedLongLongValue());
    }
    String * uid = (String *) serializable->objectForKey(MCSTR("uid"));
    if (uid != NULL) {
        setUid((uint32_t) uid->unsignedLongValue());
    }
    String * size = (String *) serializable->objectForKey(MCSTR("size"));
    if (size != NULL) {
        setSize((uint32_t) size->unsignedLongValue());
    }
    String * flags = (String *) serializable->objectForKey(MCSTR("flags"));
    if (flags != NULL) {
        setFlags((MessageFlag) flags->unsignedIntValue());
    }
    String * originalFlags = (String *) serializable->objectForKey(MCSTR("originalFlags"));
    if (originalFlags != NULL) {
        setOriginalFlags((MessageFlag) originalFlags->unsignedIntValue());
    }
    String * customFlags = (String *) serializable->objectForKey(MCSTR("customFlags"));
    if (customFlags != NULL) {
        setCustomFlags((Array *) serializable->objectForKey(MCSTR("customFlags")));
    }
    setMainPart((AbstractPart *) Object::objectWithSerializable((HashMap *) serializable->objectForKey(MCSTR("mainPart"))));
    setGmailLabels((Array *) serializable->objectForKey(MCSTR("gmailLabels")));
    String * gmailMessageID = (String *) serializable->objectForKey(MCSTR("gmailMessageID"));
    if (gmailMessageID != NULL) {
        setGmailMessageID(gmailMessageID->unsignedLongLongValue());
    }
    String * gmailThreadID = (String *) serializable->objectForKey(MCSTR("gmailThreadID"));
    if (gmailThreadID != NULL) {
        setGmailThreadID(gmailThreadID->unsignedLongLongValue());
    }
}

static void * createObject()
{
    return new IMAPMessage();
}

INITIALIZE(IMAPMessage)
{
    Object::registerObjectConstructor("mailcore::IMAPMessage", &createObject);
}
