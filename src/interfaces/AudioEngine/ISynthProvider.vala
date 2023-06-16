namespace Ensembles.ArrangerWorkstation.AudioEngine {
    public enum SynthType {
        RENDER,
        UTILITY
    }

    public interface ISynthProvider : Object {
        /**
         * Get syntheizer instance
         *
         * @param type type of synthesizer
         */
        public abstract unowned Fluid.Synth get_synth (SynthType type);
    }
}
