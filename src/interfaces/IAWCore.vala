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
        /** Use driver */
        public abstract AWCore use_driver (string driver_name);
        public abstract AWCore load_soundfont_from_path (string sf2_dir);
        public abstract AWCore load_style_from_path (string enstl_path);
        public abstract AWCore build_synth_engine ();

        /**
         * Load all data like voices, styles and plugins.
         */
        public abstract async void load_data_async ();

        /**
         * Load all data like voices, styles and plugins.
         */
        public abstract void load_data ();

        /**
         * Get a list of paths from where the styles are searched.
         */
        public abstract unowned List<string> get_style_paths ();
    }
}
