interfaces = files(
    'interfaces/IAWCore.vala',
    'interfaces/AudioEngine/ISynthEngine.vala',
    'interfaces/Analysers/IVoiceAnalyser.vala',
    'interfaces/FileLoaders/IStyleFileLoader.vala',
    'interfaces/MIDIPlayers/IStyleEngine.vala'
)

classes = files (
    # Builder
    'classes/AWBuilder.vala',
    # Service
    'classes/Service.vala',
    # Core facade
    'classes/AWCore.vala',

    # Audio engine
    'classes/AudioEngine/SynthEngine.vala',
    'classes/AudioEngine/SynthSettings.vala',
    'classes/AudioEngine/SynthModPresets.vala',

    # Drivers
    'classes/Drivers/MIDIDriver.vala',

    # Analysers
    'classes/Analysers/ChordAnalyser.vala',
    'classes/Analysers/StyleAnalyser.vala',
    'classes/Analysers/VoiceAnalyser.vala',

    # File loaders
    'classes/FileLoaders/StyleFileLoader.vala',

    # MIDI players
    'classes/MIDIPlayers/StyleEngine.vala',

    # Utilities
    'classes/Utils/ErrorDomains.vala',
    'classes/Utils/StyleMIDIModifiers.vala',
    'classes/Utils/MIDI.vala',
    'classes/Utils/Math.vala',

    # Models
    'classes/Models/Chord.vala',
    'classes/Models/Registry.vala',
    'classes/Models/Voice.vala',
    'classes/Models/Style.vala',
    'classes/Models/StylePart.vala',
    'classes/Models/MIDIEvent.vala',

    # Plugins
    'classes/Plugins/Plugin.vala',
    'classes/Plugins/PluginManager.vala',

    # Audio Plugins
    'classes/Plugins/AudioPlugins/AudioPlugin.vala',
    'classes/Plugins/AudioPlugins/Port.vala',

    # Plugin Racks
    'classes/Racks/Rack.vala',
    'classes/Racks/DSPRack.vala',
    'classes/Racks/VoiceRack.vala',

    # LV2 Plugins
    'classes/Plugins/AudioPlugins/Lv2/LV2Manager.vala',
    'classes/Plugins/AudioPlugins/Lv2/LV2Plugin.vala',
    'classes/Plugins/AudioPlugins/Lv2/LV2SyMap.vala',
    'classes/Plugins/AudioPlugins/Lv2/LV2EvBuf.vala',
    'classes/Plugins/AudioPlugins/Lv2/LV2Worker.vala',
    'classes/Plugins/AudioPlugins/Lv2/LV2PortAnalyser.vala',
    'classes/Plugins/AudioPlugins/Lv2/Ports/LV2Port.vala',
    'classes/Plugins/AudioPlugins/Lv2/Ports/LV2ControlPort.vala',
    'classes/Plugins/AudioPlugins/Lv2/Ports/LV2AtomPort.vala'
)


sources = [interfaces, classes]
