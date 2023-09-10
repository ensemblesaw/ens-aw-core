namespace Ensembles.ArrangerWorkstation.Plugins.AudioPlugins.Lv2 {
    public class LV2Options {
        public float sample_rate;
        public uint32 block_length = 4096U;
        public size_t midi_buffer_size = 1024U;
        //  public float ui_update_rate;
        //  public float ui_scale_factor;
    }
}
