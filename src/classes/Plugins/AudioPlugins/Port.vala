/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Ensembles.ArrangerWorkstation.Plugins.AudioPlugins {
    public class Port : Object {
        public string name { get; construct; }
        public uint32 index { get; construct; }

        public Port (string name, uint32 index) {
            Object (
                name: name,
                index: index
            );
        }
    }
}
