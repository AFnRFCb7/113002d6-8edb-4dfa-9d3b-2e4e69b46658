{
    inputs = { } ;
    outputs = { self } :
	    {
	        lib =
	            {
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
                                                    systemd =
                                                        {
                                                            services =
                                                                implementation-parameters.lib.mkIf
                                                                    implementation-parameters.config.trump5000.services.enable
                                                                        {
                                                                            trump5000-server =
                                                                                implementation-parameters.lib.mkIf
                                                                                    implementation-parameters.config.trump5000.services.server.enable
                                                                                    {
                                                                                        after = [ "network.target" ] ;
                                                                                        name = "${ implementation-parameters.config.trump5000.services.server.name }.service" ;
                                                                                        serviceConfig =
                                                                                            {
                                                                                                DynamicUser = true ;
                                                                                                ExecStartPre =
                                                                                                    let
                                                                                                        application =
                                                                                                            root-parameters.lazy-shell-application
                                                                                                                {
                                                                                                                    name = "ExecStartPre" ;
                                                                                                                    mounts = { trump5000 = { source = "/run/trump5000" ; type = "bind" ; } ; } ;
                                                                                                                    post = null ;
                                                                                                                    runtime-inputs = pkgs : [ pkgs.gnutar pkgs.xz ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            tar \
                                                                                                                                --extract \
                                                                                                                                --xz \
                                                                                                                                --file ${ self }/express.tar.xz \
                                                                                                                                --directory /mounts/trump5000/
                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        in "${ application }/bin/ExecStartPre" ;
                                                                                                ExecStart =
                                                                                                    let
                                                                                                        application =
                                                                                                            root-parameters.lazy-shell-application
                                                                                                                {
                                                                                                                    name = "ExecStart" ;
                                                                                                                    mounts = { trump5000 = { source = "/run/trump5000" ; type = "bind" ; } ; } ;
                                                                                                                    post = null ;
                                                                                                                    runtime-inputs = pkgs : [ pkgs.nodejs ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            node /mounts/trump5000/server.js
                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        in "${ application }/bin/ExecStart" ;
                                                                                                RuntimeDirectory = "trump5000" ;
                                                                                            } ;
                                                                                        wantedBy = [ "multi-user.target" ] ;
                                                                                    } ;
                                                                        } ;
                                                        } ;
                                                } ;
                                            options =
                                                {
                                                    trump5000 =
                                                        {
                                                            services =
                                                                {
                                                                    enable = implementation-parameters.lib.mkOption { default = true ; type = lib.types.bool ; } ;
                                                                    server =
                                                                        {
                                                                            enable = implementation-parameters.lib.mkOption { default = true ; type = lib.types.bool ; } ;
                                                                            name = implementation-parameters.lib.mkOption { default = "trump5000-server" ; type = lib.types.str ; } ;
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
                                                                                    ''${ check-parameters.client }.wait_for_unit("trump5000-server.service")''
                                                                                    ''${ check-parameters.client }.wait_for_open_port(3000)''
                                                                                ]
                                                                        ] ;
                                                                writeShellApplication = check-parameters.writeShellApplication ;
                                                            }
                                                            {
                                                                mounts = { } ;
                                                                name = "trump5000" ;
                                                                runtime-inputs = pkgs : [ pkgs.coreutils pkgs.curl ] ;
                                                                text = "curl http://127.0.0.1:3000/hello?name=4646461779242742 2> /dev/null" ;
                                                            }
                                                            {
                                                                arguments = [ ] ;
                                                                standard-error = "" ;
                                                                standard-input = null ;
                                                                standard-output = "hi 4646461779242742" ;
                                                                status = 0 ;
                                                            } ;
                                        implementation = implementation ;
                                    } ;
        } ;
}

