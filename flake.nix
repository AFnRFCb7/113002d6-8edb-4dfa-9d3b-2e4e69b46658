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
                                                        implementation-parameters.config.sally.download-dependencies.frontend.mobile
                                                    ] ;
                                                    environment.variables =
                                                        {
                                                            SALLY = implementation-parameters.config.sally.frontend.mobile.package ;
                                                            DOWNLOAD_NODE = implementation-parameters.config.sally.download-dependencies.frontend.mobile ;
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
                                                                                                                    mounts = { sally = { source = "/run/sally" ; type = "ro-bind" ; } ; } ;
                                                                                                                    post = null ;
                                                                                                                    runtime-inputs = pkgs : [ pkgs.findutils pkgs.nodejs ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            find /mounts/sally
                                                                                                                            node /mounts/sally/server.js ${ builtins.toString config.sally.services.server.port }
                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        in "${ application }/bin/ExecStart" ;
                                                                                                ExecStartPre =
                                                                                                    let
                                                                                                        application =
                                                                                                            root-parameters.lazy-shell-application
                                                                                                                {
                                                                                                                    name = "ExecStartPre" ;
                                                                                                                    mounts = { sally = { source = "/run/sally" ; type = "bind" ; } ; } ;
                                                                                                                    post = null ;
                                                                                                                    runtime-inputs = pkgs : [ pkgs.coreutils ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            cp --recursive ${ ./node_modules } /mounts/sally/node_modules
                                                                                                                            cp ${ ./server.js } /mounts/sally/server.js
                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        in "${ application }/bin/ExecStartPre" ;
                                                                                                RuntimeDirectory = "sally" ;
                                                                                            } ;
                                                                                        wantedBy = [ "multi-user.target" ] ;
                                                                                    } ;
                                                                        } ;
                                                        } ;
                                                } ;
                                            options =
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
                                                        {
                                                            sally =
                                                                {
                                                                    download-dependencies =
                                                                        {
                                                                            frontend =
                                                                                {
                                                                                    mobile =
                                                                                        implementation-parameters.lib.mkOption
                                                                                            {
                                                                                                default =
                                                                                                    implementation-parameters.pkgs.writeShellApplication
                                                                                                        {
                                                                                                            name = "download" ;
                                                                                                            runtimeInputs =
                                                                                                                [
                                                                                                                    implementation-parameters.pkgs.coreutils
                                                                                                                    implementation-parameters.pkgs.findutils
                                                                                                                    implementation-parameters.pkgs.gradle
                                                                                                                    ( failure 4734451342324564 )
                                                                                                                    androidSdk
                                                                                                                    (
                                                                                                                        implementation-parameters.pkgs.writeShellApplication
                                                                                                                            {
                                                                                                                                name = "cleanup" ;
                                                                                                                                runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                text =
                                                                                                                                    ''
                                                                                                                                        rm --recursive --force "$GRADLE_USER_HOME"
                                                                                                                                    '' ;
                                                                                                                            }
                                                                                                                    )
                                                                                                                ] ;
                                                                                                            text =
                                                                                                                ''
                                                                                                                    export ANDROID_HOME=${ androidSdk }
                                                                                                                    cd frontend/mobile

                                                                                                                    GRADLE_USER_HOME="$(mktemp --directory)" || failure 6182679945594691
                                                                                                                    export GRADLE_USER_HOME
                                                                                                                    trap cleanup EXIT

                                                                                                                    gradle \
                                                                                                                        -Pandroid.aapt2FromMavenOverride="$ANDROID_HOME/libexec/android-sdk/build-tools/35.0.0/aapt2" \
                                                                                                                        build

                                                                                                                    rm --recursive --force gradle-dependencies
                                                                                                                    cp --recursive "$GRADLE_USER_HOME/caches/." gradle-dependencies/

                                                                                                                    find gradle-dependencies \
                                                                                                                        -type f \
                                                                                                                        \( -name '*.lock' -o -name 'gc.properties' \) \
                                                                                                                        -delete

                                                                                                                    chmod --recursive a+rwX gradle-dependencies

                                                                                                                    git add gradle-dependencies
                                                                                                                    rm --recursive --force .gradle
                                                                                                                    git commit -m "$1" --allow-empty-message
                                                                                                                '' ;
                                                                                                        } ;
                                                                                                type = implementation-parameters.lib.types.package ;
                                                                                            } ;
                                                                                } ;
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
                                                                    emulator =
                                                                        {
                                                                            mobile =
                                                                                implementation-parameters.lib.mkOption
                                                                                    {
                                                                                        default =
                                                                                            implementation-parameters.pkgs.writeShellApplication
                                                                                                {
                                                                                                    name = "emulator" ;
                                                                                                    runtimeInputs = [ ] ;
                                                                                                    text =
                                                                                                        ''
                                                                                                        '' ;
                                                                                                } ;
                                                                                        type = implementation-parameters.lib.types.package ;
                                                                                    } ;
                                                                        } ;
                                                                    frontend =
                                                                        {
                                                                            mobile =
                                                                                {
                                                                                    package =
                                                                                        implementation-parameters.lib.mkOption
                                                                                            {
                                                                                                default =
                                                                                                    let
                                                                                                        in
                                                                                                            implementation-parameters.pkgs.runCommand
                                                                                                                "sally"
                                                                                                                {
                                                                                                                    nativeBuildInputs =
                                                                                                                        [
                                                                                                                            implementation-parameters.pkgs.findutils
                                                                                                                            androidSdk
                                                                                                                            implementation-parameters.pkgs.coreutils
                                                                                                                            implementation-parameters.pkgs.gradle
                                                                                                                            ( failure 1862736323979915 )
                                                                                                                        ] ;
                                                                                                                    ANDROID_HOME = "${ androidSdk }" ;
                                                                                                                }
                                                                                                                ''
                                                                                                                    export ANDROID_HOME="${ androidSdk }"
                                                                                                                    WORK_DIR="$(mktemp --directory)" || failure 3113983533329552
                                                                                                                    echo "WORK_DIR=$WORK_DIR"

                                                                                                                    cd "$WORK_DIR"

                                                                                                                    cp --recursive "${./frontend/mobile}/." .
                                                                                                                    chmod --recursive u+rwX "$WORK_DIR"

                                                                                                                    export HOME="$WORK_DIR/home"
                                                                                                                    export GRADLE_USER_HOME="$HOME/.gradle"

                                                                                                                    mkdir --parents "$GRADLE_USER_HOME"
                                                                                                                    cp --recursive "${./frontend/mobile/gradle-dependencies}/." "$GRADLE_USER_HOME/caches/"
                                                                                                                    chmod --recursive u+rwX "$GRADLE_USER_HOME"

                                                                                                                    gradle \
                                                                                                                        -Pandroid.aapt2FromMavenOverride="$ANDROID_HOME/libexec/android-sdk/build-tools/35.0.0/aapt2" \
                                                                                                                        build \
                                                                                                                        --offline

                                                                                                                    mkdir --parents "$out"
                                                                                                                    cp --recursive build/outputs/. "$out"/
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
                                                                                            # ''${ check-parameters.client }.wait_for_open_port(10652)''
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
                                                                                test -s "$SALLY/apk/debug/sally-mobile-debug.apk"
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

