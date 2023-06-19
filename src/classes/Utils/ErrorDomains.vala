/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Ensembles.ArrangerWorkstation {
    protected errordomain BuildError {
        MISSING_PARAMETER
    }

    protected errordomain FluidError {
        INVALID_SF
    }

    protected errordomain StyleError {
        INVALID_FILE,
        INVALID_LAYOUT,
    }

    protected errordomain PluginError {
        UNSUPPORTED_FEATURE,
        INVALID_CATEGORY
    }
}
