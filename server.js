const express = require("express") ;
const app = express() ;
const port = Number(process.argv[2]) ;
app.get
    (
        "/hello" ,
        ( request , response ) =>
            {
                const name = request.query.name || "world" ;
                response.send( `hi ${ name }`) ;
            }
    ) ;'
app.get
    (
        "/secret" ,
        ( request , response ) =>
            {
                const name = request.query.name || "world" ;
                response.send( `hi ${ name }`) ;
            }
    ) ;    '
app.post
    (
        "/login" , ( request , response ) =>
            {
                response.send("login") ;
            }
    ) ;
app.listen
    (
        port ,
        () =>
            {
                console.log(`listening on port ${ port }`) ;
            }
    ) ;
