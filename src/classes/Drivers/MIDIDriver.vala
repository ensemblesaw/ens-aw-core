namespace Ensembles.ArrangerWorkstation.Drivers {
    /**
     * MIDI input / ouput host.
     */
    public class MIDIDriver : Object {
        public bool colored_input { get; construct; }

        private Fluid.Settings midi_driver_settings;
        private Fluid.MIDIDriver midi_driver;

        public MIDIDriver (bool colored_input) {
            Object (
                colored_input: colored_input
            );

            midi_driver = new Fluid.MIDIDriver (
                midi_driver_settings,
                (midi_driver_obj) => {

                    return Fluid.OK;
                },
                this
            );
        }

        construct {
            midi_driver_settings = new Fluid.Settings ();
        }


    }
}
