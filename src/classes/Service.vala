using Vinject;
using Ensembles.ArrangerWorkstation;

namespace Ensembles.Services {
    extern static Injector service;

    public ServiceToken<AWCore> aw_core;

    public void configure_aw_service (AWBuilder.AWBuilderCallback aw_builder_callback) throws VinjectErrors {
        aw_core = new ServiceToken<AWCore> ();
        var builder = new AWBuilder ();
        aw_builder_callback (builder);
        service.register_resolution<IAWCore, AWCore> (
            Services.aw_core,
            sf2_dir: builder.sf2_dir,
            sf2_name: builder.sf2_name,
            driver: builder.driver
        );

        foreach (var path in builder.style_search_paths) {
            service.obtain (aw_core).add_style_search_path (path);
        }
    }
}

namespace Ensembles.ArrangerWorkstation {
    public class AWBuilder : Object {
        internal AWCore.Driver driver = AWCore.Driver.ALSA;
        internal string sf2_dir = "~/";
        internal string sf2_name = "Ensembles";
        internal List<string> style_search_paths = new List<string> ();

        public delegate void AWBuilderCallback (AWBuilder arranger_workstation_builder);

        public AWBuilder use_driver (AWCore.Driver driver) {
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
