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
                                                    environment.systemPackages =
                                                        [
                                                            ( implementation-parameters.config.node-package.fetch { dependencies = { express = "^5.1.0" ; } ; scripts = { start = "node server.js 10652" ; } ; } )
                                                            implementation-parameters.config.android-application.fetch
                                                        ] ;
                                                    environment.variables =
                                                        {
                                                            # SALLY = implementation-parameters.config.sally.frontend.mobile.package ;
                                                            # DOWNLOAD_NODE = implementation-parameters.config.sally.download-dependencies.frontend.mobile ;
                                                            EMULATOR = implementation-parameters.config.sally.emulator.mobile ;
                                                            FETCH_JSON = implementation-parameters.config.node-package.fetch { dependencies = { express = "^5.1.0" ; } ; scripts = { start = "node server.js 10652" ; } ; } ;
                                                            FETCH_ANDROID = implementation-parameters.config.android-application.fetch ;
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
                                                                                                            implementation-parameters.config.node-package.execute
                                                                                                                {
                                                                                                                    command = "run start" ;
                                                                                                                    name = "ExecStart" ;
                                                                                                                    package = implementation-parameters.config.node-package.build ./. ;
                                                                                                                    work-directory = "/tmp/sally" ;
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
                                                let
                                                    androidComposition =
                                                        implementation-parameters.pkgs.androidenv.composeAndroidPackages
                                                            {
                                                                platformVersions = [ "35" ] ;
                                                                buildToolsVersions = [ "35.0.0" ] ;
                                                                includeEmulator = true ;
                                                                includeSystemImages = true ;
                                                                systemImageTypes = [ "google_apis" ] ;
                                                                abiVersions = [ "x86_64" ] ;
                                                            } ;
                                                    androidSdk = androidComposition.androidsdk ;
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
                                                                                                                    implementation-parameters.pkgs.gnutar
                                                                                                                    ( failure 4734451342324564 )
                                                                                                                    androidSdk
                                                                                                                    (
                                                                                                                        implementation-parameters.pkgs.writeShellApplication
                                                                                                                            {
                                                                                                                                name = "explode" ;
                                                                                                                                runtimeInputs =
                                                                                                                                    [
                                                                                                                                        implementation-parameters.pkgs.coreutils
                                                                                                                                        implementation-parameters.pkgs.git
                                                                                                                                        implementation-parameters.pkgs.jdk
                                                                                                                                        ( failure 9891196344992798 )
                                                                                                                                    ] ;
                                                                                                                                text =
                                                                                                                                    ''
                                                                                                                                        RELATIVE_FILE="$1"
                                                                                                                                        ABSOLUTE_FILE="$( realpath "$RELATIVE_FILE" )" || failure 7667864193624809
                                                                                                                                        ABSOLUTE_DIRECTORY="$ABSOLUTE_FILE.exploded"
                                                                                                                                        mkdir --parents "$ABSOLUTE_DIRECTORY"
                                                                                                                                        cd "$ABSOLUTE_DIRECTORY"
                                                                                                                                        split --bytes=10M "$ABSOLUTE_FILE"
                                                                                                                                        git add "$ABSOLUTE_DIRECTORY"
                                                                                                                                        rm "$ABSOLUTE_FILE"
                                                                                                                                    '' ;
                                                                                                                            }
                                                                                                                    )
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
                                                                                                                    echo 1723258852938545 4247271882821595
                                                                                                                    find gradle-dependencies -type f -name "*.jar" -print -exec explode {} \;
                                                                                                                    echo 1723258852938545 2282220072447790
                                                                                                                    find gradle-dependencies -type f -name "*.jar" -exec failure 7242237646954809 \;
                                                                                                                    chmod --recursive a+rwX gradle-dependencies
                                                                                                                    git add gradle-dependencies
                                                                                                                    rm --recursive --force .gradle
                                                                                                                    git clean -fd
                                                                                                                    git commit -m "$1" --allow-empty-message
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
                                                                                                    runtimeInputs =
                                                                                                        [
                                                                                                            pkgs.coreutils
                                                                                                            androidSdk
                                                                                                            ( failure 3197695537713754 )
                                                                                                        ] ;
                                                                                                    text =
                                                                                                        ''
                                                                                                            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"

                                                                                                            ANDROID_AVD_HOME="$( mktemp --directory )" || failure 7318874258885152
                                                                                                            export ANDROID_AVD_HOME

                                                                                                            APK="${ implementation-parameters.config.sally.frontend.mobile.package }/apk/debug/app-debug.apk"

                                                                                                            # Catalog the APK before doing anything with the emulator.
                                                                                                            echo "=== APK ==="
                                                                                                            echo "path: $APK"
                                                                                                            ls -lh "$APK"

                                                                                                            echo "=== APK package metadata ==="
                                                                                                            "$ANDROID_HOME/build-tools/35.0.0/aapt" dump badging "$APK" \
                                                                                                                | grep -E '^(package:|launchable-activity:)'

                                                                                                            echo "=== APK SHA-256 ==="
                                                                                                            sha256sum "$APK"

                                                                                                            avdmanager create avd \
                                                                                                                --force \
                                                                                                                --name sally \
                                                                                                                --package "system-images;android-35;google_apis;x86_64" \
                                                                                                                --device "pixel"

                                                                                                            emulator \
                                                                                                                -avd sally \
                                                                                                                -no-snapshot \
                                                                                                                -no-audio \
                                                                                                                -no-boot-anim &

                                                                                                            adb wait-for-device

                                                                                                            until adb shell getprop sys.boot_completed 2>/dev/null | grep -q '^1$'; do
                                                                                                                sleep 1
                                                                                                            done

                                                                                                            adb install "$APK"
                                                                                                            adb shell monkey -p com.example.sally 1


                                                                                                            debug(){
                                                                                                                adb devices

                                                                                                                # List of devices attached
                                                                                                                # emulator-5554    device

                                                                                                                adb logcat -d -t 300

                                                                                                                adb logcat -c
                                                                                                                adb shell monkey -p com.example.sally 1
                                                                                                                adb logcat -d | grep -E 'FATAL EXCEPTION|AndroidRuntime|com.example.sally'

                                                                                                                adb logcat -d > /tmp/sally-logcat.txt

                                                                                                                grep -n -A 40 -B 10 'FATAL EXCEPTION' /tmp/sally-logcat.txt

                                                                                                                adb logcat

                                                                                                                # FATAL EXCEPTION: main

                                                                                                                adb shell dumpsys package com.example.sally

                                                                                                                adb shell pm path com.example.sally

                                                                                                                adb shell pm list packages | grep sally

                                                                                                                adb logcat -c
                                                                                                                adb shell monkey -p com.example.sally 1
                                                                                                                adb logcat -d | grep -E -A 50 -B 10 'FATAL EXCEPTION|AndroidRuntime'
                                                                                                            }
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
                                                                                                                            implementation-parameters.pkgs.gnutar
                                                                                                                            androidSdk
                                                                                                                            implementation-parameters.pkgs.coreutils
                                                                                                                            implementation-parameters.pkgs.gradle
                                                                                                                            ( failure 1862736323979915 )
                                                                                                                            (
                                                                                                                                pkgs.writeShellApplication
                                                                                                                                    {
                                                                                                                                        name = "implode" ;
                                                                                                                                        runtimeInputs =
                                                                                                                                            [
                                                                                                                                                implementation-parameters.pkgs.coreutils
                                                                                                                                                implementation-parameters.pkgs.findutils
                                                                                                                                                implementation-parameters.pkgs.jdk
                                                                                                                                                ( failure 3418308241641114 )
                                                                                                                                            ] ;
                                                                                                                                        text =
                                                                                                                                            ''
                                                                                                                                                RELATIVE_DIRECTORY="$1"
                                                                                                                                                ABSOLUTE_DIRECTORY="$( realpath "$RELATIVE_DIRECTORY" )" || failure 5895370384790233
                                                                                                                                                ABSOLUTE_FILE="${ "$" }{ABSOLUTE_DIRECTORY%.*}"
                                                                                                                                                find "$ABSOLUTE_DIRECTORY" -type f -mindepth 1 | sort | xargs cat > "$ABSOLUTE_FILE"
                                                                                                                                            '' ;
                                                                                                                                    }
                                                                                                                            )
                                                                                                                        ] ;
                                                                                                                    ANDROID_HOME = "${ androidSdk }" ;
                                                                                                                }
                                                                                                                ''
                                                                                                                    export RESOURCE="$( mktemp --directory )" || failure 1131106762433829
                                                                                                                    cp --recursive ${ ./. }/. "$RESOURCE"
                                                                                                                    chmod -R a+rwx "$RESOURCE"
                                                                                                                    find "$RESOURCE" -type d -name "*.exploded" -exec implode {} \;
                                                                                                                    export ANDROID_HOME="${ androidSdk }"
                                                                                                                    WORK_DIR="$(mktemp --directory)" || failure 3113983533329552
                                                                                                                    echo "WORK_DIR=$WORK_DIR"

                                                                                                                    cd "$WORK_DIR"

                                                                                                                    cp --recursive "$RESOURCE/frontend/mobile/." .
                                                                                                                    chmod --recursive u+rwX "$WORK_DIR"
                                                                                                                    find "$WORK_DIR" -type d -name "*.jar.exploded" -exec implode {} \;

                                                                                                                    export HOME="$WORK_DIR/home"
                                                                                                                    export GRADLE_USER_HOME="$HOME/.gradle"

                                                                                                                    mkdir --parents "$GRADLE_USER_HOME"
                                                                                                                    cp --recursive "$WORK_DIR/gradle-dependencies/." "$GRADLE_USER_HOME/caches/"
                                                                                                                    chmod --recursive u+rwX "$WORK_DIR"
                                                                                                                    find "$GRADLE_USER_HOME" -type d -name "*.jar.exploded" -exec implode {} \;

                                                                                                                    find "$WORK_DIR" -name "*.jar" >&2
                                                                                                                    find "$WORK_DIR" -name "*.exploded" >&2
                                                                                                                    gradle \
                                                                                                                        -Pandroid.aapt2FromMavenOverride="$ANDROID_HOME/libexec/android-sdk/build-tools/35.0.0/aapt2" \
                                                                                                                        build \
                                                                                                                        --offline

                                                                                                                    mkdir --parents "$out"
                                                                                                                    cp --recursive app/build/outputs/. "$out"/
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
                                                                                test -s "$SALLY/apk/debug/app-debug.apk"
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

