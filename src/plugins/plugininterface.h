#pragma once

class PluginInterface
{
public:
    virtual ~PluginInterface() = default;
    virtual const char* name() const = 0;
    virtual bool isAvailable() const = 0;
};
