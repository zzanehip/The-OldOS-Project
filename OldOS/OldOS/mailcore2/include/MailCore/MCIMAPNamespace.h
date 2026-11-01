#ifndef MAILCORE_MCIMAPNAMESPACE_H

#define MAILCORE_MCIMAPNAMESPACE_H

#include <MailCore/MCBaseTypes.h>

#ifdef __cplusplus

namespace mailcore {
    
    class IMAPNamespaceItem;
    
    class MAILCORE_EXPORT IMAPNamespace : public Object {
    public:
        IMAPNamespace();
        virtual ~IMAPNamespace();
        
        virtual String * mainPrefix();
        virtual char mainDelimiter();
        
        virtual Array * /* String */ prefixes();
        
        virtual String * pathForComponents(Array * components);
        virtual String * pathForComponentsAndPrefix(Array * components, String * prefix);
        
        virtual Array * /* String */ componentsFromPath(String * path);
        
        virtual bool containsFolderPath(String * path);
        
        static IMAPNamespace * namespaceWithPrefix(String * prefix, char delimiter);
        
    public: // subclass behavior
        IMAPNamespace(IMAPNamespace * other);
        virtual String * description();
        virtual Object * copy();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);

    private:
        Array * /* String */ mItems;
        void init();
        IMAPNamespaceItem * mainItem();
        IMAPNamespaceItem * itemForPath(String * path);
        
    public: // private
        virtual void importIMAPNamespace(struct mailimap_namespace_item * item);
    };
    
}

#endif

#endif
