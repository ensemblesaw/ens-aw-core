/*
 * Copyright 2020-2023 Subhadeep Jasu <subhajasu@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
/*
 * This file incorporates work covered by the following copyright and
 * permission notices:
 *
 * ---
 *
  Copyright 2007-2022 David Robillard <http://drobilla.net>

  Permission to use, copy, modify, and/or distribute this software for any
  purpose with or without fee is hereby granted, provided that the above
  copyright notice and this permission notice appear in all copies.

  THIS SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * ---
 */

namespace Ensembles.ArrangerWorkstation.Plugins.AudioPlugins.Lv2 {
    /**
     * The LV2 Manager object manages LV2 Plugins.
     */
    public class LV2Manager : Object {
        internal static Lilv.World world = new Lilv.World ();

        internal static SyMap symap = new SyMap ();
        internal static Mutex symap_lock = Mutex ();

        internal static HashTable<string, Lilv.Node> node_map =
        new HashTable<string, Lilv.Node> (
            str_hash,
            (k1, k2) => {
                return k1 == k2;
            }
        );

        internal static LV2Options options = new LV2Options ();
        internal static LV2URIDs urids = new LV2URIDs ();
        internal static LV2Nodes nodes = new LV2Nodes (world);

        private IAWCore i_aw_core;

        public void load_plugins (IAWCore i_aw_core, PluginManager plugin_manager) {
            assert (world != null);

            this.i_aw_core = i_aw_core;

            Console.log ("Loading LV2 Plugins…");
            world.load_all ();

            var plugins = world.get_all_plugins ();

            options.sample_rate = (float) AudioEngine.SynthEngine.sample_rate;

            for (var iter = plugins.begin (); !plugins.is_end (iter); iter = plugins.next (iter)) {
                var lilv_plugin = plugins.get (iter);

                if (lilv_plugin != null) {
                    var plugin = new LV2Plugin (lilv_plugin, this);
                    plugin_manager.audio_plugins.append (plugin);

                    i_aw_core.send_loading_status (_("Loading LV2 plugin: ") + plugin.name + "…");

                    Thread.usleep (20000);
                }
            }

            Console.log (
                "LV2 Plugins Loaded Successfully!",
                Console.LogLevel.SUCCESS
            );
        }

        // LV2 Feature Implementations

        // URI -> Lilv Node Mapping
        internal static unowned Lilv.Node get_node_by_uri (string uri) {
            if (node_map.contains (uri)) {
                return node_map.get (uri);
            }

            return add_node_uri (uri);
        }

        internal static unowned Lilv.Node add_node_uri (string uri) {
            node_map.insert (uri, new Lilv.Node.uri (world, uri));
            return node_map.get (uri);
        }

        // LV2 URID
        public LV2.URID.Urid map_uri (string uri) {
            Lv2.LV2Manager.symap_lock.lock ();
            LV2.URID.Urid urid = Lv2.LV2Manager.symap.map (uri);
            Lv2.LV2Manager.symap_lock.unlock ();
            return urid;
        }

        public string unmap_uri (LV2.URID.Urid urid) {
            Lv2.LV2Manager.symap_lock.lock ();
            string uri = Lv2.LV2Manager.symap.unmap ((uint32)urid);
            Lv2.LV2Manager.symap_lock.unlock ();
            return uri;
        }

    }
}
