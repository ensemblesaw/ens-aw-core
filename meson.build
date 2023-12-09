# Project name, programming language and version
project (
    'ens-aw-core',
    'c', 'vala',
    version: '0.1.0',
    meson_version: '>=0.57.0'
)

# Translation module
i18n = import ('i18n')

# Project arguments
add_project_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    '-DG_LOG_DOMAIN="Ensembles"',
    language: 'c'
)

add_project_arguments (
    ['--vapidir', join_paths (meson.current_source_dir (), 'vapi')],
    # Set Driver Compatibilities
    '-D', 'ALSA_DRIVER',
    '-D', 'PULSEAUDIO_DRIVER',
    '-D', 'JACK_DRIVER',
    # '-D', 'PIPEWIRE_CORE_DRIVER',  # Uncomment to enable pipewire core support provided fluidsynth supports it
    language: 'vala'
)

# Listing dependencies
dependencies = [
    dependency ('gtk4'),
    dependency ('glib-2.0'),
    dependency ('gobject-2.0'),
    dependency ('gee-0.8'),
    dependency ('libsoup-3.0'),
    dependency ('json-glib-1.0'),
    dependency ('fluidsynth'),
    dependency ('gstreamer-1.0'),
    dependency ('lv2'),
    dependency ('lilv-0'),
    dependency ('suil-0'),
    dependency ('zix-0', fallback: ['zix', 'zix_dep'], default_options: [
    'tests=disabled', 'default_library=static',
    'docs=disabled', 'tests_cpp=disabled',
    ]),
    dependency ('portmidi'),
    dependency ('Vinject-0.0.0', fallback: ['libvinject', 'vinject_dep']),
    dependency ('libpipewire-0.3'),
    dependency ('ens-shell-cli-0', fallback: ['ens-shell-cli', 'ens_shell_cli_dep']),
    meson.get_compiler ('vala').find_library ('posix'),
    meson.get_compiler ('c').find_library ('m', required : true),
]

subdir ('src')

# Define library
libens_aw_core = static_library (
    meson.project_name () + '-' + meson.project_version().split('.')[0],
    sources,
    dependencies: dependencies,
    install: true,
    install_dir: [true, true, true]
)

ens_aw_core_dep = declare_dependency (
    dependencies: dependencies,
    include_directories: include_directories('.'),
    link_with: libens_aw_core
)
