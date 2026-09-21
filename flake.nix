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
                                                    environment.variables =
                                                        {
                                                            SALLY = implementation-parameters.config.sally.frontend.mobile.package ;
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
                                                                                                ExecStartPre =
                                                                                                    let
                                                                                                        application =
                                                                                                            root-parameters.lazy-shell-application
                                                                                                                {
                                                                                                                    name = "ExecStartPre" ;
                                                                                                                    mounts = { sally = { source = "/run/sally" ; type = "bind" ; } ; } ;
                                                                                                                    post = null ;
                                                                                                                    runtime-inputs = pkgs : [ pkgs.gnutar pkgs.xz ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            tar \
                                                                                                                                --extract \
                                                                                                                                --xz \
                                                                                                                                --file ${ self }/express.tar.xz \
                                                                                                                                --directory /mounts/sally/
                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        in "${ application }/bin/ExecStartPre" ;
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
                                                            frontend =
                                                                {
                                                                    mobile =
                                                                        {
                                                                            package =
                                                                                implementation-parameters.lib.mkOption
                                                                                    {
                                                                                        default =
                                                                                            let
                                                                                                androidComposition =
                                                                                                    implementation-parameters.pkgs.androidenv.composeAndroidPackages
                                                                                                        {
                                                                                                            platformVersions = [ "35" ] ;
                                                                                                            buildToolsVersions = [ "35.0.0" ] ;
                                                                                                        } ;

                                                                                                androidSdk =
                                                                                                    androidComposition.androidsdk ;
                                                                                                in
                                                                                                    implementation-parameters.pkgs.runCommand
                                                                                                        "sally"
                                                                                                        { nativeBuildInputs = [ implementation-parameters.pkgs.findutils androidSdk implementation-parameters.pkgs.coreutils implementation-parameters.pkgs.gradle ( failure 1862736323979915 ) ] ; }
                                                                                                        ''
                                                                                                            WORK_DIR="$( mktemp --directory )" || failure 3113983533329552
                                                                                                            cd "$WORK_DIR"
                                                                                                            cp --recursive ${ ./frontend/mobile }/* .
                                                                                                            find . >&2
                                                                                                            gradle assembleDebug
                                                                                                            mkdir --parents $out
                                                                                                            cp app/build/outputs/apk/debug/app-debug.apk $out/
                                                                                                        '' ;
                                                                                        type = implementation-parameters.lib.types.package ;
                                                                                    } ;
                                                                        } ;
                                                                } ;
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
                                                                        hi 4646461779242742
                                                                        login'' ;
                                                                status = 0 ;
                                                            } ;
                                        implementation = implementation ;
                                    } ;
        } ;
}

