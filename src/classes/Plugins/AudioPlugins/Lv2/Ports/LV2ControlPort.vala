/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

 namespace Ensembles.ArrangerWorkstation.Plugins.AudioPlugins.Lv2 {
    public class LV2ControlPort : LV2Port {
        public float default_value { get; construct; }
        public float min_value { get; construct; }
        public float max_value { get; construct; }
        public float step { get; construct; }
        public string unit { get; construct; }
        public float[] stops { get; private set; }

        public float value;

        public LV2ControlPort (string name, uint32 index, owned string[] properties,
        string symbol, string turtle_token = "", float min_value = 0, float max_value = 1,
        float default_value = 0, float step = 0.1f, string unit = "", float[] stops = {}) {
            Object (
                name: name,
                index: index,
                properties: properties,
                symbol: symbol,
                turtle_token: turtle_token,
                default_value: default_value,
                min_value: min_value,
                max_value: max_value,
                step: step,
                unit: unit
            );

            this.stops = stops.copy ();
        }

        construct {
            value = default_value;
        }
    }
}
