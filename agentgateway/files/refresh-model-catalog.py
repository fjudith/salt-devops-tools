#!/usr/bin/env python3
# Managed by Salt. Do not edit.
"""Download the agentgateway model cost catalog and write a copy that the
installed agentgateway binary can load.

The published catalog is generated for the newest agentgateway. Older binaries
reject the whole file when it has a service tier they don't know (for example
"fast"). Pricing tiers whose serviceTier is not in KNOWN_TIERS are dropped, so
those models are billed at their base rate. Fields the binary doesn't know
are removed as well.

Usage: refresh-model-catalog.py <output-file> [url]
"""
import json
import os
import sys
import tempfile
import urllib.request

KNOWN_TIERS = {"standard", "flex", "priority", "reserved"}
DEFAULT_URL = "https://agentgateway.dev/model-catalog"

# Fields understood by agentgateway 1.7.x. Anything else is removed because the
# binary refuses to load a catalog that contains unknown fields.
RATES = {"input", "output", "cacheRead", "cacheWrite", "cacheWriteDetails", "reasoning",
         "inputAudio", "outputAudio", "perPage", "perAudioMinute"}
MODEL = {"name", "status", "released", "rates", "tiers", "tags", "limits", "modalities",
         "capabilities", "reasoning"}
LIMITS = {"context", "input", "output"}
MODALITIES = {"input", "output"}
CAPABILITIES = {"reasoning", "structuredOutput", "toolCall", "temperature"}
REASONING = {"toggle", "effort", "budgetTokens"}
BUDGET = {"min", "max"}
TIER = {"contextOver", "serviceTier", "rates"}
SUBSECTIONS = {"rates": RATES, "limits": LIMITS, "modalities": MODALITIES,
               "capabilities": CAPABILITIES}


def keep(obj, allowed):
    return {k: v for k, v in obj.items() if k in allowed}


def sanitize_model(model):
    dropped = len(model) - len(keep(model, MODEL))
    model = keep(model, MODEL)
    for name, allowed in SUBSECTIONS.items():
        if isinstance(model.get(name), dict):
            model[name] = keep(model[name], allowed)
    reasoning = model.get("reasoning")
    if isinstance(reasoning, dict):
        reasoning = keep(reasoning, REASONING)
        if isinstance(reasoning.get("budgetTokens"), dict):
            reasoning["budgetTokens"] = keep(reasoning["budgetTokens"], BUDGET)
        model["reasoning"] = reasoning
    tiers = []
    for tier in model.get("tiers", []):
        # Tiers with conditions this version cannot apply must be dropped.
        if set(tier) - TIER or tier.get("serviceTier", "standard") not in KNOWN_TIERS:
            dropped += 1
            continue
        if isinstance(tier.get("rates"), dict):
            tier["rates"] = keep(tier["rates"], RATES)
        tiers.append(tier)
    if tiers:
        model["tiers"] = tiers
    else:
        model.pop("tiers", None)
    return model, dropped


def sanitize(catalog):
    dropped = 0
    out = {"providers": {}}
    if isinstance(catalog.get("metadata"), dict):
        out["metadata"] = keep(catalog["metadata"], {"source", "generatedAt"})
    for pname, provider in catalog.get("providers", {}).items():
        models = {}
        for mname, model in provider.get("models", {}).items():
            models[mname], d = sanitize_model(model)
            dropped += d
        out["providers"][pname] = {"models": models}
    return out, dropped


def main():
    out = sys.argv[1]
    url = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_URL
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "salt-agentgateway/1.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            catalog = json.load(resp)
    except Exception as exc:  # network or JSON error
        print("changed=no comment='fetch failed: %s'" % exc)
        return 0 if os.path.exists(out) else 1
    catalog, dropped = sanitize(catalog)
    data = json.dumps(catalog, indent=2).encode() + b"\n"
    if os.path.exists(out):
        with open(out, "rb") as fh:
            if fh.read() == data:
                print("changed=no comment='catalog up to date'")
                return 0
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(out), prefix=".catalog-")
    with os.fdopen(fd, "wb") as fh:
        fh.write(data)
    os.chmod(tmp, 0o644)
    os.replace(tmp, out)
    print("changed=yes comment='catalog updated, dropped %d unsupported entries'" % dropped)
    return 0


if __name__ == "__main__":
    sys.exit(main())
