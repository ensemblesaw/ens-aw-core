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
        public string name { get; construct; }
        /**
         * Name of the author of this plugin.
         */
        public string author_name { get; construct; }
        /**
         * Email address of the author of this plugin.
         */
        public string author_email { get; construct; }
        /**
         * Homepage or the main URL of the plugin.
         */
        public string author_homepage { get; construct; }
        /**
         * The license associated with this plugin.
         */
        public string license { get; construct; }
        /**
         * Whether the plugin can have an UI.
         */
        public bool has_ui { get; protected set construct; }

        private bool _active;

        /**
         * The plugin will only work if it's active.
         */
        public bool active {
            get {
                return _active;
            }
            set {
                if (_active != value) {
                    _active = value;
                    if (value) {
                        activate ();
                    } else {
                        deactivate ();
                    }
                }
            }
        }

        protected Plugin () {
            active = false;
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
