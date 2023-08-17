/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Ensembles.ArrangerWorkstation.Plugins.AudioPlugins.Lv2 {
    public class LV2Port : Port {
        public string[] properties { get; construct; }
        public string symbol { get; construct; }
        public string turtle_token { get; construct; }

        public LV2Port (string name, uint32 index, owned string[] properties,
            string symbol, string turtle_token = "") {
            Object (
                name: name,
                index: index,
                symbol: symbol,
                turtle_token: turtle_token
            );
        }
    }
}
