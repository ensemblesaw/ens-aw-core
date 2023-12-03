namespace Ensembles.Models {
    public class MIDIDevice : Object {
        public uint8 id { get; construct; }
        public string name { get; construct; }
        public string description { get; construct; }
        public bool input { get; construct; }

        public MIDIDevice (uint8 id, string name, string description, bool input = true) {
            Object (
                id: id,
                name: name,
                description: description,
                input: input
            );
        }
    }
}
