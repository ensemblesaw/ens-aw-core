/*
 * Copyright 2020-2023 Subhadeep Jasu <subhadeep107@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Ensembles.ArrangerWorkstation {
    /**
     * ## Arranger Workstation
     *
     * This forms the core of the app. This houses all the behind the scenes
     * stuff that make every beat beat and every sound sound.
     */
    public interface IAWCore : Object {
        // Signals
        /** Signals when the arranger is done loading data. */
        public signal void ready();
        /** Sends verbose status for loading screen. */
        public signal void send_loading_status(string status);

        public abstract AWCore load_soundfont_from_path (string sf2_dir);

        public abstract AWCore load_style_from_path (string enstl_path);

        /**
         * Load all data like voices, styles and plugins
         */
        public abstract async void load_data_async ();

        /**
         * Load all data like voices, styles and plugins
         */
        public abstract void load_data ();

        public abstract unowned List<string> get_style_paths ();
    }
}
