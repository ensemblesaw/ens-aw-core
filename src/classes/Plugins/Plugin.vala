/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Ensembles.ArrangerWorkstation.Plugins {
    /**
     * The base plugin type.
     *
     * A plugin is used to add additional functionality
     * or features to ensembles.
     */
    public abstract class Plugin : Object {
        /**
         * Name of the plugin.
         */
        public string name { get; protected set; }
        /**
         * Name of the author of this plugin.
         */
        public string author_name { get; protected set; }
        /**
         * Email address of the author of this plugin.
         */
        public string author_email { get; protected set; }
        /**
         * Homepage or the main URL of the plugin.
         */
        public string author_homepage { get; protected set; }
        /**
         * The license associated with this plugin.
         */
        public string license { get; protected set; }
        public bool has_ui { get; protected set; }

        private bool _active;

        /**
         * The plugin will only work if it's active.
         */
        public bool active {
            get {
                return _active;
            }
            set {
                _active = value;
                if (value) {
                    activate ();
                } else {
                    deactivate ();
                }
            }
        }

        protected Plugin () {
            active = false;
            instantiate ();
        }

        ~Plugin () {
            active = false;
        }

        /**
         * This function is called when the plugin is instantiated.
         * This just means that the plugin data is created. A Plugin cannot be
         * used without instantiation.
         */
        public abstract void instantiate () throws PluginError;

        protected abstract void activate ();

        protected abstract void deactivate ();
    }
}
