require_relative '../model/build.rb'
require_relative '../util/util.rb'
require_relative '../util/dsl.rb'
require 'json'

class MsvcToolchain
    include BuildDSL

    # Unlike Clang, the MSVC toolchain can only initialize for one target
    # architecture, since we need to set a lot of architecture-specific
    # variables in the environment (from vcvarsall.bat).
    #
    # Fortunately, there is no such thing as a "universal" build on Windows, so
    # we never need to build for multiple targets anyway.  (Otherwise we'd have
    # to do something funky like storing the environment for each arch and
    # applying the right one for each cl.exe invocation.)
    #
    # So for the MSVC toolchain, the architecture is needed at initialization.
    # compile() and link() still take an architecture parameter for API
    # compatibility with the clang toolchain, but it must match the
    # initialized architecture.
    def initialize(architecture, qt)
        @architecture = architecture
        @qt = qt
        @mocPath = @qt.tool('moc')
        @rccPath = @qt.tool('rcc')

        @msvcRoot = locateVisualStudio
        puts "Found VS: #{@msvcRoot}"
        vcvars = File.join(@msvcRoot, 'VC/Auxiliary/Build/vcvarsall.bat')

        # Use vcvarsall to set up the environment, locate tools, etc.
        # vcvarsall sets a lot of environment variables needed for the tools to
        # work, including SDK paths.  Use msvc_env.bat to dump the variables
        # that were set so we can include them into Rake's environment, rather
        # than requiring rake to be run from a shell where vcvarsall has already
        # been applied.
        #
        # This dump will include the variables already in Rake's environment
        # too, but there's no harm in re-applying those.
        if @architecture == :x86_64
            vcArch = 'x64'
        elsif @architecture == :arm64
            vcArch = 'x64_arm64'
        else
            raise "Unsupported arquitecture: #{@architecture}"
        end
        vcEnvScript = File.absolute_path('rake/toolchain/msvc_env.bat')
        invokeVcEnvScript = "\"#{vcEnvScript}\" \"#{vcvars}\" #{vcArch}"
        vcEnv = `#{Util.cmd(invokeVcEnvScript)}`

        vcEnv.each_line do |var|
            split = var.match(/^([^=]+)=(.*)$/)
            if(split != nil)
                ENV[split[1]] = split[2]
            end
        end

        # vcvars puts cl.exe in our PATH, it doesn't indicate the exact
        # bin/Host<arch>/<arch>/... path anywhere.
        @cl = 'cl.exe'
        # This include directory has to be passed to moc explicitly
        vcToolsDir = ENV['VCToolsInstallDir']
        if !vcToolsDir
            raise "VC Tools not installed."
        end
        @msvcInclude = File.join(vcToolsDir.gsub('\\', '/'), 'INCLUDE')
        # Grab the SDK root so we can ignore system headers in makedep
        @sdkRoot = ENV['WindowsSdkDir']
        # rc.exe is in PATH too, we don't get the exact bin/<version>/<arch>
        # path anywhere
        @rc = 'rc.exe'
    end

    # Find Visual Studio path, prefer to use the version matching the Qt build
    # Note: support for VS 2022 is experimental.
    def locateVisualStudio()
        qtVsVer = @qt.targetQtRoot.match(/msvc([0-9]+)/)[1]
        vsRoots = [File.join(ENV['ProgramFiles'].gsub('\\', '/'),
                        'Microsoft Visual Studio', "2022"),
                   File.join(ENV['ProgramFiles(x86)'].gsub('\\', '/'),
                        'Microsoft Visual Studio', "2019")].sort { |path| path.end_with?(qtVsVer) ? 0 : 1 }
        vsRoot = vsRoots[0]
        # Keep the first valid VS installation we find
        for root in vsRoots
            vsEdition = Util.find(['Professional','Community','BuildTools','Enterprise']) do |e|
                File.exist?(File.join(root, e))
            end
            if vsEdition
                vsRoot = root
                break
            end
        end
        if !vsEdition
            raise "Could not locate a valid VS installation"
        end
        File.join(vsRoot, vsEdition)
    end

    # Within compile() or link(), check that the arch specified was the one that
    # was initialized.
    def checkInitializedArchitecture(architecture)
        raise "MSVC can only target one architecture per build" if architecture != @architecture
    end

    # Get platform-specific file extensions
    def targetExt(type)
        return '.dll' if type == :dynamic
        return '.lib' if type == :static
        return '.exe' if type == :executable
    end
    def symlinkExts(type)
        [] # Doesn't apply on Windows
    end
    # The object file extension may depend on the type of source file (on
    # Windows, resource scripts (.rc) compile to .res objects)
    def objectExt(sourceFile)
        if(File.extname(sourceFile) == '.rc')
            return '.res'
        end
        '.obj'
    end
    # Check if a file is an object file of any type
    def isObjectFile?(sourceFile)
        ext = File.extname(sourceFile)
        ext == '.obj' || ext == '.res'
    end

    # Macros that are always defined when compiling for Windows
    WinMacros = [
        'UNICODE',
        '_UNICODE',
        'WIN32',
        'WINAPI_FAMILY=WINAPI_FAMILY_DESKTOP_APP',
        'NTDDI_VERSION=NTDDI_WIN7',
        'WINVER=0x0601',
        '_WIN32_WINNT=0x0601',
        '_WIN32_WINDOWS=0x0601'
    ]

    # Macros that depend on variant
    VariantMacros = {
        debug: [
            'PIA_DEBUG'
        ],
        release: [
            'NDEBUG',
            'QT_NO_DEBUG'
        ]
    }
    CompileOpts = {
        debug: [
            '/Od', # Disable optimizations
            '/bigobj' # Some debug objects exceed default section count limit
        ],
        release: [
            '/O2', # Optimize for speed
            '/GL' # Enable whole program optimization
        ]
    }
    LinkOpts = {
        debug: [
            # Reference private symbols from executable instead of moving to
            # PDB - links faster, but limited PDB requires build products to
            # debug.  (New default in VS2017+ for debug builds)
            '/DEBUG:FASTLINK'
        ],
        release: [
            '/DEBUG:FULL', # Move all debugging information to PDB
            '/OPT:REF', # Remove unreferenced sections
            '/OPT:ICF', # Identical COMDAT folding
            '/LTCG' # Enable link-time code generation (related to /GL above)
        ]
    }
    # Arguments for lib.exe
    StaticLinkOpts = {
        debug: [
        ],
        release: [
            '/LTCG' # Enable link-time code generation (related to /GL above)
        ]
    }

    # MSVC has multiple versions of the runtime library:
    # https://docs.microsoft.com/en-us/cpp/build/reference/md-mt-ld-use-run-time-library?view=vs-2019
    #
    # /MT, /MTd - statically link the runtime library
    # /MD, /MDd - dynamically link the runtime library
    #
    # The 'd' suffix indicates to use the debug version of the runtime library.
    def msvcRuntimeArg(runtime)
        if(Build::Variant == :release)
            if(runtime == :static)
                '/MT'   # Static release lib
            else
                '/MD'   # Dynamic release lib
            end
        else
            if(runtime == :static)
                '/MTd'  # Static debug lib
            else
                '/MDd'  # Dynamic debug lib
            end
        end
    end

    # Quotes a single argument appropriately for CommandLineToArgvW(), which is
    # used by most Windows programs to parse arguments (but _not_ cmd.exe in
    # particular).
    #
    # The processing of quotes and backslashes is finicky to compromise with
    # Windows backlash directory separators.  Backslashes are treated normally
    # _except_ when followed by "; all consecutive backslashes leading up to "
    # are treated as escape sequences.  So, we need to double all consecutive
    # backslashes preceding quotation marks, _without_ doubling backslashes
    # elsewhere.
    def winQuoteArg(arg)
        # If it doesn't contain spaces or quotes, there's nothing to do, leave
        # it alone.
        if !(arg.include?(' ') || arg.include?('"'))
            return arg
        end
        # Capture backslashes preceding each quotation mark and double them.
        # Surround the resulting string with quotes, and escape the quotation
        # marks.
        "\"#{arg.gsub(/(\\*)"/, '\1\1\\"')}\""
    end

    # Quote and join an array of arguments into a Windows-style command line
    def winJoinArgs(args)
        args.map{ |arg| winQuoteArg(arg) }.join(' ')
    end

    # No support for code coverage with MSVC
    def coverageAvailable?
        false
    end

    def toolchainPath
        @msvcRoot
    end

    # Apply moc to a source or header file.  All paths should be absolute paths.
    # frameworkPaths is ignored on MSVC.
    def moc(architecture, sourceFile, outputFile, macros, includeDirs, frameworkPaths)
        checkInitializedArchitecture(architecture)
        params = [
            @mocPath,
            WinMacros.map { |m| "-D#{m}" },
            macros.map { |m| "-D#{m}" },
            includeDirs.map { |d| "-I#{d}" },
            # Has to be given explicitly for moc, but not cl
            "-I#{@msvcInclude}",
            '-o', outputFile,
            sourceFile
        ]
        params.flatten!
       Util.shellRun winJoinArgs(params)
    end

    # Invoke rcc to compile QRC resources to a source file
    def rcc(sourceFile, outputFile, name)
        params = [
            @rccPath,
            sourceFile,
            '-name', name,
            '-o', outputFile
        ]
       Util.shellRun winJoinArgs(params)
    end

    class MakedepWriter
        def initialize(depFile, objectFile, sourceFile, excludeRoots)
            @depFile = depFile
            @depFile.write("#{objectFile}: \\\n")
            @depFile.write(" #{sourceFile}")

            # Normalize these directory prefixes to check against header paths -
            # lowercase and use '/' for all separators.
            # Rake's makefile import doesn't allow us to use backslashes (they
            # can't be escaped reliably), and Rake mainly uses '/' anyway.
            @excludeRoots = excludeRoots.map{ |r| r.downcase.gsub('\\', '/') }
        end

        def addDep(path)
            pathNorm = path.downcase.gsub('\\', '/')
            # Ignore excluded roots - the MSVC, Windows SDK, or Qt.  These
            # rarely change, and there are a _lot_ of them, so they cause the
            # Rakefile to take ~15-20 seconds to load even on a fast machine.
            if(!@excludeRoots.any?{ |r| pathNorm.start_with?(r) })
                # Escape spaces.  Rake's makefile import does support this.
                @depFile.write(" \\\n #{pathNorm.gsub(' ', '\\ ')}")
            end
        end
    end

    def openMakedep(depFile, objectFile, sourceFile, &block)
        File.open(depFile, 'w') do |f|
            writer = MakedepWriter.new(f, objectFile, sourceFile,
                                       [@msvcRoot, @sdkRoot, @qt.targetQtRoot])
            block.call(writer)
        end
    end

    # Generate Makefile-style dependencies for a source file without compiling,
    # using cl.exe.
    #
    # This is used for resource scripts.  rc.exe doesn't have anything like
    # /showIncludes.  The preprocessors aren't identical
    # (https://devblogs.microsoft.com/oldnewthing/20171004-00/?p=97126), but it
    # should be close enough for this purpose.
    def clMakedep(sourceFile, objectFile, depFile, macros, includeDirs, useUtf8)
        params = [
            # Preprocess only, and ignore preprocessed output
            Build::CompilerLauncher, @cl, '/nologo', '/P', '/showIncludes', '/FiNUL',
            WinMacros.map { |m| "/D#{m}" },
            VariantMacros[Build::Variant].map { |m| "/D#{m}" },
            macros.map { |m| "/D#{m}" },
            includeDirs.map { |d| "/I#{d}" },
            sourceFile,
            '/utf-8',
        ].compact
        # '/utf-8' is omitted for .rc files, which are usually in UTF-16 with a
        # BOM for rc.exe
        if(useUtf8)
            params << '/utf-8'
        end
        params.flatten!
        preprocOutput = `#{winJoinArgs(params)} 2>&1`
        openMakedep(depFile, objectFile, sourceFile) do |w|
            lineRegex = /\ANote: including file: +(.*)\Z/

            preprocOutput.each_line do |l|
                match = lineRegex.match(l)
                if(match != nil)
                    # It's an "including file" line, write out a dependency
                    w.addDep(match[1])
                end
            end
        end
    end

    # Compile a source file with cl.exe
    def clCompile(sourceFile, objectFile, depFile, macros, includeDirs, runtime)
        params = [
            Build::CompilerLauncher, @cl, '/nologo',
            '/c', # Compile only, don't link
            msvcRuntimeArg(runtime), # Specify runtime variant
            '/Zi', # Generate separate PDB file
            '/EHsc', # C++ stack unwinding; extern "C" functions can't throw
            # Omit /TP or /TC, let cl.exe decide source type based on extension
            '/std:c++17', # Use C++17
            '/Zc:rvalueCast', # Use proper type conversion conformance
            '/utf-8', # Source and target charsets are UTF-8
            '/we4834', # Discarding value marked [nodiscard] is an error
            CompileOpts[Build::Variant],
            WinMacros.map { |m| "/D#{m}" },
            VariantMacros[Build::Variant].map { |m| "/D#{m}" },
            macros.map { |m| "/D#{m}" },
            includeDirs.map { |d| "/I#{d}" },
            # Generate JSON output containing source dependencies, which we'll
            # transform to a Makefile-formatted header dependency file.
            # This option was added in VS 16.7.  If you get an error that the
            # option is not recognized, update VS.
            '/sourceDependencies', depFile + '.json',
            '/Fd' + objectFile.ext('.pdb'),
            '/Fo' + objectFile,
            File.absolute_path(sourceFile) # Absolute path allows Qt Creator to open files from diagnostics
        ]
        params += ['/Zc:__cplusplus', '/permissive-']
        params = params.compact
        params.flatten!
        Util.shellRun winJoinArgs(params)
        CompilerDatabase.create_fragment(sourceFile, objectFile, params)

        # Transform the headers from the JSON source dependency output to a
        # Makefile that Rake can import
        sourceDeps = JSON.parse(File.read(depFile + '.json'))
        openMakedep(depFile, objectFile, sourceFile) do |w|
            sourceDeps['Data']['Includes'].each { |i| w.addDep(i) }
        end
    end

    # Compile a resource script with rc.exe
    def rcCompile(sourceFile, objectFile, macros, includeDirs)
        params = [
            @rc, '/nologo',
            WinMacros.flat_map { |m| ['/d', m] },
            VariantMacros[Build::Variant].flat_map { |m| ['/d', m] },
            macros.flat_map { |m| ['/d', m] },
            includeDirs.flat_map { |d| ['/I', d] },
            '/FO', objectFile, sourceFile
        ]
        params.flatten!
        Util.shellRun winJoinArgs(params)
    end

    # Compile one source file to an object file.  All paths should be absolute
    # paths.
    #
    # - sourceFile - path to the source file to compile, for MSVC this can be a
    #   .c, .cpp, or .rc file (resouce scripts compile to .res objects with
    #   rc.exe)
    # - objectFile - path to the object file, use objectExt(sourceFile) to
    #   obtain the proper extension
    # - depFile - path to a Makefile-style dependency file that will be written
    #   listing the headers used to compile this file.  System and Qt headers
    #   are ignored in order to speed up rakefile loads.
    # - macros - array of macros to define, of the form 'NAME' or 'NAME=VALUE'
    # - includeDirs - array of include directories to use when compiling this
    #   file
    # - frameworkPaths - ignored for MSVC
    # - options - target options specified by Executable.  :runtime is used in
    #   this step
    def compile(architecture, sourceFile, objectFile, depFile, macros,
                includeDirs, frameworkPaths, options)
        checkInitializedArchitecture(architecture)

        if(File.extname(sourceFile) == '.rc')
            # Use cl to do a makedep for resource files - see clMakedep()
            clMakedep(sourceFile, objectFile, depFile, macros, includeDirs, false)
            rcCompile(sourceFile, objectFile, macros, includeDirs)
        else
            clCompile(sourceFile, objectFile, depFile, macros, includeDirs,
                      options[:runtime])
        end
    end

    def decorateCFunction(symbol)
        # On x86, MSVC does decorate C-linkage functions using calling
        # convention (only).  Assume the function is __cdecl, which is the
        # default (it just gets a leading underscore).
        return "_#{symbol}" if Build::TargetArchitecture == :x86
        return symbol
    end

    def clLink(targetFile, objFiles, libPaths, libs, interface,
               forceLinkSymbols, extraArgs)
        subsys = 'WINDOWS'
        if(interface == :console)
            subsys = 'CONSOLE'
        elsif(interface != :gui)
            raise "Unknown target interface: #{interface}"
        end
        params = [
            Build::CompilerLauncher,
            @cl,
            '/nologo',
            objFiles,
            libs.map { |l| "#{l}.lib" },
            '/Fe' + targetFile,
            '/link', # Link only
            LinkOpts[Build::Variant],
            '/OSVERSION:10.00',
            "/SUBSYSTEM:#{subsys},10.00",
            '/INCREMENTAL:NO',
            '/MANIFEST:EMBED', # Embed app manifest in image
            "/MANIFESTINPUT:#{File.absolute_path('common/res/manifest.xml')}",
            "/PDB:#{targetFile.ext('.pdb')}",
            libPaths.map { |l| "/LIBPATH:#{l}" },
            forceLinkSymbols.map { |s| "/INCLUDE:#{decorateCFunction(s)}" },
            extraArgs
        ].compact
        params.flatten!
       Util.shellRun winJoinArgs(params)
    end

    # Link a dynamic library or executable.
    # - architecture - Desired target architecture.
    # - targetFile - Absolute path to the target DLL or EXE to build
    # - objFiles - Compiled object files
    # - libPaths - Library search paths
    # - libs - Names of libraries to link (not including '.lib' suffix)
    # - frameworkPaths - ignored for MSVC
    # - frameworks - ignored for MSVC
    # - extraArgs - Extra arguments for the linker (passed through cl via /link)
    # - options - Target options specified by Executable.  :type and :interface
    #   are used in this step.
    def link(architecture, targetFile, objFiles, libPaths, libs, frameworkPaths,
             frameworks, extraArgs, options)
        checkInitializedArchitecture(architecture)

        if(options[:type] == :dynamic)
            clLink(targetFile, objFiles, libPaths, libs, options[:interface],
                   options[:forceLinkSymbols],
                   ['/DLL', "/IMPLIB:#{targetFile.ext('.lib')}"] + extraArgs)
        elsif(options[:type] == :static)
           Util.shellRun('lib.exe', '/nologo', *StaticLinkOpts[Build::Variant],
               "/OUT:#{targetFile}", *objFiles)
        elsif(options[:type] == :executable)
            clLink(targetFile, objFiles, libPaths, libs, options[:interface],
                   options[:forceLinkSymbols], extraArgs)
        else
            raise "Unknown target type: #{options[:type]}"
        end
    end
end
