
#include <cstddef>
#include <string>
#include <map>
#include "madmap.hpp"

template <typename T>
class MADMap {
    
public:
    std::map<T, std::string> _container;
    
    void setObject(std::string *str, T key) {
        if (str != NULL) {
            this->_container[key] = str;
            
        } else {
            this->_container.erase(key);
            
        }
    }
    
    std::string *objectAtIndex(T i) {
        typename std::map<T, std::string>::const_iterator found = this->_container.find(i);
        if (found == this->_container.end()) return NULL;
        return found->second.c_str();
    }
    
    unsigned long count() {
        return this->_container.size();

    }
    
    ~MADMap() {
        this->_container.clear();
    }

    
};

