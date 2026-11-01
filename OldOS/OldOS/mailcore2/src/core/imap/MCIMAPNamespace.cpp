#include "MCIMAPNamespace.h"

#include "MCDefines.h"
#include "MCIMAPNamespaceItem.h"

#include <libetpan/libetpan.h>

using namespace mailcore;

void IMAPNamespace::init()
{
    mItems = NULL;
}

IMAPNamespace::IMAPNamespace()
{
    init();
    mItems = new Array();
}

IMAPNamespace::IMAPNamespace(IMAPNamespace * other)
{
    init();
    mItems = (Array *) other->mItems->copy();
}

IMAPNamespace::~IMAPNamespace()
{
    MC_SAFE_RELEASE(mItems);
}

String * IMAPNamespace::description()
{
    String * result = String::string();
    result->appendUTF8Format("<%s:%p %s>", MCUTF8(className()), this,
        MCUTF8DESC(mItems));
    return result;
}

Object * IMAPNamespace::copy()
{
    return new IMAPNamespace(this);
}

IMAPNamespaceItem * IMAPNamespace::mainItem()
{
    if (mItems->count() == 0)
        return NULL;
    
    return (IMAPNamespaceItem *) mItems->objectAtIndex(0);
}

IMAPNamespaceItem * IMAPNamespace::itemForPath(String * path)
{
    for(unsigned int i = 0 ; i < mItems->count() ; i ++) {
        IMAPNamespaceItem * item = (IMAPNamespaceItem *) mItems->objectAtIndex(i);
        if (item->containsFolder(path))
            return item;
    }
    
    return NULL;
}

String * IMAPNamespace::mainPrefix()
{
    if (mItems->count() == 0)
        return NULL;
    
    return mainItem()->prefix();
}

char IMAPNamespace::mainDelimiter()
{
    if (mItems->count() == 0)
        return 0;
    
    return mainItem()->delimiter();
}

Array * IMAPNamespace::prefixes()
{
    Array * result = Array::array();
    for(unsigned int i = 0 ; i < mItems->count() ; i ++) {
        IMAPNamespaceItem * item = (IMAPNamespaceItem *) mItems->objectAtIndex(i);
        result->addObject(item->prefix());
    }
    return result;
}

String * IMAPNamespace::pathForComponents(Array * components)
{
    return mainItem()->pathForComponents(components);
}

String * IMAPNamespace::pathForComponentsAndPrefix(Array * components, String * prefix)
{
    IMAPNamespaceItem * item = itemForPath(prefix);
    if (item == NULL)
        return NULL;
    return item->pathForComponents(components);
}

Array * IMAPNamespace::componentsFromPath(String * path)
{
    IMAPNamespaceItem * item = itemForPath(path);
    if (item == NULL)
        return NULL;
    return item->componentsForPath(path);
}

bool IMAPNamespace::containsFolderPath(String * path)
{
    return (itemForPath(path) != NULL);
}

IMAPNamespace * IMAPNamespace::namespaceWithPrefix(String * prefix, char delimiter)
{
    IMAPNamespace * ns;
    IMAPNamespaceItem * item;
    
    ns = new IMAPNamespace();
    item = new IMAPNamespaceItem();
    item->setDelimiter(delimiter);
    item->setPrefix(prefix);
    ns->mItems->addObject(item);
    item->release();
    
    return (IMAPNamespace *) ns->autorelease();
}

void IMAPNamespace::importIMAPNamespace(struct mailimap_namespace_item * item)
{
    clistiter * cur;
    
    for(cur = clist_begin(item->ns_data_list) ; cur != NULL ; cur = clist_next(cur)) {
        IMAPNamespaceItem * item;
        struct mailimap_namespace_info * info;
        
        info = (struct mailimap_namespace_info *) clist_content(cur);
        item = new IMAPNamespaceItem();
        item->importIMAPNamespaceInfo(info);
        mItems->addObject(item);
        item->release();
    }
}

HashMap * IMAPNamespace::serializable()
{
    HashMap * result = Object::serializable();
    result->setObjectForKey(MCSTR("items"), mItems->serializable());
    return result;
}

void IMAPNamespace::importSerializable(HashMap * serializable)
{
    Array * items = (Array *) Object::objectWithSerializable((HashMap *) serializable->objectForKey(MCSTR("items")));
    MC_SAFE_REPLACE_RETAIN(Array, mItems, items);
}

static void * createObject()
{
    return new IMAPNamespace();
}

INITIALIZE(IMAPNamespace)
{
    Object::registerObjectConstructor("mailcore::IMAPNamespace", &createObject);
}
