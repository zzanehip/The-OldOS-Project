#include "MCMessagePart.h"

#include "MCDefines.h"

using namespace mailcore;

MessagePart::MessagePart()
{
    init();
}

MessagePart::MessagePart(MessagePart * other) : AbstractMessagePart(other)
{
    init();
    setPartID(other->partID());
}

void MessagePart::init()
{
    mPartID = NULL;
}

MessagePart::~MessagePart()
{
    MC_SAFE_RELEASE(mPartID);
}

void MessagePart::setPartID(String * partID)
{
    MC_SAFE_REPLACE_COPY(String, mPartID, partID);
}

String * MessagePart::partID()
{
    return mPartID;
}

Object * MessagePart::copy()
{
    return new MessagePart(this);
}

static void * createObject()
{
    return new MessagePart();
}

INITIALIZE(MessagePart)
{
    Object::registerObjectConstructor("mailcore::MessagePart", &createObject);
}
