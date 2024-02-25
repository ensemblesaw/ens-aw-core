using Ensembles.ArrangerWorkstation.AudioEngine;

namespace Ensembles.ArrangerWorkstation {
    public class AWBuilder : Object {
        internal ISynthEngine.Driver driver = ISynthEngine.Driver.ALSA;
        internal string sf2_dir = "~/";
        internal string sf2_name = "Ensembles";
        internal List<string> style_search_paths = new List<string> ();

        /*
         * The delegate below is referenced in the `Services.vala` file as
         * part of a builder pattern used for registering AWCore as a service
         * via dependency injection.
         */


        /**
         * Provides a handy way to use the builder functions.
         */
        public delegate void AWBuilderCallback (AWBuilder arranger_workstation_builder);

        public AWBuilder use_driver (ISynthEngine.Driver driver) {
            this.driver = driver;
            return this;
        }

        public AWBuilder load_soundfont_from_dir (string sf2_dir) {
            this.sf2_dir = sf2_dir;
            return this;
        }


        public AWBuilder load_soundfont_with_name (string sf2_name) {
            this.sf2_name = sf2_name;
            return this;
        }

        public AWBuilder add_style_search_path (string enstl_dir) {
            this.style_search_paths.append (enstl_dir);
            return this;
        }
    }
}
