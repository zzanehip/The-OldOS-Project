#include "MCAbstractMessagePart.h"

#include "MCMessageHeader.h"

using namespace mailcore;

void AbstractMessagePart::init()
{
    mMainPart = NULL;
    mHeader = NULL;
    setPartType(PartTypeMessage);
}

AbstractMessagePart::AbstractMessagePart()
{
    init();
}

AbstractMessagePart::AbstractMessagePart(AbstractMessagePart * other) : AbstractPart(other)
{
    init();
    if (other->mainPart() != NULL) {
        setMainPart((AbstractPart *) other->mainPart()->copy()->autorelease());
    }
    if (other->mHeader != NULL) {
        setHeader((MessageHeader *) other->header()->copy()->autorelease());
    }
}

AbstractMessagePart::~AbstractMessagePart()
{
    MC_SAFE_RELEASE(mMainPart);
    MC_SAFE_RELEASE(mHeader);
}

String * AbstractMessagePart::description()
{
    String * result = String::string();
    result->appendUTF8Format("<%s:%p %s>", className()->UTF8Characters(), this, mMainPart->description()->UTF8Characters());
    return result;
}

Object * AbstractMessagePart::copy()
{
    return new AbstractMessagePart(this);
}

MessageHeader * AbstractMessagePart::header()
{
    if (mHeader == NULL) {
        mHeader = new MessageHeader();
    }
    return mHeader;
}

void AbstractMessagePart::setHeader(MessageHeader * header)
{
    MC_SAFE_REPLACE_RETAIN(MessageHeader, mHeader, header);
}

AbstractPart * AbstractMessagePart::mainPart()
{
    return mMainPart;
}

void AbstractMessagePart::setMainPart(AbstractPart * mainPart)
{
    MC_SAFE_REPLACE_RETAIN(AbstractPart, mMainPart, mainPart);
}

AbstractPart * AbstractMessagePart::partForContentID(String * contentID)
{
    return mainPart()->partForContentID(contentID);
}

AbstractPart * AbstractMessagePart::partForUniqueID(String * contentID)
{
    return mainPart()->partForUniqueID(contentID);
}

HashMap * AbstractMessagePart::serializable()
{
    HashMap * result = (HashMap *) AbstractPart::serializable();
    if (mainPart() != NULL) {
        result->setObjectForKey(MCSTR("mainPart"), mainPart()->serializable());
    }
    if (header() != NULL) {
        result->setObjectForKey(MCSTR("header"), header()->serializable());
    }
    return result;
}

void AbstractMessagePart::importSerializable(HashMap * serializable)
{
    AbstractPart::importSerializable(serializable);
    setMainPart((AbstractPart *) Object::objectWithSerializable((HashMap *) serializable->objectForKey(MCSTR("mainPart"))));
    setHeader((MessageHeader *) Object::objectWithSerializable((HashMap *) serializable->objectForKey(MCSTR("header"))));
}
