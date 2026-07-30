#pragma once

#include "../ilogooverlayplugin.h"
#include "../ibatchgenerationplugin.h"
#include "../ipdfexportplugin.h"

class StubLogoOverlayPlugin final : public ILogoOverlayPlugin
{
public:
    const char* name() const override { return "logo-overlay-stub"; }
    bool isAvailable() const override { return false; }
};

class StubBatchGenerationPlugin final : public IBatchGenerationPlugin
{
public:
    const char* name() const override { return "batch-generation-stub"; }
    bool isAvailable() const override { return false; }
};

class StubPdfExportPlugin final : public IPdfExportPlugin
{
public:
    const char* name() const override { return "pdf-export-stub"; }
    bool isAvailable() const override { return false; }
};
