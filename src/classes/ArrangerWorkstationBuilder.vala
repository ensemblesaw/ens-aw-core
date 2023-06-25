namespace Ensembles.ArrangerWorkstation {
    public class ArrangerWorkstationBuilder {
        internal string driver_name;
        internal string sf2_dir;
        internal string sf2_name;
        internal string[] enstl_search_paths;

        public ArrangerWorkstationBuilder using_driver (string driver_name) {
            this.driver_name = driver_name;
            return this;
        }

        public ArrangerWorkstationBuilder load_sf_from (string path, string? name = "EnsemblesGM") {
            sf2_dir = path;
            sf2_name = name;
            return this;
        }

        public ArrangerWorkstationBuilder add_style_search_path (string path) {
            if (enstl_search_paths == null) {
                enstl_search_paths = new string[0];
            }

            enstl_search_paths.resize (enstl_search_paths.length + 1);
            enstl_search_paths[enstl_search_paths.length - 1] = path;
            return this;
        }
    }
}
