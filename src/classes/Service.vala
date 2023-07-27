using Vinject;
using Ensembles.ArrangerWorkstation;

namespace Ensembles.Services {
    extern static Injector di_container;

    public ServiceToken<IAWCore> st_aw_core;
    public ServiceToken<AudioEngine.ISynthEngine.Driver> st_driver;
    public ServiceToken<string> st_sf2_name;
    public ServiceToken<string> st_sf2_dir;

    public void configure_aw_service (AWBuilder.AWBuilderCallback aw_builder_callback) throws VinjectErrors {
        st_aw_core = new ServiceToken<IAWCore> ();
        st_driver = new ServiceToken<AudioEngine.ISynthEngine.Driver> ();
        st_sf2_name = new ServiceToken<string> ();
        st_sf2_dir = new ServiceToken<string> ();

        var builder = new AWBuilder ();
        aw_builder_callback (builder);

        di_container.register_constant (st_driver, builder.driver);
        di_container.register_constant (st_sf2_name, builder.sf2_name);
        di_container.register_constant (st_sf2_dir, builder.sf2_dir);
        di_container.register_singleton <AWCore, IAWCore> (
            Services.st_aw_core,
            driver: st_driver,
            sf2_name: st_sf2_name,
            sf2_dir: st_sf2_dir
        );

        var _aw_core = di_container.obtain (st_aw_core);

        foreach (var path in builder.style_search_paths) {
            _aw_core.add_style_search_path (path);
        }
    }
}
