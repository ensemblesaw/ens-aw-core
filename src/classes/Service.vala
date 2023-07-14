using Vinject;
using Ensembles.ArrangerWorkstation;

namespace Ensembles.Services {
    extern static Injector di_container;

    public ServiceToken<IAWCore> st_aw_core;
    public ServiceToken<AWCore.Driver> st_driver;
    public ServiceToken<string> st_sf2_name;
    public ServiceToken<string> st_sf2_dir;

    public void configure_aw_service (AWBuilder.AWBuilderCallback aw_builder_callback) throws VinjectErrors {
        st_aw_core = new ServiceToken<IAWCore> ();
        st_driver = new ServiceToken<AWCore.Driver> ();
        st_sf2_name = new ServiceToken<string> ();
        st_sf2_dir = new ServiceToken<string> ();

        var builder = new AWBuilder ();
        aw_builder_callback (builder);

        di_container.register_constant (st_driver, builder.driver);
        di_container.register_constant (st_sf2_name, builder.sf2_name);
        di_container.register_constant (st_sf2_dir, builder.sf2_dir);
        di_container.register_resolution<AWCore, IAWCore> (
            Services.st_aw_core,
            sf2_dir: st_driver,
            sf2_name: st_sf2_name,
            driver: st_sf2_dir
        );

        foreach (var path in builder.style_search_paths) {
            di_container.obtain (st_aw_core).add_style_search_path (path);
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
