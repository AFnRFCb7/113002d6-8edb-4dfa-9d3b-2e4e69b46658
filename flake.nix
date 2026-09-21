{
    inputs = { } ;
    outputs = { self } :
	    {
	        lib =
	            {
	                failure ,
	                lazy-shell-application
                } :
                    let
                        implementation =
                            { config , lib , pkgs , ... } :
                                let
                                    implementation-parameters =
                                        {
                                            config = config ;
                                            lib = lib ;
                                            pkgs = pkgs ;
                                        } ;
                                    in
                                        {
                                            config =
                                                {
                                                    environment.systemPackages = [
                                                        implementation-parameters.config.sally.download-dependencies.services.server
                                                    ] ;
                                                    environment.variables =
                                                        {
                                                            # SALLY = implementation-parameters.config.sally.frontend.mobile.package ;
                                                            DOWNLOAD_NODE = implementation-parameters.config.sally.download-dependencies.services.server ;
                                                        } ;
                                                    systemd =
                                                        {
                                                            services =
                                                                implementation-parameters.lib.mkIf
                                                                    implementation-parameters.config.sally.services.enable
                                                                        {
                                                                            sally-server =
                                                                                implementation-parameters.lib.mkIf
                                                                                    implementation-parameters.config.sally.services.server.enable
                                                                                    {
                                                                                        after = [ "network.target" ] ;
                                                                                        name = "${ implementation-parameters.config.sally.services.server.name }.service" ;
                                                                                        serviceConfig =
                                                                                            {
                                                                                                DynamicUser = true ;
                                                                                                ExecStart =
                                                                                                    let
                                                                                                        application =
                                                                                                            root-parameters.lazy-shell-application
                                                                                                                {
                                                                                                                    name = "ExecStart" ;
                                                                                                                    mounts = { sally = { source = "/run/sally" ; type = "bind" ; } ; } ;
                                                                                                                    post = null ;
                                                                                                                    runtime-inputs = pkgs : [ pkgs.nodejs ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            node /mounts/sally/server.js ${ builtins.toString config.sally.services.server.port }
                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        in "${ application }/bin/ExecStart" ;
                                                                                                RuntimeDirectory = "sally" ;
                                                                                            } ;
                                                                                        wantedBy = [ "multi-user.target" ] ;
                                                                                    } ;
                                                                        } ;
                                                        } ;
                                                } ;
                                            options =
                                                {
                                                    sally =
                                                        {
                                                            download-dependencies =
                                                                {
                                                                    services =
                                                                        {
                                                                            server =
                                                                                implementation-parameters.lib.mkOption
                                                                                    {
                                                                                        default =
                                                                                            implementation-parameters.pkgs.writeShellApplication
                                                                                                {
                                                                                                    name = "dependencies" ;
                                                                                                    runtimeInputs = [ pkgs.git pkgs.nodejs ] ;
                                                                                                    text =
                                                                                                        let
                                                                                                            package =
                                                                                                                {
                                                                                                                    dependencies =
                                                                                                                        {
                                                                                                                            express = "^5.1.0" ;
                                                                                                                        } ;
                                                                                                                } ;
                                                                                                            in
                                                                                                                ''
                                                                                                                    cat ${ builtins.toFile "package.json" ( builtins.toJSON package ) } > package.json
                                                                                                                    npm install
                                                                                                                    git add node_modules
                                                                                                                    git commit -m "$@" --allow-empty
                                                                                                                '' ;
                                                                                                } ;
                                                                                        type = implementation-parameters.lib.types.package ;
                                                                                    } ;
                                                                        } ;
                                                                } ;
#                                                            frontend =
#                                                                {
#                                                                    mobile =
#                                                                        {
#                                                                            download =
#                                                                                implementation-parameters.lib.mkOption
#                                                                                    {
#                                                                                        default =
#                                                                                            implementation-parameters.pkgs.writeShellApplication
#                                                                                                {
#                                                                                                    name = "download" ;
#                                                                                                    runtimeInputs =
#                                                                                                        [
#                                                                                                            implementation-parameters.pkgs.coreutils
#                                                                                                            implementation-parameters.pkgs.findutils
#                                                                                                            implementation-parameters.pkgs.gradle
#                                                                                                            ( failure 4734451342324564 )
#                                                                                                        ] ;
#                                                                                                        text =
#                                                                                                            ''
#                                                                                                                GRADLE_USER_HOME="$( mktemp --dry-run )" || failure 6182679945594691
#                                                                                                                export GRADLE_USER_HOME
#                                                                                                                trap "rm --recursive --force $GRADLE_USER_HOME" EXIT
#                                                                                                                rm --recursive --force "$GRADLE_USER_HOME"
#                                                                                                                gradle assembleDebug
#                                                                                                                rm -rf gradle-dependencies
#                                                                                                                mkdir --parents gradle-dependencies
#                                                                                                                cp --recursive "$GRADLE_USER_HOME/caches/modules-2" gradle-dependencies/
#                                                                                                                find gradle-dependencies \
#                                                                                                                    -type f \
#                                                                                                                    \( -name '*.lock' -o -name 'gc.properties' \) \
#                                                                                                                    -delete
#                                                                                                            '' ;
#                                                                                                } ;
#                                                                                        type = implementation-parameters.lib.types.package ;
#                                                                                    } ;
#                                                                            package =
#                                                                                implementation-parameters.lib.mkOption
#                                                                                    {
#                                                                                        default =
#                                                                                            let
#                                                                                                androidComposition =
#                                                                                                    implementation-parameters.pkgs.androidenv.composeAndroidPackages
#                                                                                                        {
#                                                                                                            platformVersions = [ "35" ] ;
#                                                                                                            buildToolsVersions = [ "35.0.0" ] ;
#                                                                                                        } ;
#
#                                                                                                androidSdk =
#                                                                                                    androidComposition.androidsdk ;
#                                                                                                in
#                                                                                                    implementation-parameters.pkgs.runCommand
#                                                                                                        "sally"
#                                                                                                        {
#                                                                                                            nativeBuildInputs =
#                                                                                                                [
#                                                                                                                    implementation-parameters.pkgs.findutils
#                                                                                                                    androidSdk
#                                                                                                                    implementation-parameters.pkgs.coreutils
#                                                                                                                    implementation-parameters.pkgs.gradle
#                                                                                                                    ( failure 1862736323979915 )
#                                                                                                                ] ;
#                                                                                                        }
#                                                                                                        ''
#                                                                                                            WORK_DIR="$( mktemp --directory )" || failure 3113983533329552
#                                                                                                            cd "$WORK_DIR"
#                                                                                                            cp --recursive ${ ./frontend/mobile }/* .
#                                                                                                            find . >&2
#                                                                                                            gradle assembleDebug
#                                                                                                            mkdir --parents $out
#                                                                                                            cp app/build/outputs/apk/debug/app-debug.apk $out/
#                                                                                                        '' ;
#                                                                                        type = implementation-parameters.lib.types.package ;
#                                                                                    } ;
#                                                                        } ;
#                                                                } ;
                                                            services =
                                                                {
                                                                    enable = implementation-parameters.lib.mkOption { default = true ; type = lib.types.bool ; } ;
                                                                    server =
                                                                        {
                                                                            enable = implementation-parameters.lib.mkOption { default = true ; type = lib.types.bool ; } ;
                                                                            name = implementation-parameters.lib.mkOption { default = "sally-server" ; type = lib.types.str ; } ;
                                                                            port = implementation-parameters.lib.mkOption { default = 10652 ; type = lib.types.int ; } ;
                                                                        } ;
                                                                } ;
                                                        } ;
                                                } ;
                                        } ;
                                root-parameters =
                                    {
                                        lazy-shell-application = lazy-shell-application ;
                                    } ;
                                in
                                    {
                                        check =
                                            lazy-shell-application :
                                            {
                                                client ,
                                                coreutils ,
                                                findutils ,
                                                nixosTest ,
                                                nodes ,
                                                order ,
                                                test-setup ,
                                                writeShellApplication
                                            } :
                                                let
                                                    check-parameters =
                                                        {
                                                            client = client ;
                                                            coreutils = coreutils ;
                                                            findutils = findutils ;
                                                            lazy-shell-application = lazy-shell-application ;
                                                            nixosTest = nixosTest ;
                                                            nodes = nodes ;
                                                            order = order ;
                                                            test-setup = test-setup ;
                                                            writeShellApplication = writeShellApplication ;
                                                        } ;
                                                    in
                                                        check-parameters.lazy-shell-application
                                                            {
                                                                client = check-parameters.client ;
                                                                coreutils = check-parameters.coreutils ;
                                                                findutils = check-parameters.findutils ;
                                                                nixosTest = check-parameters.nixosTest ;
                                                                nodes = check-parameters.nodes ;
                                                                order = check-parameters.order ;
                                                                test-setup =
                                                                    builtins.concatLists
                                                                        [
                                                                            check-parameters.test-setup
                                                                                [
                                                                                    ''${ check-parameters.client }.wait_for_unit("sally-server.service")''
                                                                                    ''${ check-parameters.client }.wait_for_open_port(10652)''
                                                                                ]
                                                                        ] ;
                                                                writeShellApplication = check-parameters.writeShellApplication ;
                                                            }
                                                            {
                                                                mounts = { } ;
                                                                name = "sally" ;
                                                                runtime-inputs = pkgs : [ pkgs.coreutils pkgs.curl ] ;
                                                                text =
                                                                    ''
                                                                        curl --silent --fail http://127.0.0.1:10652/hello?name=4646461779242742 2> /dev/null
                                                                        echo
                                                                        curl --silent --fail --request POST http://127.0.0.1:10652/login 2> /dev/null
                                                                        test -s "$SALLY/app-debug.apk"
                                                                    '' ;
                                                            }
                                                            {
                                                                arguments = [ ] ;
                                                                standard-error = "" ;
                                                                standard-input = null ;
                                                                standard-output =
                                                                    ''
                                                                        hi 4646461779242742'' ;
                                                                status = 0 ;
                                                            } ;
                                        implementation = implementation ;
                                    } ;
        } ;
}

