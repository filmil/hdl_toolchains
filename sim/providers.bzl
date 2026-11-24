"""The data a simulator toolchain hands to the simulation rules."""

SimInfo = provider(
    doc = """A simulator, and how it spells each option on its command line.

Each spelling is a list of arguments, with placeholders in braces that the
rules fill in. A spelling of two arguments, like `["-top", "{top}"]`, adds
both.""",
    fields = {
        "executable": "File: the simulator.",
        "runfiles": "runfiles: what the simulator needs at run time.",
        "define": "list of str: one define with a value. Placeholders {name} and {value}.",
        "define_bare": "list of str: one define with no value. Placeholder {name}.",
        "incdir": "list of str: one include directory. Placeholder {dir}.",
        "top": "list of str: the top module. Placeholder {top}.",
        "plusarg": "list of str: one plusarg, given without its leading +. Placeholder {arg}.",
        "waves": "list of str: a waveform dump to a file, or [] when not supported. Placeholder {file}.",
        "waves_extension": "str: the file extension of the waveform dump, like \"fst\".",
        "extra_args": "list of str: arguments passed on every run, before the sources.",
    },
)
